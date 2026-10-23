"""
merge_vivado_results.py

Merges vivado_metrics.jsonl (written by run_vivado_all_models.tcl) into the
notebook's results_all_models.json.

 - Repairs the corruption left by the v2 TCL patcher:  "error": ""null
 - Overwrites the Vivado fields (success, area, ff, power, delay, error), including
   stale dash strings in "delay", and adds dsp, bram, power_dynamic, power_static,
   wns, clock and stage.
 - Never edits the input file; writes results_all_models_merged.json.

Usage (from results/open_models/):
    python ../../vivado/merge_vivado_results.py results_all_models.json vivado_metrics.jsonl [more.jsonl ...] [vivado_all.log]

A .log argument (the Vivado batch log from run_vivado_all_models.tcl) is used to fill in
the real ERROR text of every failed design.
"""
import json, re, sys, shutil
from collections import defaultdict

src = sys.argv[1] if len(sys.argv) > 1 else "results_all_models.json"
args = sys.argv[2:]
log_files = [a for a in args if a.lower().endswith(".log")]
jsonl_files = [a for a in args if not a.lower().endswith(".log")] or ["vivado_metrics.jsonl"]  # later overrides earlier
dst = src.replace(".json", "_merged.json")

text = open(src, encoding="utf-8").read()
try:
    rows = json.loads(text)
except json.JSONDecodeError:
    shutil.copy(src, src + ".bak")
    # "error": "<anything>"null  ->  "error": "<anything>"
    text = re.sub(r'("error"\s*:\s*"(?:[^"\\]|\\.)*")null', r"\1", text)
    rows = json.loads(text)          # still failing? the file needs manual repair
    print("Repaired malformed JSON (backup saved as .bak)")

metrics = {}
for jf in jsonl_files:
    with open(jf, encoding="utf-8") as f:
        for line in f:
            if line.strip():
                m = json.loads(line)
                metrics[(m["model"], m["task_id"], m["lang"])] = m

GENERIC = ("[Common 17-69]", "[Common 17-39]")     # "Command failed" / "failed due to earlier errors"

def parse_logs(paths):
    """{(model, task, lang): 'ERROR: ... | ERROR: ...'} from '### DESIGN model/task/lang' markers."""
    errs, cur = {}, None
    for path in paths:
        for line in open(path, encoding="utf-8", errors="replace"):
            mk = re.match(r"###\s*DESIGN\s+(\S+?)/(\S+?)/(\S+)\s*$", line.strip())
            if mk:
                cur = mk.groups(); errs.setdefault(cur, []); continue
            if cur and line.startswith("ERROR:") and not any(g in line for g in GENERIC):
                errs[cur].append(line.strip())
    return {k: " | ".join(dict.fromkeys(v))[:600] for k, v in errs.items() if v}

log_errors = parse_logs(log_files) if log_files else {}
if log_files:
    print(f"Read real error text for {len(log_errors)} designs from {', '.join(log_files)}")

VIVADO_FIELDS = ["success", "area", "ff", "dsp", "bram", "power", "power_dynamic",
                 "power_static", "wns", "delay", "clock", "stage", "error"]

matched = 0
for r in rows:
    m = metrics.get((r["model"], r["task_id"], r["lang"]))
    if m and r.get("valid_rtl"):      # ignore stale files left over from an older generation run
        matched += 1
        for k in VIVADO_FIELDS:
            r[k] = m.get(k)
        if not r.get("success"):
            r["error"] = log_errors.get((r["model"], r["task_id"], r["lang"])) or r.get("error")
    else:
        # never reached Vivado: invalid RTL / missing file
        r["success"] = False
        for k in VIVADO_FIELDS:
            if k not in ("success", "error"):
                r[k] = None
        r["error"] = r.get("reject_reason") or "not run in Vivado"

json.dump(rows, open(dst, "w", encoding="utf-8"), indent=2)
print(f"{matched}/{len(rows)} rows matched a Vivado result -> {dst}")

# quick sanity table: how far does each model get?
t = defaultdict(lambda: defaultdict(int))
for r in rows:
    k = (r["model"], r["lang"])
    t[k]["n"] += 1
    t[k]["valid"] += bool(r.get("valid_rtl"))
    t[k]["synth"] += bool(r.get("success"))
print(f"\n{'model':32s} lang  tasks  valid  synth")
for (model, lang), c in sorted(t.items()):
    print(f"{model:32s} {lang:4s}  {c['n']:5d}  {c['valid']:5d}  {c['synth']:5d}")

# most common failure reasons (needs the .log)
codes = defaultdict(list)
for r in rows:
    if r.get("valid_rtl") and not r.get("success") and r.get("error"):
        for c in set(re.findall(r"\[((?:Synth|VRFC|HDL|Vivado)[ \w]*\d+-\d+)\]", r["error"])):
            codes[c].append(f'{r["model"]}/{r["task_id"]}/{r["lang"]}')
if codes:
    print("\nMost common failure codes:")
    for c, where in sorted(codes.items(), key=lambda kv: -len(kv[1]))[:10]:
        print(f"  {c:18s} x{len(where):3d}   e.g. {where[0]}")