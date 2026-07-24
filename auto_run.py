import argparse
import csv
import os
import re
import time
import math
import shutil
import subprocess
import tqdm

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


def cal_atk(dic_list, n, k):
    sum_list = []
    for design in dic_list.keys():
        c = dic_list[design]["syntax_success"]
        sum_list.append(1 - math.comb(n - c, k) / math.comb(n, k))
    syntax_passk = sum(sum_list) / len(dic_list)

    sum_list = []
    for design in dic_list.keys():
        c = dic_list[design]["func_success"]
        sum_list.append(1 - math.comb(n - c, k) / math.comb(n, k))
    func_passk = sum(sum_list) / len(dic_list)
    print(f"\nsyntax pass@{k}: {syntax_passk:.4f},   func pass@{k}: {func_passk:.4f}")


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


design_names = [
    "adder_8bit", "adder_16bit", "adder_32bit", "adder_pipe_64bit", "adder_bcd", "sub_64bit",
    "multi_8bit", "multi_16bit", "multi_booth_8bit", "multi_pipe_4bit", "multi_pipe_8bit",
    "div_16bit", "radix2_div", "comparator_3bit", "comparator_4bit", "accu", "fixed_point_adder",
    "fixed_point_substractor", "float_multi", "asyn_fifo", "LIFObuffer", "right_shifter", "LFSR",
    "barrel_shifter", "fsm", "sequence_detector", "counter_12", "JC_counter", "ring_counter",
    "up_down_counter", "signal_generator", "square_wave", "clkgenerator", "instr_reg", "ROM", "RAM",
    "alu", "pe", "freq_div", "freq_divbyeven", "freq_divbyodd", "freq_divbyfrac", "calendar",
    "traffic_light", "width_8to16", "synchronizer", "edge_detect", "pulse_detect", "parallel2serial",
    "serial2parallel",
]

design_paths = {}
for root, dirs, files in os.walk("."):
    if "makefile" in files and "testbench.v" in files:
        name = os.path.basename(root)
        if name in design_names:
            design_paths[name] = os.path.abspath(root)

parser = argparse.ArgumentParser(description="Evaluate generated RTL on the RTLLM benchmark via Vivado XSim.")
parser.add_argument("--lang", choices=LANG_CONFIG.keys(), default="verilog",
                    help="HDL of the generated designs to evaluate (default: verilog).")
parser.add_argument("--gen-dir", default=None,
                    help="Directory containing trial subfolders (e.g. t1/) with generated RTL. "
                         "Defaults to the language preset (openrouter_deepseek_v4_pro, etc.).")
parser.add_argument("--trials", type=int, default=5,
                    help="Evaluate up to this many trials (t1..tN). Default: 5.")
parser.add_argument("--pass-k", nargs="+", type=int, default=[1, 2, 5],
                    help="pass@k metrics to report (default: 1 2 5).")
parser.add_argument("--csv", default=None,
                    help="Output CSV path. Defaults to <gen_dir_basename>.csv.")
cli_args = parser.parse_args()
LANG = LANG_CONFIG[cli_args.lang]

generation_path = os.path.abspath(cli_args.gen_dir or LANG["gen_dir"])
trial_ids = discover_trials(generation_path, cli_args.trials)
result_dic = {key: {"syntax_success": 0, "func_success": 0} for key in design_names}

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
        if design not in design_paths:
            progress_bar.update(1)
            continue

        target_folder = design_paths[design]
        generated_file = os.path.join(generation_path, trial_id, f"{design}{LANG['ext']}")

        if not os.path.exists(generated_file):
            progress_bar.update(1)
            continue

        os.chdir(target_folder)
        syntax_ok, output = run_vivado_sim(generated_file, LANG["hdl"])

        if syntax_ok:
            result_dic[design]["syntax_success"] += 1
            if "Pass" in output or "pass" in output:
                result_dic[design]["func_success"] += 1

        clean_sim_artifacts()
        os.chdir(root_dir)
        progress_bar.update(1)

    return result_dic


if trial_ids:
    for trial_id in trial_ids:
        result_dic = test_one_trial(trial_id, result_dic)
    progress_bar.close()

    n_trials = len(trial_ids)
    total_syntax_success = sum(1 for item in design_names if result_dic[item]["syntax_success"] > 0)
    total_func_success = sum(1 for item in design_names if result_dic[item]["func_success"] > 0)

    print("\n" + "=" * 40)
    print(f"BENCHMARK SUMMARY (Vivado XSim, lang={cli_args.lang}, gen_dir={os.path.basename(generation_path)})")
    print(f"Trials evaluated: {', '.join(trial_ids)} ({n_trials} total)")
    print(f"Designs with >=1 syntax pass: {total_syntax_success}/{len(design_names)}")
    print(f"Designs with >=1 functional pass: {total_func_success}/{len(design_names)}")
    print("=" * 40)

    for k in sorted(set(cli_args.pass_k)):
        if k > n_trials:
            print(f"\npass@{k}: skipped (need {k} trials, have {n_trials})")
            continue
        print(f"\n--- pass@{k} (n={n_trials}) ---")
        cal_atk(result_dic, n_trials, k)

    csv_path = cli_args.csv or f"{os.path.basename(generation_path)}.csv"
    with open(csv_path, "w", newline="", encoding="utf-8") as csv_file:
        writer = csv.DictWriter(csv_file, fieldnames=[
            "design", "syntax_success", "func_success",
            "syntax_pass_rate", "func_pass_rate", "n_trials",
        ])
        writer.writeheader()
        for design in design_names:
            s = result_dic[design]["syntax_success"]
            f = result_dic[design]["func_success"]
            writer.writerow({
                "design": design,
                "syntax_success": s,
                "func_success": f,
                "syntax_pass_rate": f"{s / n_trials:.4f}",
                "func_pass_rate": f"{f / n_trials:.4f}",
                "n_trials": n_trials,
            })
    print(f"\nResults saved to: {os.path.abspath(csv_path)}")
else:
    progress_bar.close()
    print("Error: Missing target directories.")
    print(f"Expected trial folders like t1..t{cli_args.trials} under: {generation_path}")
