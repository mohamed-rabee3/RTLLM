"""Extract RTL from raw model output and validate it before it goes to Vivado."""
import re

from prompts import LANG, code_prefix

def blank_comments(code, lang):
    """Replace comments by spaces (same length, so indices still match the original text)."""
    pat = r"--[^\n]*" if lang == "vhd" else r"//[^\n]*|/\*.*?\*/"
    return re.sub(pat, lambda m: re.sub(r"[^\n]", " ", m.group(0)), code, flags=re.S)

def design_end(code, lang, modules):
    """Index just after the point where every required module/entity exists and every opened
    module/architecture is closed (helpers placed before the top are fine). None = not finished."""
    vhd, unit = lang == "vhd", ("entity" if lang == "vhd" else "module")
    fl, clean = (re.I if vhd else 0), blank_comments(code, lang)
    if vhd:
        opens = [m.start() for m in re.finditer(r"\barchitecture\s+\w+\s+of\b", clean, re.I)]
        names = {m.lower() for m in re.findall(r"\barchitecture\s+(\w+)\s+of\b", clean, re.I)}
        pat = r"\bend\s+architecture\b[^;]*;" + (rf"|\bend\s+(?:{'|'.join(map(re.escape, names))})\s*;" if names else "")
    else:
        opens, pat = [m.start() for m in re.finditer(r"\bmodule\b", clean)], r"\bendmodule\b"
    for k, m in enumerate(re.finditer(pat, clean, fl), 1):
        if sum(o < m.start() for o in opens) <= k and \
           all(re.search(rf"\b{unit}\s+{re.escape(n)}\b", clean[:m.end()], fl) for n in modules):
            return m.end()
    return None

def finish_base_output(task, lang, continuation):
    """Base-model output = prefix + continuation, cut at the end of the design and fenced for extract()."""
    code = code_prefix(task, lang) + continuation
    cut = design_end(code, lang, task["modules"])
    return f"```{LANG[lang]['fence']}\n{code[:cut] if cut else code}\n```"

def is_looping(text, block=400, reps=3):
    """True when the last `block` characters already occurred `reps` times: the model is repeating itself."""
    return len(text) > block * reps and text.count(text[-block:]) >= reps

def is_testbench(block):
    return bool(re.search(r"\b(?:module|entity)\s+(?:tb\w*|\w*_tb|testbench\w*|test_\w*|\w*_test)\b", block, re.I))

def extract(raw, lang):
    """Code from the model output: every fenced design block (testbenches dropped), else bare module..endmodule / entity..end architecture."""
    raw = re.sub(r"<think>.*?</think>", "", raw, flags=re.S)
    key = r"\bentity\b" if lang == "vhd" else r"\bmodule\b"
    blocks = [b.strip() for b in re.findall(r"```[\w+-]*[ \t]*\n(.*?)```", raw, re.S)
              if re.search(key, b, re.I) and not is_testbench(b)]
    if blocks:
        return "\n\n".join(blocks)
    if lang == "vhd":
        m = re.search(r"\b(?:library|entity)\b.*\bend\s+architecture\b[^;]*;", raw, re.S | re.I)
    else:
        m = re.search(r"\bmodule\b.*\bendmodule\b", raw, re.S)
    return m.group(0).strip() if m else None

def validate(code, lang, modules):
    """(ok, reason). Requires every module named in the prompt, and no simulation-only / wrong-language constructs."""
    if not code or not code.strip():
        return False, "extraction failed"
    clean, fl = blank_comments(code, lang), (re.I if lang == "vhd" else 0)
    unit = "entity" if lang == "vhd" else "module"
    for m in modules:
        if not re.search(rf"\b{unit}\s+{re.escape(m)}\b", clean, fl):
            return False, f"missing {unit} '{m}'"
    if design_end(code, lang, modules) is None:
        return False, "incomplete (no end of design)"
    for pat, label in LANG[lang]["forbidden"]:
        m = re.search(pat, clean, re.I)
        if m:
            return False, f"forbidden: {label} ('{m.group(0)}')"
    return True, "valid"