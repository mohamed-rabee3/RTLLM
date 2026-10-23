import argparse
import csv
import json
import os
import re
import time
import math
import shutil
import subprocess
from datetime import datetime, timezone

import tqdm

from benchmark_config import BENCHMARK_DESIGNS, design_category, discover_design_paths

# RTLLM runner using AMD Vivado XSim (replaces Synopsys VCS / Icarus Verilog).
XSIM_SNAPSHOT = "rtllm_snap"
XVLOG = "xvlog"
XVHDL = "xvhdl"
XELAB = "xelab"
XSIM = "xsim"
ROOT_DIR = os.path.dirname(os.path.abspath(__file__))

# Per-language config. The testbench stays Verilog for both; a VHDL DUT is
# compiled with xvhdl and bound to the Verilog bench by XSim's mixed-language
# elaboration (entity/port names matched case-insensitively).
LANG_CONFIG = {
    "verilog":     {"ext": ".v",   "gen_dir": "openrouter_deepseek_v4_pro",      "hdl": "verilog"},
    "vhdl":        {"ext": ".vhd", "gen_dir": "openrouter_deepseek_v4_pro_vhdl", "hdl": "vhdl"},
    "qwen_verilog":{"ext": ".v",   "gen_dir": "qwen_verilog",                    "hdl": "verilog"},
    "qwen_vhdl":   {"ext": ".vhd", "gen_dir": "qwen_vhdl",                       "hdl": "vhdl"},
}


def load_env_file(env_path=None):
    """Load KEY=VALUE pairs from .env into os.environ (does not override existing vars)."""
    if env_path is None:
        env_path = os.path.join(ROOT_DIR, ".env")
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
            if not sep:
                continue
            key = key.strip()
            value = value.strip().strip('"').strip("'")
            if key and key not in os.environ:
                os.environ[key] = value


def _vivado_tool_exists(bin_dir, tool):
    """Return True if xvlog/xelab/xsim exist in bin (handles .bat wrappers on Windows)."""
    for ext in (".exe", ".bat", ""):
        if os.path.isfile(os.path.join(bin_dir, tool + ext)):
            return True
    return False


def _vivado_bin_candidates():
    candidates = []

    vivado_bin = os.environ.get("VIVADO_BIN")
    if vivado_bin:
        candidates.append(vivado_bin)

    vivado_home = os.environ.get("XILINX_VIVADO")
    if vivado_home:
        candidates.extend([
            os.path.join(vivado_home, "bin"),
            os.path.join(vivado_home, "Vivado", "bin"),
        ])

    for base in (r"C:\Xilinx", r"D:\Xilinx", r"E:\vivado", "/tools/Xilinx"):
        if not os.path.isdir(base):
            continue
        for entry in sorted(os.listdir(base), reverse=True):
            install_root = os.path.join(base, entry)
            candidates.extend([
                os.path.join(install_root, "bin"),
                os.path.join(install_root, "Vivado", "bin"),
            ])
            vivado_dir = os.path.join(install_root, "Vivado")
            if os.path.isdir(vivado_dir):
                for version in sorted(os.listdir(vivado_dir), reverse=True):
                    candidates.append(os.path.join(vivado_dir, version, "bin"))

    seen = set()
    unique = []
    for path in candidates:
        norm = os.path.normcase(os.path.normpath(path))
        if norm not in seen:
            seen.add(norm)
            unique.append(path)
    return unique


def setup_vivado_path():
    """Add Vivado bin directory to PATH if tools are not already available."""
    if shutil.which(XVLOG) and shutil.which(XELAB) and shutil.which(XSIM):
        return True

    for bin_dir in _vivado_bin_candidates():
        if all(_vivado_tool_exists(bin_dir, tool) for tool in (XVLOG, XELAB, XSIM)):
            os.environ["PATH"] = bin_dir + os.pathsep + os.environ.get("PATH", "")
            os.environ["XILINX_VIVADO"] = os.environ.get("XILINX_VIVADO", os.path.dirname(bin_dir))
            return True
    return False


def exec_shell(cmd_str, timeout=120):
    """Run cmd; on timeout kill the whole process tree.

    xsim spawns a child xsimk that holds xsim.dir/<snap>/xsimk.exe. A bare
    os.system could not be killed, so timed-out sims left orphan processes that
    locked the snapshot and broke the next design's elaboration. Popen lets us
    taskkill the tree.
    """
    proc = subprocess.Popen(cmd_str, shell=True)
    try:
        proc.wait(timeout=timeout)
        return 1
    except subprocess.TimeoutExpired:
        if os.name == "nt":
            subprocess.run(
                ["taskkill", "/F", "/T", "/PID", str(proc.pid)],
                capture_output=True,
            )
        else:
            proc.kill()
        try:
            proc.wait(timeout=10)
        except subprocess.TimeoutExpired:
            pass
        return 0


def discover_trials(generation_path, max_trials=5):
    """Return available trial folder names under generation_path.

    Supports RTLLM convention (t1..tN) and Pass1..PassN style folders.
    """
    if not os.path.isdir(generation_path):
        return []
    trials = []
    for i in range(1, max_trials + 1):
        trial_id = f"t{i}"
        if os.path.isdir(os.path.join(generation_path, trial_id)):
            trials.append(trial_id)
    if trials:
        return trials

    def trial_sort_key(name):
        match = re.search(r"(\d+)$", name)
        return int(match.group(1)) if match else name

    for name in sorted(os.listdir(generation_path), key=trial_sort_key):
        path = os.path.join(generation_path, name)
        if not os.path.isdir(path):
            continue
        if re.fullmatch(r"(?i)t\d+|pass\d+", name):
            trials.append(name)
    return trials[:max_trials] if max_trials else trials


def calculate_pass_at_k(dic_list, n, k):
    """Return unbiased syntax and functional pass@k estimates.

    The estimator is averaged across designs and assumes ``n`` independent
    samples per design, with ``c`` successful samples for each design:
    ``1 - C(n-c, k) / C(n, k)``.
    """
    if not dic_list:
        raise ValueError("Cannot calculate pass@k for an empty result set.")
    if n < 1:
        raise ValueError("n must be at least 1.")
    if not 1 <= k <= n:
        raise ValueError(f"k must be between 1 and n (received k={k}, n={n}).")

    denominator = math.comb(n, k)

    def mean_score(success_key):
        scores = []
        for design_result in dic_list.values():
            successes = design_result[success_key]
            scores.append(1 - math.comb(n - successes, k) / denominator)
        return sum(scores) / len(scores)

    return {
        "k": k,
        "syntax_pass_at_k": mean_score("syntax_success"),
        "func_pass_at_k": mean_score("func_success"),
    }


def print_pass_at_k(dic_list, n, k):
    metrics = calculate_pass_at_k(dic_list, n, k)
    print(
        f"syntax pass@{k}: {metrics['syntax_pass_at_k']:.4f},   "
        f"func pass@{k}: {metrics['func_pass_at_k']:.4f}"
    )
    return metrics


def clean_sim_artifacts():
    for name in ("compile.log", "compile_tb.log", "elab.log", "run.log", "output.txt",
                 "xvlog.pb", "xvhdl.pb", "xelab.pb", "xvhdl.log"):
        if not os.path.exists(name):
            continue
        # xsim may still hold a handle briefly after a sim timeout; retry, then skip.
        for attempt in range(5):
            try:
                os.remove(name)
                break
            except OSError:
                if attempt == 4:
                    break
                time.sleep(0.5)
    for name in ("xsim.dir", ".Xil"):
        # Retry: a prior `xsim -R` may still hold xsim.dir/<snap>/xsimk.exe on
        # Windows; leaving a stale snapshot makes the next xelab fail to link.
        for attempt in range(5):
            if not os.path.isdir(name):
                break
            shutil.rmtree(name, ignore_errors=True)
            if not os.path.isdir(name):
                break
            time.sleep(0.5)


def find_top_module(tb_file="testbench.v"):
    """Return the top-level testbench module name.

    Convention: the bench top is declared without ports (`module foo;` or
    `module foo();`). Strip comments first, prefer the portless module, and
    fall back to the first module declared.
    """
    try:
        with open(tb_file, "r", encoding="utf-8", errors="replace") as file:
            text = file.read()
    except OSError:
        return "testbench"

    # Strip block and line comments so commented-out modules are ignored.
    text = re.sub(r"/\*.*?\*/", "", text, flags=re.DOTALL)
    text = re.sub(r"//[^\n]*", "", text)

    first = None
    for match in re.finditer(r"\bmodule\s+([A-Za-z_]\w*)\s*(#\s*\([^)]*\)\s*)?(\(?)", text):
        name, _params, paren = match.group(1), match.group(2), match.group(3)
        if first is None:
            first = name
        # Portless declaration -> module name; or module name();
        rest = text[match.end():match.end() + 64].lstrip()
        if paren == "":
            return name  # `module foo;`
        if rest.startswith(")"):
            return name  # `module foo();`
    return first or "testbench"


def run_vivado_sim(design_file, lang="verilog"):
    """Compile, elaborate, and simulate with Vivado XSim. Returns (syntax_ok, output_text).

    For VHDL the DUT is compiled with xvhdl and the (still Verilog) testbench with
    xvlog; XSim's mixed-language elaboration binds them. For Verilog both files go
    through a single xvlog call.
    """
    clean_sim_artifacts()

    # The DUT (model output) is compiled in strict mode so it is scored as the
    # plain HDL it must be; the reference testbench is compiled with -sv because
    # several RTLLM benches use SystemVerilog (e.g. `break`) that the upstream
    # VCS flow accepted but xvlog rejects by default.
    if lang == "vhdl":
        if os.system(f'{XVHDL} -2008 -log xvhdl.log "{design_file}"') != 0:
            return False, ""
        if os.system(f"{XVLOG} -sv -log compile_tb.log testbench.v") != 0:
            return False, ""
    else:
        if os.system(f'{XVLOG} -log compile.log "{design_file}"') != 0:
            return False, ""
        if os.system(f"{XVLOG} -sv -log compile_tb.log testbench.v") != 0:
            return False, ""

    top = find_top_module("testbench.v")
    elab_cmd = (
        f"{XELAB} -debug typical -timescale 1ns/1ps -top {top} "
        f"-snapshot {XSIM_SNAPSHOT} -log elab.log"
    )
    if os.system(elab_cmd) != 0:
        return False, ""

    sim_cmd = f"{XSIM} {XSIM_SNAPSHOT} -R > output.txt 2>&1"
    exec_shell(sim_cmd)

    output = ""
    if os.path.exists("output.txt"):
        with open("output.txt", "r", encoding="utf-8", errors="replace") as file:
            output = file.read()
    return True, output


design_names = list(BENCHMARK_DESIGNS)
design_paths = discover_design_paths(ROOT_DIR)
missing_designs = [name for name in design_names if name not in design_paths]
if missing_designs:
    raise SystemExit(f"Error: missing benchmark design folders: {', '.join(missing_designs)}")

parser = argparse.ArgumentParser(description="Evaluate generated RTL on the RTLLM benchmark via Vivado XSim.")
parser.add_argument("--lang", choices=LANG_CONFIG.keys(), default="verilog",
                    help="HDL of the generated designs to evaluate (default: verilog).")
parser.add_argument("--gen-dir", default=None,
                    help="Directory containing trial subfolders (e.g. t1/) with generated RTL. "
                         "Defaults to the language preset (openrouter_deepseek_v4_pro, etc.).")
parser.add_argument("--trials", type=int, default=5,
                    help="Evaluate up to this many trials (t1..tN). Default: 5.")
parser.add_argument("--pass-k", nargs="+", type=int, default=[1, 2, 3, 4, 5],
                    help="pass@k metrics to report (default: 1 2 3 4 5).")
parser.add_argument("--csv", default=None,
                    help="Output CSV path. Defaults to <gen_dir_basename>.csv.")
parser.add_argument("--json", default=None,
                    help="Detailed JSON report path. Defaults to <gen_dir_basename>_benchmark_results.json.")
parser.add_argument("--resume-from", default=None,
                    help="Reuse completed trial/design outcomes from an existing JSON report. "
                         "Only normal pass/syntax-fail/functional-fail records for the same "
                         "language, generation directory, and available generated file are reused.")
cli_args = parser.parse_args()
LANG = LANG_CONFIG[cli_args.lang]

generation_arg = cli_args.gen_dir or LANG["gen_dir"]
generation_path = os.path.abspath(
    generation_arg if os.path.isabs(generation_arg) else os.path.join(ROOT_DIR, generation_arg)
)
trial_ids = discover_trials(generation_path, cli_args.trials)
result_dic = {key: {"syntax_success": 0, "func_success": 0} for key in design_names}
trial_results = []
resume_results = {}

if cli_args.resume_from:
    resume_path = os.path.abspath(cli_args.resume_from)
    if os.path.isfile(resume_path):
        try:
            with open(resume_path, encoding="utf-8") as resume_file:
                resume_report = json.load(resume_file)
        except (OSError, ValueError) as exc:
            raise SystemExit(f"Error: cannot load resume report {resume_path}: {exc}") from exc

        if resume_report.get("language") != LANG["hdl"]:
            raise SystemExit(
                f"Error: resume report language is {resume_report.get('language')!r}, "
                f"expected {LANG['hdl']!r}."
            )
        prior_generation_path = os.path.abspath(resume_report.get("generation_path") or "")
        if os.path.normcase(prior_generation_path) != os.path.normcase(generation_path):
            raise SystemExit(
                f"Error: resume report generation path is {prior_generation_path!r}, "
                f"expected {generation_path!r}."
            )

        reusable_statuses = {"passed", "syntax_failed", "functional_failed"}
        for item in resume_report.get("trial_results") or []:
            trial_id = item.get("trial")
            design = item.get("design")
            generated_file = os.path.join(generation_path, str(trial_id), f"{design}{LANG['ext']}")
            if (
                trial_id in trial_ids
                and design in result_dic
                and item.get("status") in reusable_statuses
                and os.path.isfile(generated_file)
                and os.path.getsize(generated_file) > 0
            ):
                resume_results[(trial_id, design)] = dict(item)
        print(f"Resume mode: reusing {len(resume_results)} completed trial/design outcomes from {resume_path}.")

load_env_file()

if not setup_vivado_path():
    vivado_home = os.environ.get("XILINX_VIVADO", "(not set)")
    print("Error: Vivado XSim tools (xvlog, xelab, xsim) not found.")
    print(f"XILINX_VIVADO from .env: {vivado_home}")
    print("Expected tools under <install>/bin or <install>/Vivado/bin")
    print(r"Example .env: XILINX_VIVADO=E:\vivado\2025.2")
    print("Or set VIVADO_BIN to the bin folder directly.")
    raise SystemExit(1)

progress_bar = tqdm.tqdm(total=len(design_names) * max(len(trial_ids), 1))


def test_one_trial(trial_id, result_dic):
    root_dir = os.getcwd()
    for design in design_names:
        resume_key = (trial_id, design)
        if resume_key in resume_results:
            item = dict(resume_results[resume_key])
            trial_results.append(item)
            if item.get("syntax_pass"):
                result_dic[design]["syntax_success"] += 1
            if item.get("functional_pass"):
                result_dic[design]["func_success"] += 1
            progress_bar.update(1)
            continue

        if design not in design_paths:
            trial_results.append({
                "trial": trial_id,
                "design": design,
                "category": "Unknown",
                "syntax_pass": False,
                "functional_pass": False,
                "status": "missing_benchmark_design",
                "runtime_seconds": 0.0,
            })
            progress_bar.update(1)
            continue

        target_folder = design_paths[design]
        generated_file = os.path.join(generation_path, trial_id, f"{design}{LANG['ext']}")
        category = design_category(ROOT_DIR, target_folder)

        if not os.path.exists(generated_file):
            trial_results.append({
                "trial": trial_id,
                "design": design,
                "category": category,
                "syntax_pass": False,
                "functional_pass": False,
                "status": "missing_generated_file",
                "runtime_seconds": 0.0,
            })
            progress_bar.update(1)
            continue

        started = time.monotonic()
        try:
            os.chdir(target_folder)
            syntax_ok, output = run_vivado_sim(generated_file, LANG["hdl"])
            functional_ok = syntax_ok and bool(re.search(r"Your\s+Design\s+Passed", output, re.IGNORECASE))

            if syntax_ok:
                result_dic[design]["syntax_success"] += 1
            if functional_ok:
                result_dic[design]["func_success"] += 1

            trial_results.append({
                "trial": trial_id,
                "design": design,
                "category": category,
                "syntax_pass": syntax_ok,
                "functional_pass": functional_ok,
                "status": "passed" if functional_ok else ("functional_failed" if syntax_ok else "syntax_failed"),
                "runtime_seconds": round(time.monotonic() - started, 3),
            })
        except Exception as exc:
            trial_results.append({
                "trial": trial_id,
                "design": design,
                "category": category,
                "syntax_pass": False,
                "functional_pass": False,
                "status": "runner_error",
                "runtime_seconds": round(time.monotonic() - started, 3),
                "error": f"{type(exc).__name__}: {exc}",
            })
        finally:
            clean_sim_artifacts()
            os.chdir(root_dir)
        progress_bar.update(1)

    return result_dic


if trial_ids:
    for trial_id in trial_ids:
        result_dic = test_one_trial(trial_id, result_dic)
    progress_bar.close()
    trial_order = {trial_id: index for index, trial_id in enumerate(trial_ids)}
    design_order = {design: index for index, design in enumerate(design_names)}
    trial_results.sort(
        key=lambda item: (
            trial_order.get(item.get("trial"), len(trial_order)),
            design_order.get(item.get("design"), len(design_order)),
        )
    )

    n_trials = len(trial_ids)
    total_syntax_success = sum(1 for item in design_names if result_dic[item]["syntax_success"] > 0)
    total_func_success = sum(1 for item in design_names if result_dic[item]["func_success"] > 0)

    print("\n" + "=" * 40)
    print(f"BENCHMARK SUMMARY (Vivado XSim, lang={cli_args.lang}, gen_dir={os.path.basename(generation_path)})")
    print(f"Trials evaluated: {', '.join(trial_ids)} ({n_trials} total)")
    print(f"Designs with >=1 syntax pass: {total_syntax_success}/{len(design_names)}")
    print(f"Designs with >=1 functional pass: {total_func_success}/{len(design_names)}")
    print("=" * 40)

    pass_metrics = []
    for k in sorted(set(cli_args.pass_k)):
        if k < 1:
            raise SystemExit(f"Error: pass@k requires k >= 1 (received {k}).")
        if k > n_trials:
            print(f"\npass@{k}: skipped (need {k} trials, have {n_trials})")
            continue
        print(f"\n--- pass@{k} (n={n_trials}) ---")
        pass_metrics.append(print_pass_at_k(result_dic, n_trials, k))

    csv_path = cli_args.csv or f"{os.path.basename(generation_path)}.csv"
    csv_path = os.path.abspath(csv_path)
    os.makedirs(os.path.dirname(csv_path), exist_ok=True)
    with open(csv_path, "w", newline="", encoding="utf-8") as csv_file:
        writer = csv.DictWriter(csv_file, fieldnames=[
            "design", "category", "syntax_success", "func_success",
            "syntax_pass_rate", "func_pass_rate", "n_trials",
        ])
        writer.writeheader()
        for design in design_names:
            s = result_dic[design]["syntax_success"]
            f = result_dic[design]["func_success"]
            writer.writerow({
                "design": design,
                "category": design_category(ROOT_DIR, design_paths[design]),
                "syntax_success": s,
                "func_success": f,
                "syntax_pass_rate": f"{s / n_trials:.4f}",
                "func_pass_rate": f"{f / n_trials:.4f}",
                "n_trials": n_trials,
            })
    print(f"\nResults saved to: {csv_path}")

    generation_manifest = {}
    manifest_path = os.path.join(generation_path, "run_manifest.json")
    if os.path.isfile(manifest_path):
        try:
            with open(manifest_path, encoding="utf-8") as manifest_file:
                generation_manifest = json.load(manifest_file)
        except (OSError, ValueError):
            generation_manifest = {}

    design_results = []
    for design in design_names:
        result = result_dic[design]
        design_results.append({
            "design": design,
            "category": design_category(ROOT_DIR, design_paths[design]),
            "syntax_success": result["syntax_success"],
            "functional_success": result["func_success"],
            "n_trials": n_trials,
        })

    json_path = os.path.abspath(
        cli_args.json or f"{os.path.basename(generation_path)}_benchmark_results.json"
    )
    os.makedirs(os.path.dirname(json_path), exist_ok=True)
    report = {
        "schema_version": 1,
        "generated_at": datetime.now(timezone.utc).isoformat().replace("+00:00", "Z"),
        "benchmark": "RTLLM 2.0 full 72-design repository set",
        "simulator": "AMD Vivado XSim",
        "language": LANG["hdl"],
        "generation_path": generation_path,
        "generation_manifest": generation_manifest,
        "trials": trial_ids,
        "n_trials": n_trials,
        "n_designs": len(design_names),
        "resume": {
            "source": os.path.abspath(cli_args.resume_from) if cli_args.resume_from else None,
            "reused_trial_results": len(resume_results),
            "evaluated_trial_results": len(trial_results) - len(resume_results),
        },
        "summary": {
            "designs_with_syntax_pass": total_syntax_success,
            "designs_with_functional_pass": total_func_success,
            "total_designs": len(design_names),
        },
        "pass_at_k": pass_metrics,
        "design_results": design_results,
        "trial_results": trial_results,
        "sources": {
            "chatmock": "https://github.com/RayBytes/ChatMock",
            "gpt_5_6_guidance": "https://developers.openai.com/api/docs/guides/model-guidance?model=gpt-5.6-sol",
            "rtllm": "https://github.com/hkust-zhiyao/RTLLM",
        },
    }
    with open(json_path, "w", encoding="utf-8") as json_file:
        json.dump(report, json_file, indent=2)
    print(f"Detailed report saved to: {json_path}")
else:
    progress_bar.close()
    print("Error: Missing target directories.")
    print(f"Expected trial folders like t1..t{cli_args.trials} under: {generation_path}")
    raise SystemExit(1)
