"""Vivado synthesis harness: area, power, and delay for RTLLM candidates.

Two modes:

* ``--mode model``  synthesizes one generated candidate per design (by default the
  first functionally-passing trial recorded in an ``auto_run.py`` JSON report).
* ``--mode golden`` synthesizes the repository's ``verified_*.v`` reference RTL so the
  model numbers have a human-designed baseline to be compared against.

Both modes use an identical flow, so the model/golden ratios are meaningful even
though the absolute numbers depend on the chosen part and clock period.
"""

from __future__ import annotations

import argparse
import concurrent.futures
import glob
import json
import os
import re
import shutil
import subprocess
import time
from datetime import datetime, timezone

from benchmark_config import BENCHMARK_DESIGNS, design_category, discover_design_paths

ROOT_DIR = os.path.dirname(os.path.abspath(__file__))
# Only the Spartan-7 family is installed in this Vivado; xc7s100fgga676-2 is its
# largest device in the fastest speed grade.
DEFAULT_PART = "xc7s100fgga676-2"
DEFAULT_PERIOD_NS = 10.0
DEFAULT_TOGGLE_PCT = 25.0
LANG_EXT = {"verilog": ".v", "vhdl": ".vhd"}


def load_env_file(env_path=None):
    """Load KEY=VALUE pairs from .env without overriding existing variables."""
    env_path = env_path or os.path.join(ROOT_DIR, ".env")
    if not os.path.isfile(env_path):
        return
    with open(env_path, encoding="utf-8") as file:
        for raw_line in file:
            line = raw_line.strip()
            if not line or line.startswith("#"):
                continue
            if line.startswith("export "):
                line = line[7:].strip()
            key, sep, value = line.partition("=")
            if sep:
                key = key.strip()
                value = value.strip().strip('"').strip("'")
                if key and key not in os.environ:
                    os.environ[key] = value


def find_vivado():
    """Return the path to the vivado launcher, or None."""
    direct = shutil.which("vivado")
    if direct:
        return direct

    candidates = []
    bin_dir = os.environ.get("VIVADO_BIN")
    if bin_dir:
        candidates.append(bin_dir)
    home = os.environ.get("XILINX_VIVADO")
    if home:
        candidates += [os.path.join(home, "bin"), os.path.join(home, "Vivado", "bin")]
    for base in (r"C:\Xilinx", r"D:\Xilinx", r"E:\Xilinx", r"E:\vivado", "/tools/Xilinx"):
        if not os.path.isdir(base):
            continue
        for entry in sorted(os.listdir(base), reverse=True):
            install = os.path.join(base, entry)
            candidates += [os.path.join(install, "bin"), os.path.join(install, "Vivado", "bin")]
            vivado_dir = os.path.join(install, "Vivado")
            if os.path.isdir(vivado_dir):
                for version in sorted(os.listdir(vivado_dir), reverse=True):
                    candidates.append(os.path.join(vivado_dir, version, "bin"))

    for directory in candidates:
        for name in ("vivado.bat", "vivado.exe", "vivado"):
            path = os.path.join(directory, name)
            if os.path.isfile(path):
                return path
    return None


# The TCL flow. Constraints are applied to the synthesized netlist rather than
# read in before synth_design: Vivado needs an elaborated design before the clock
# ports can be identified reliably, and every candidate goes through the exact
# same flow, so the comparison stays fair.
TCL_TEMPLATE = r"""
set metrics [dict create]

if {$hdl eq "vhdl"} {
    read_vhdl -vhdl2008 $src
} else {
    read_verilog -sv $src
}

if {[llength [get_parts -quiet $part]] == 0} {
    error "part '$part' is not installed in this Vivado (check get_parts)"
}

set tops [find_top]
if {[llength $tops] == 0} {
    error "find_top returned no candidate top module"
}
set top [lindex $tops 0]
dict set metrics top $top

# In-context synthesis (I/O buffers inserted) is the default: without IOBs Vivado's
# vectorless power estimate rounds dynamic power to 0.000 W on designs this small.
# The caller retries with out_of_context if a design cannot fit the device pinout.
if {$ooc eq "1"} {
    synth_design -top $top -part $part -mode out_of_context
    dict set metrics synth_mode out_of_context
} else {
    synth_design -top $top -part $part
    dict set metrics synth_mode in_context
}

# --- area -------------------------------------------------------------------
proc nprim {pattern} {
    return [llength [get_cells -quiet -hierarchical -filter "REF_NAME =~ $pattern"]]
}
dict set metrics cells_total [llength [get_cells -quiet -hierarchical -filter {IS_PRIMITIVE == 1}]]
dict set metrics luts        [nprim "LUT*"]
dict set metrics regs        [nprim "FD*"]
dict set metrics carry       [nprim "CARRY*"]
dict set metrics muxf        [nprim "MUXF*"]
dict set metrics dsp         [nprim "DSP*"]
dict set metrics bram        [nprim "RAMB*"]
dict set metrics srl         [nprim "SRL*"]
dict set metrics iob         [expr {[nprim "IBUF*"] + [nprim "OBUF*"] + [nprim "IOBUF*"]}]
dict set metrics bufg        [nprim "BUFG*"]
dict set metrics ports       [llength [get_ports -quiet]]
# Area figure of merit: synthesized logic primitives only, so the I/O and clock
# buffers that in-context synthesis adds do not distort the model/golden ratio.
dict set metrics logic_cells [expr {[dict get $metrics luts] + [dict get $metrics regs]                                   + [dict get $metrics carry] + [dict get $metrics muxf]                                   + [dict get $metrics dsp] + [dict get $metrics bram]                                   + [dict get $metrics srl]}]

# --- constraints ------------------------------------------------------------
set inports  [get_ports -quiet -filter {DIRECTION == IN}]
set outports [get_ports -quiet -filter {DIRECTION == OUT || DIRECTION == INOUT}]
set exactclk {clk clock sysclk clk_in clkin clk_i i_clk clka clk0 clk1 clk_50 mclk pclk aclk}
set clkports {}
set clknamelist {}
foreach port $inports {
    set pname [string tolower [get_property NAME $port]]
    if {[lsearch -exact $exactclk $pname] >= 0} {
        lappend clkports $port
        lappend clknamelist $pname
    }
}
if {[llength $clkports] == 0} {
    foreach port $inports {
        set pname [get_property NAME $port]
        if {[regexp -nocase {(^|_)(clk|clock)([0-9]*)($|_)} $pname]} {
            lappend clkports $port
            lappend clknamelist $pname
        }
    }
}
dict set metrics clock_ports [join $clknamelist " "]

set clkindex 0
set clknames {}
foreach port $clkports {
    set cname "rtllm_clk$clkindex"
    create_clock -name $cname -period $period $port
    lappend clknames $cname
    incr clkindex
}
if {[llength $clknames] == 0} {
    # Purely combinational: a virtual clock turns the input-to-output cone into a
    # constrained path so report_timing has something to walk.
    create_clock -name rtllm_virt -period $period
    lappend clknames rtllm_virt
    dict set metrics sequential 0
} else {
    dict set metrics sequential 1
}
set refclk [lindex $clknames 0]

set dataports {}
foreach port $inports {
    if {[lsearch -exact $clkports $port] < 0} { lappend dataports $port }
}
if {[llength $dataports] > 0} { set_input_delay 0.0 -clock $refclk $dataports }
if {[llength $outports] > 0}  { set_output_delay 0.0 -clock $refclk $outports }

# --- delay ------------------------------------------------------------------
set path [get_timing_paths -quiet -delay_type max -max_paths 1 -nworst 1]
if {[llength $path] > 0} {
    dict set metrics slack_ns      [get_property SLACK $path]
    dict set metrics delay_ns      [get_property DATAPATH_DELAY $path]
    dict set metrics logic_levels  [get_property LOGIC_LEVELS $path]
    dict set metrics path_startpoint [get_property STARTPOINT_PIN $path]
    dict set metrics path_endpoint   [get_property ENDPOINT_PIN $path]
}
# In-context synthesis puts IBUF/OBUF delay on every pad-to-pad path, which swamps
# the logic on small designs; the register-to-register path isolates the datapath.
set regs_all [all_registers -quiet]
if {[llength $regs_all] > 0} {
    set rpath [get_timing_paths -quiet -delay_type max -max_paths 1 -nworst 1                                 -from $regs_all -to $regs_all]
    if {[llength $rpath] > 0} {
        dict set metrics logic_delay_ns [get_property DATAPATH_DELAY $rpath]
        dict set metrics logic_slack_ns [get_property SLACK $rpath]
        dict set metrics logic_path_levels [get_property LOGIC_LEVELS $rpath]
    }
}
dict set metrics clock_period_ns $period

# --- power ------------------------------------------------------------------
# Vectorless estimate: without a simulation activity file Vivado needs an explicit
# default toggle rate for the dynamic figure to mean anything.
set_switching_activity -default_toggle_rate $toggle -default_static_probability 0.5
dict set metrics toggle_rate_pct $toggle
set pwr [report_power -return_string]
foreach {key pattern} {
    total_power_w   {Total On-Chip Power \(W\)[^0-9\-]*([0-9]+\.?[0-9]*)}
    dynamic_power_w {Dynamic \(W\)[^0-9\-]*([0-9]+\.?[0-9]*)}
    static_power_w  {Device Static \(W\)[^0-9\-]*([0-9]+\.?[0-9]*)}
} {
    if {[regexp $pattern $pwr -> value]} { dict set metrics $key $value }
}

report_utilization -file utilization.rpt
report_power       -file power.rpt
report_power -format xml -file power.xml
report_timing -delay_type max -max_paths 5 -file timing.rpt

set fh [open $metricfile w]
dict for {key value} $metrics { puts $fh "$key=$value" }
close $fh
puts "RTLLM_SYNTH_OK"
"""


def safe_name(design):
    """Design names contain spaces; keep the scratch folder filesystem-friendly."""
    return re.sub(r"[^\w.-]+", "_", design)


def parse_metrics(path):
    values = {}
    if not os.path.isfile(path):
        return values
    with open(path, encoding="utf-8", errors="replace") as file:
        for line in file:
            key, sep, value = line.rstrip("\n").partition("=")
            if not sep:
                continue
            value = value.strip()
            try:
                values[key] = int(value)
            except ValueError:
                try:
                    values[key] = float(value)
                except ValueError:
                    values[key] = value
    return values


def run_one(task, vivado, part, period, timeout, toggle, ooc=False):
    work_dir = task["work_dir"]
    os.makedirs(work_dir, exist_ok=True)
    metric_file = os.path.join(work_dir, "metrics.txt")
    script_path = os.path.join(work_dir, "run.tcl")
    # Vivado's find_top re-parses the source list and splits it on whitespace, so a
    # design directory such as "Finite State Machine" breaks it. The scratch directory
    # name is already sanitized, so synthesizing a copy sidesteps the problem entirely.
    local_source = os.path.join(work_dir, "dut" + (".vhd" if task["hdl"] == "vhdl" else ".v"))
    shutil.copyfile(task["source"], local_source)
    preamble = "\n".join([
        "set src {%s}" % local_source.replace("\\", "/"),
        "set part {%s}" % part,
        "set period %s" % period,
        "set hdl {%s}" % task["hdl"],
        "set metricfile {%s}" % metric_file.replace("\\", "/"),
        "set ooc {%s}" % ("1" if ooc else "0"),
        "set toggle %s" % toggle,
        "",
    ])
    with open(script_path, "w", encoding="utf-8", newline="\n") as file:
        file.write(preamble + TCL_TEMPLATE)
    for stale in (metric_file, os.path.join(work_dir, "vivado.log")):
        if os.path.isfile(stale):
            os.remove(stale)

    command = [
        vivado, "-mode", "batch", "-notrace",
        "-log", "vivado.log", "-journal", "vivado.jou",
        "-source", script_path,
    ]
    started = time.monotonic()
    record = {
        "design": task["design"],
        "category": task["category"],
        "kind": task["kind"],
        "language": task["hdl"],
        "trial": task.get("trial"),
        "source_file": task["source"],
    }
    record["synth_mode_requested"] = "out_of_context" if ooc else "in_context"
    # vivado.bat spawns vivado.exe as a child, so a timeout has to kill the whole
    # tree by PID -- killing by image name would take down the sibling workers too.
    environment = dict(os.environ)
    environment["XILINX_LOCAL_USER_DATA"] = "no"
    process = subprocess.Popen(
        command, cwd=work_dir, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
        text=True, errors="replace", env=environment,
    )
    try:
        stdout, _ = process.communicate(timeout=timeout)
        stdout = stdout or ""
        record["status"] = "ok" if "RTLLM_SYNTH_OK" in stdout else "synth_failed"
        if record["status"] != "ok":
            errors = re.findall(r"^ERROR:.*$", stdout, re.MULTILINE)
            record["error"] = errors[-1][:400] if errors else f"exit {process.returncode}"
    except subprocess.TimeoutExpired:
        record["status"] = "timeout"
        record["error"] = f"exceeded {timeout}s"
        if os.name == "nt":
            subprocess.run(["taskkill", "/F", "/T", "/PID", str(process.pid)], capture_output=True)
        else:
            process.kill()
        try:
            process.communicate(timeout=30)
        except subprocess.TimeoutExpired:
            pass
    except Exception as exc:  # noqa: BLE001 - a broken candidate must not abort the sweep
        record["status"] = "runner_error"
        record["error"] = f"{type(exc).__name__}: {exc}"

    record.update(parse_metrics(metric_file))
    record["runtime_seconds"] = round(time.monotonic() - started, 2)

    # Fmax comes from the register-to-register path when the design has one; a purely
    # combinational block is rated by its own propagation delay instead.
    logic_slack = record.get("logic_slack_ns")
    slack = record.get("slack_ns")
    critical = None
    if isinstance(logic_slack, (int, float)):
        critical = period - logic_slack
    elif record.get("sequential") and isinstance(slack, (int, float)):
        critical = period - slack
    elif isinstance(record.get("delay_ns"), (int, float)):
        critical = record["delay_ns"]
    if isinstance(critical, (int, float)) and critical > 0:
        record["critical_path_ns"] = round(critical, 3)
        record["fmax_mhz"] = round(1000.0 / critical, 2)
    return record


TRANSIENT_MARKERS = ("tclapp::load_apps", "Could not open", "17-354")


def run_with_fallback(task, vivado, part, period, timeout, toggle):
    """In-context synthesis first; fall back to out-of-context if the pinout will not fit."""
    record = run_one(task, vivado, part, period, timeout, toggle, ooc=False)
    if record["status"] != "ok" and any(m in str(record.get("error", "")) for m in TRANSIENT_MARKERS):
        record = run_one(task, vivado, part, period, timeout, toggle, ooc=False)
    if record["status"] == "synth_failed":
        retry = run_one(task, vivado, part, period, timeout, toggle, ooc=True)
        if retry["status"] == "ok":
            retry["in_context_error"] = record.get("error")
            return retry
    return record


def best_passing_trials(report_path):
    """Map design -> trial id of its first functionally-passing candidate."""
    with open(report_path, encoding="utf-8") as file:
        report = json.load(file)
    order = {trial: index for index, trial in enumerate(report.get("trials") or [])}
    best = {}
    for item in report.get("trial_results") or []:
        if not item.get("functional_pass"):
            continue
        design, trial = item.get("design"), item.get("trial")
        current = best.get(design)
        if current is None or order.get(trial, 99) < order.get(current, 99):
            best[design] = trial
    return best, report


def golden_source(design_dir):
    matches = sorted(glob.glob(os.path.join(design_dir, "verified_*.v")))
    return matches[0] if matches else None


def parse_args():
    parser = argparse.ArgumentParser(description="Vivado PPA sweep for RTLLM candidates.")
    parser.add_argument("--mode", choices=("model", "golden"), default="model")
    parser.add_argument("--lang", choices=LANG_EXT, default="verilog")
    parser.add_argument("--gen-dir", default=None, help="Generation directory (model mode).")
    parser.add_argument("--report", default=None,
                        help="auto_run.py JSON report used to pick the passing trial (model mode).")
    parser.add_argument("--scope", choices=("best-pass", "all-pass", "all"), default="best-pass",
                        help="Which candidates to synthesize (default: best-pass).")
    parser.add_argument("--out-json", required=True)
    parser.add_argument("--work-dir", default=None, help="Scratch directory for Vivado runs.")
    parser.add_argument("--part", default=DEFAULT_PART)
    parser.add_argument("--clock-period", type=float, default=DEFAULT_PERIOD_NS)
    parser.add_argument("--toggle-rate", type=float, default=DEFAULT_TOGGLE_PCT,
                        help="Default switching activity for the vectorless power estimate, in %% "
                             f"(default: {DEFAULT_TOGGLE_PCT}).")
    parser.add_argument("--workers", type=int, default=2)
    parser.add_argument("--timeout", type=int, default=1800)
    parser.add_argument("--only", default=None, help="Restrict to a single design.")
    parser.add_argument("--resume", action="store_true",
                        help="Keep successful results already in --out-json and only re-run the rest.")
    args = parser.parse_args()
    if args.mode == "model" and not args.gen_dir:
        parser.error("--gen-dir is required in model mode")
    if args.mode == "model" and args.scope != "all" and not args.report:
        parser.error("--report is required unless --scope all")
    return args


def main():
    load_env_file()
    args = parse_args()

    vivado = find_vivado()
    if not vivado:
        raise SystemExit(
            "Error: vivado launcher not found. Set VIVADO_BIN or XILINX_VIVADO in .env "
            r"(e.g. VIVADO_BIN=E:\vivado\2025.2\Vivado\bin)."
        )

    design_paths = discover_design_paths(ROOT_DIR)
    designs = [args.only] if args.only else [d for d in BENCHMARK_DESIGNS if d in design_paths]
    if args.only and args.only not in design_paths:
        raise SystemExit(f"Error: design '{args.only}' not found.")

    work_root = os.path.abspath(args.work_dir or os.path.join(ROOT_DIR, ".runtime", f"synth_{args.mode}_{args.lang}"))
    os.makedirs(work_root, exist_ok=True)
    source_report = None
    tasks = []
    if args.mode == "golden":
        for design in designs:
            source = golden_source(design_paths[design])
            if not source:
                continue
            tasks.append({
                "design": design,
                "category": design_category(ROOT_DIR, design_paths[design]),
                "kind": "golden",
                "hdl": "verilog",
                "trial": None,
                "source": source,
                "work_dir": os.path.join(work_root, safe_name(design)),
            })
    else:
        generation_path = os.path.abspath(
            args.gen_dir if os.path.isabs(args.gen_dir) else os.path.join(ROOT_DIR, args.gen_dir)
        )
        extension = LANG_EXT[args.lang]
        selected = {}
        if args.report:
            best, source_report = best_passing_trials(args.report)
            if args.scope == "best-pass":
                selected = {design: [trial] for design, trial in best.items()}
            elif args.scope == "all-pass":
                with open(args.report, encoding="utf-8") as file:
                    report = json.load(file)
                for item in report.get("trial_results") or []:
                    if item.get("functional_pass"):
                        selected.setdefault(item["design"], []).append(item["trial"])
        if args.scope == "all":
            trial_dirs = sorted(
                (name for name in os.listdir(generation_path)
                 if re.fullmatch(r"t\d+", name) and os.path.isdir(os.path.join(generation_path, name))),
                key=lambda name: int(name[1:]),
            )
            selected = {design: list(trial_dirs) for design in designs}

        for design in designs:
            for trial in selected.get(design, []):
                source = os.path.join(generation_path, trial, f"{design}{extension}")
                if not os.path.isfile(source) or os.path.getsize(source) == 0:
                    continue
                tasks.append({
                    "design": design,
                    "category": design_category(ROOT_DIR, design_paths[design]),
                    "kind": "model",
                    "hdl": args.lang,
                    "trial": trial,
                    "source": source,
                    "work_dir": os.path.join(work_root, safe_name(design) + "__" + trial),
                })

    kept = []
    if args.resume and os.path.isfile(args.out_json):
        with open(args.out_json, encoding="utf-8") as file:
            previous = json.load(file)
        done = {
            (item.get("design"), item.get("trial"))
            for item in previous.get("results") or []
            if item.get("status") == "ok"
        }
        kept = [item for item in previous.get("results") or [] if item.get("status") == "ok"]
        before = len(tasks)
        tasks = [task for task in tasks if (task["design"], task.get("trial")) not in done]
        print(f"Resume: keeping {len(kept)} successful result(s), re-running {len(tasks)} of {before}.")

    if not tasks:
        if kept:
            print("Nothing left to run; all targets already succeeded.")
        else:
            raise SystemExit("Error: no synthesis tasks were selected (no passing candidates?).")

    print(f"Vivado: {vivado}")
    print(f"Synthesizing {len(tasks)} target(s) on {args.part} at {args.clock_period} ns "
          f"with {args.workers} worker(s). Scratch: {work_root}")

    results = list(kept)
    done = 0
    with concurrent.futures.ThreadPoolExecutor(max_workers=args.workers) as executor:
        futures = {
            executor.submit(run_with_fallback, task, vivado,
                            args.part, args.clock_period, args.timeout, args.toggle_rate): task
            for task in tasks
        }
        for future in concurrent.futures.as_completed(futures):
            record = future.result()
            results.append(record)
            done += 1
            label = f"{record['design']}" + (f"/{record['trial']}" if record.get("trial") else "")
            detail = ""
            if record["status"] == "ok":
                detail = (f"cells={record.get('logic_cells')} "
                          f"power={record.get('total_power_w')}W "
                          f"delay={record.get('delay_ns')}ns")
            else:
                detail = record.get("error", "")
            print(f"[{done}/{len(tasks)}] {label}: {record['status']} {detail}")

    order = {design: index for index, design in enumerate(BENCHMARK_DESIGNS)}
    results.sort(key=lambda item: (order.get(item["design"], 999), str(item.get("trial") or "")))

    payload = {
        "schema_version": 1,
        "generated_at": datetime.now(timezone.utc).isoformat().replace("+00:00", "Z"),
        "mode": args.mode,
        "scope": args.scope,
        "language": args.lang if args.mode == "model" else "verilog",
        "part": args.part,
        "clock_period_ns": args.clock_period,
        "toggle_rate_pct": args.toggle_rate,
        "flow": "Vivado synth_design (in-context, I/O buffers inserted; out-of-context fallback); "
                "clocks and I/O delays applied post-synthesis; vectorless power estimate at the "
                "stated default toggle rate",
        "source_report": os.path.abspath(args.report) if args.report else None,
        "generation_manifest": (source_report or {}).get("generation_manifest"),
        "n_targets": len(results),
        "n_ok": sum(1 for item in results if item["status"] == "ok"),
        "results": results,
    }
    out_path = os.path.abspath(args.out_json)
    os.makedirs(os.path.dirname(out_path), exist_ok=True)
    with open(out_path, "w", encoding="utf-8") as file:
        json.dump(payload, file, indent=2)
    print(f"\nPPA report saved to: {out_path}  ({payload['n_ok']}/{len(results)} synthesized)")


if __name__ == "__main__":
    main()
