"""Prompt construction: per-language rules (LANG) and three prompt styles
(chat template / RTLCoder "### Instruction" / base-model file completion)."""
import re

from config import BASE_MODELS

SIM_ONLY = [(r"\binitial\b", "initial block"), (r"#\s*\d+", "# delay"),
            (r"\$(?:display|monitor|finish|stop|time|dumpfile|dumpvars)\b", "simulation system task"),
            (r"\bforever\b", "forever"), (r"\bwait\s*\(", "wait()")]
SV_ONLY  = [(r"\b(?:logic|always_comb|always_ff|always_latch|typedef|enum|struct|interface|endinterface|package|endpackage)\b",
             "SystemVerilog construct in plain Verilog"),
            (r"(?<![\w'])'[01xz]\b", "SystemVerilog fill literal in plain Verilog")]
VHDL_SIM = [(r"\bwait\b", "wait"), (r"\bafter\s+\d", "after (delay)"), (r"\breport\b", "report"), (r"\bassert\b", "assert")]

LANG = {
  "v":   dict(label="Verilog-2001", ext=".v", cmt="//", fence="verilog", forbidden=SIM_ONLY + SV_ONLY,
              shape="Start with `module`, end with `endmodule`.",
              style="Plain Verilog-2001: `wire`/`reg`, `assign`, `always @(*)` (combinational), `always @(posedge clk)` (sequential). "
                    "No SystemVerilog constructs (logic, always_ff, always_comb, typedef, enum, interface, package).",
              never="initial, #delay, $display, $monitor, $finish, $stop, $time, $dumpfile, $dumpvars, forever, wait("),
  "sv":  dict(label="SystemVerilog", ext=".sv", cmt="//", fence="systemverilog", forbidden=SIM_ONLY,
              shape="Start with `module`, end with `endmodule`.",
              style="Use `logic` for signals, `always_comb` (combinational) and `always_ff @(posedge clk)` (sequential).",
              never="initial, #delay, $display, $monitor, $finish, $stop, $time, $dumpfile, $dumpvars, forever, wait("),
  "vhd": dict(label="VHDL-2008", ext=".vhd", cmt="--", fence="vhdl", forbidden=VHDL_SIM,
              shape="Start with `library ieee;`, end with `end architecture`.",
              style="Use std_logic / std_logic_vector (ieee.numeric_std for arithmetic) and complete process sensitivity lists.",
              never="wait, report, after (time delay), assert"),
}

def system_prompt(lang):
    s = LANG[lang]
    return (f"You are an expert RTL hardware designer. Write ONLY synthesizable {s['label']} for Xilinx Vivado.\n\n"
            "RULES — ALL MANDATORY:\n"
            "- Output raw code ONLY. No markdown, no backticks, no explanations.\n"
            f"- {s['shape']} Nothing before or after.\n"
            "- Use EXACTLY the module/entity names given in the task. Helper modules go in the same file.\n"
            f"- {s['style']}\n- NEVER use: {s['never']}\n- Do NOT write a testbench.")

def user_message(task, lang):
    label = LANG[lang]["label"]
    prompt = task["prompt"] if lang == "v" else re.sub(r"Verilog", label, task["prompt"])   # "in Verilog code" -> "in VHDL-2008 code"
    return f"Language: {label}\nTop-level module/entity: {task['top']}\n\n{prompt}"

def code_prefix(task, lang):
    """First lines of the file that a base model must continue."""
    if lang == "vhd":
        return f"library ieee;\nuse ieee.std_logic_1164.all;\nuse ieee.numeric_std.all;\n\nentity {task['modules'][0]} is\n  port ("
    return f"module {task['modules'][0]}("

def family(tok, model_id):
    if "rtlcoder" in model_id.lower():                         return "hash"
    if model_id in BASE_MODELS or not tok.chat_template:       return "base"
    return "chat"

def build_prompt(tok, model_id, task, lang):
    fam, sysmsg, user = family(tok, model_id), system_prompt(lang), user_message(task, lang)
    if fam == "hash":                                          # RTLCoder / DeepSeek-v1 style
        return f"### Instruction:\n{sysmsg}\n\n{user}\n### Response:\n"
    if fam == "chat":
        for msgs in ([{"role": "system", "content": sysmsg}, {"role": "user", "content": user}],
                     [{"role": "user", "content": sysmsg + "\n\n" + user}]):          # 2nd try: no system role
            try:
                return tok.apply_chat_template(msgs, tokenize=False, add_generation_prompt=True, enable_thinking=False)
            except Exception:
                pass
    c = LANG[lang]["cmt"]                                      # base: comment header + start of the file
    header = [f"{LANG[lang]['label']}, synthesizable, for Xilinx Vivado. No testbench.",
              f"Modules: {', '.join(task['modules'])}   (top: {task['top']})", ""] + user.split("\n\n", 1)[1].splitlines()
    return "\n".join(f"{c} {l}".rstrip() for l in header) + "\n" + code_prefix(task, lang)