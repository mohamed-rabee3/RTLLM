"""Gather every 72-design model's results, generated code, CSVs and workbooks into one folder.

Layout (re-run after any new benchmark; the destination is rebuilt from scratch):

    <dest>/
      README.md
      00_comparison/   cross-model workbook + leaderboard, best-per-design, code-metrics CSVs
      01_golden/       golden RTL PPA baseline (JSON + CSV)
      NN_<model>/
        <lang>/
          reports/     workbook, design/trial/PPA CSVs, raw JSON reports
          code/        <Category>/<design>/t1..t5.<ext>, run_manifest.json, code_index.csv
        logs/          run logs
"""

from __future__ import annotations

import argparse
import csv
import os
import re
import shutil
from collections import defaultdict

from benchmark_config import BENCHMARK_DESIGNS
from compare_models import (
    BEST_METRICS, GOLDEN_PPA, HDL_EXT, KS, LANG_LABEL, LANGS, MODELS, ROOT_DIR, candidate_metrics,
    golden_metrics, load_json, load_models, metrics, overall_winners, ppa_ratios, short_name, winners,
)
from create_excel_report import count_code_lines


PPA_COLUMNS = ("design", "category", "trial", "status", "top", "logic_cells", "luts", "regs", "carry", "dsp",
               "bram", "iob", "sequential", "dynamic_power_w", "static_power_w", "total_power_w",
               "critical_path_ns", "slack_ns", "fmax_mhz", "logic_levels")


def parse_args():
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--dest", default=os.path.join(ROOT_DIR, "outputs", "RTLLM_all72_results"))
    return parser.parse_args()


def safe_name(text):
    return re.sub(r"[^A-Za-z0-9.\-]+", "_", text).strip("_")


def write_csv(path, header, rows):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w", newline="", encoding="utf-8") as file:
        writer = csv.writer(file)
        writer.writerow(header)
        writer.writerows(rows)


def write_ppa_csv(path, records):
    write_csv(path, PPA_COLUMNS, [[r.get(c) for c in PPA_COLUMNS] for r in records])


def copy(src, dst):
    os.makedirs(os.path.dirname(dst), exist_ok=True)
    shutil.copy2(src, dst)


def collect_language(model, folder, prefix, lang, lang_data, dest):
    report = lang_data["report"]
    src_dir = os.path.join(ROOT_DIR, "outputs", folder)
    reports = os.path.join(dest, "reports")
    for name in os.listdir(src_dir):
        # Only the 72-design artifacts; older 50-design reports stay behind.
        if name.startswith(f"{prefix}_{lang}_all72_") or name == f"{prefix}_{lang}_ppa.json" \
                or (name.endswith(f"_{lang}_all72_results.xlsx")):
            copy(os.path.join(src_dir, name), os.path.join(reports, name))
    if lang_data["ppa"]:
        write_ppa_csv(os.path.join(reports, f"{prefix}_{lang}_ppa.csv"), lang_data["ppa"])

    gen_dir = report["generation_path"]
    code = os.path.join(dest, "code")
    manifest = os.path.join(gen_dir, "run_manifest.json")
    if os.path.isfile(manifest):
        copy(manifest, os.path.join(code, "run_manifest.json"))
    ppa_trial = {r["design"]: r.get("trial") for r in lang_data["ppa"] or []}
    ext = HDL_EXT[lang]
    index = []
    for t in report["trial_results"]:
        design, trial = t["design"], t["trial"]
        src = os.path.join(gen_dir, trial, design + ext)
        rel = os.path.join(t.get("category") or "Uncategorized", design, trial + ext)
        total, lines = count_code_lines(src, lang)
        if total is not None:
            copy(src, os.path.join(code, rel))
        index.append([design, t.get("category"), trial, t.get("syntax_pass"), t.get("functional_pass"),
                      t.get("status"), lines, total, ppa_trial.get(design) == trial,
                      rel.replace(os.sep, "/") if total is not None else None])
    write_csv(os.path.join(code, "code_index.csv"),
              ["design", "category", "trial", "syntax_pass", "functional_pass", "status", "code_lines",
               "total_lines", "used_for_ppa", "file"], index)
    write_csv(os.path.join(reports, f"{prefix}_{lang}_all72_trial_results.csv"),
              ["design", "category", "trial", "syntax_pass", "functional_pass", "status", "code_lines",
               "total_lines", "runtime_seconds"],
              [[t["design"], t.get("category"), t["trial"], t.get("syntax_pass"), t.get("functional_pass"),
                t.get("status"), row[6], row[7], t.get("runtime_seconds")]
               for t, row in zip(report["trial_results"], index)])
    return sum(1 for row in index if row[-1])


def build_comparison(models, golden, dest):
    os.makedirs(dest, exist_ok=True)
    comparison = os.path.join(ROOT_DIR, "outputs", "RTLLM_Model_Comparison_all72.xlsx")
    if os.path.isfile(comparison):
        copy(comparison, os.path.join(dest, os.path.basename(comparison)))

    rows = []
    for model in models:
        for lang in LANGS:
            data = model["langs"].get(lang)
            if not data:
                continue
            m = metrics(data)
            ppa = ppa_ratios(data["ppa"], golden) or {}
            rows.append([model["name"], LANG_LABEL[lang], m["n"]]
                        + [round(m[f"syntax@{k}"], 4) for k in KS] + [round(m[f"func@{k}"], 4) for k in KS]
                        + [m["solved"], m["solved_all"], ppa.get("synth_ok"),
                           *(round(ppa[k], 4) if ppa.get(k) else None for k in ("area", "power", "delay"))])
    write_csv(os.path.join(dest, "leaderboard.csv"),
              ["model", "language", "trials"] + [f"syntax_pass@{k}" for k in KS] + [f"func_pass@{k}" for k in KS]
              + ["designs_solved", "designs_solved_all_trials", "synth_ok", "area_vs_golden_geomean",
                 "dyn_power_vs_golden_geomean", "delay_vs_golden_geomean"], rows)

    tally = defaultdict(lambda: defaultdict(int))
    metric_rows = []
    for lang in LANGS:
        present = [m for m in models if lang in m["langs"]]
        best_rows = []
        for design in BENCHMARK_DESIGNS:
            gold = golden_metrics(golden, design, lang)
            candidates = {}
            for model in present:
                cand = candidate_metrics(model, lang, design)
                category = model["langs"][lang]["designs"][design].get("category")
                metric_rows.append([LANG_LABEL[lang], design, category, model["name"], "PASS" if cand else "FAIL"]
                                   + ([cand["trial"], cand["code_lines"]] + [cand[k] for _l, k, _f in BEST_METRICS[1:]]
                                      if cand else [None] * 5) + gold)
                if cand:
                    candidates[short_name(model)] = cand
            row = [design, category, len(candidates), "; ".join(candidates) or "None"]
            for _label, key, _fmt in BEST_METRICS:
                names, value = winners(candidates, key)
                row += ["; ".join(names) or None, value]
                for name in names:
                    tally[(lang, name)][key] += 1
            overall = overall_winners(candidates)
            for name in overall:
                tally[(lang, name)]["overall"] += 1
            for name in candidates:
                tally[(lang, name)]["solved"] += 1
            best_rows.append(row + ["; ".join(overall) or None] + gold)
        write_csv(os.path.join(dest, f"best_per_design_{lang}.csv"),
                  ["design", "category", "models_solved", "solved_by", "fewest_code_lines_model", "code_lines",
                   "smallest_area_model", "logic_cells", "lowest_dyn_power_model", "dynamic_power_w",
                   "shortest_delay_model", "critical_path_ns", "overall_best_model", "golden_code_lines",
                   "golden_logic_cells", "golden_dynamic_power_w", "golden_critical_path_ns"], best_rows)
    write_csv(os.path.join(dest, "code_metrics_all_models.csv"),
              ["language", "design", "category", "model", "passed", "trial", "code_lines", "logic_cells",
               "dynamic_power_w", "critical_path_ns", "golden_code_lines", "golden_logic_cells",
               "golden_dynamic_power_w", "golden_critical_path_ns"], metric_rows)
    write_csv(os.path.join(dest, "best_model_wins.csv"),
              ["model", "language", "designs_solved", "fewest_code_lines", "smallest_area", "lowest_dyn_power",
               "shortest_delay", "overall_best"],
              [[model["name"], LANG_LABEL[lang], tally[(lang, short_name(model))]["solved"]]
               + [tally[(lang, short_name(model))][k] for _l, k, _f in BEST_METRICS]
               + [tally[(lang, short_name(model))]["overall"]]
               for lang in LANGS for model in models if lang in model["langs"]])
    return rows


def write_readme(dest, entries, leaderboard):
    lines = [
        "# RTLLM 72-design benchmark results",
        "",
        "All models benchmarked on the full 72-design set (RTLLM 2.0 + 22 added designs), Verilog and VHDL,",
        "5 trials per design, Vivado XSim 2025.2 functional check, PPA from Vivado synthesis on Spartan-7",
        "xc7s100fgga676-2 at 10 ns / 25% toggle (first passing trial per design).",
        "",
        "## Leaderboard",
        "",
        "| Model | Language | func pass@1 | func pass@5 | Solved | Area vs golden | Power vs golden | Delay vs golden |",
        "|---|---|---|---|---|---|---|---|",
    ]
    for r in leaderboard:
        fmt = lambda v: f"{v:.2f}x" if v else "-"
        lines.append(f"| {r[0]} | {r[1]} | {r[8]:.1%} | {r[12]:.1%} | {r[13]}/72 | {fmt(r[16])} | {fmt(r[17])} | {fmt(r[18])} |")
    lines += [
        "",
        "## Layout",
        "",
        "```",
        "00_comparison/          RTLLM_Model_Comparison_all72.xlsx (all sheets), leaderboard.csv,",
        "                        best_per_design_{verilog,vhdl}.csv, best_model_wins.csv,",
        "                        code_metrics_all_models.csv",
        "01_golden/              golden_ppa.json / golden_ppa.csv (reference RTL synthesis)",
        "NN_<model>/<lang>/reports/   per-model workbook (.xlsx), design / trial / PPA CSVs, raw JSON",
        "NN_<model>/<lang>/code/      <Category>/<design>/t1..t5 generated sources,",
        "                             code_index.csv (pass/fail, code lines, which trial was synthesized)",
        "NN_<model>/logs/             generation / evaluation logs",
        "```",
        "",
        "## Models",
        "",
    ]
    for name, route, folder, files in entries:
        lines.append(f"- **{name}** (`{folder}/`): {route}; {files} generated source files")
    lines += [
        "",
        "Code lines = non-blank, non-comment-only lines. Lower is better for code lines, area (logic cells),",
        "dynamic power and critical path. Dynamic power has 1 mW resolution, so ties are common.",
        "Golden VHDL code lines are blank for the original 50 RTLLM designs (Verilog-only references).",
        "",
        "Regenerate with `venv\\Scripts\\python.exe collect_results.py`.",
        "",
    ]
    with open(os.path.join(dest, "README.md"), "w", encoding="utf-8") as file:
        file.write("\n".join(lines))


def main():
    args = parse_args()
    dest = os.path.abspath(args.dest)
    if os.path.isdir(dest):
        shutil.rmtree(dest)
    os.makedirs(dest)

    models = load_models()
    golden_report = load_json(GOLDEN_PPA) if os.path.isfile(GOLDEN_PPA) else {"results": []}
    golden = {r["design"]: r for r in golden_report["results"]}
    gold_dir = os.path.join(dest, "01_golden")
    if os.path.isfile(GOLDEN_PPA):
        copy(GOLDEN_PPA, os.path.join(gold_dir, "golden_ppa.json"))
        write_ppa_csv(os.path.join(gold_dir, "golden_ppa.csv"), golden_report["results"])

    leaderboard = build_comparison(models, golden, os.path.join(dest, "00_comparison"))

    by_name = {name: (route, folder, prefix) for name, route, folder, prefix in MODELS}
    entries = []
    for number, model in enumerate(models, 2):
        route, folder, prefix = by_name[model["name"]]
        model_dest = os.path.join(dest, f"{number:02d}_{safe_name(model['name'])}")
        files = 0
        for lang, data in model["langs"].items():
            files += collect_language(model, folder, prefix, lang, data, os.path.join(model_dest, lang))
        src_dir = os.path.join(ROOT_DIR, "outputs", folder)
        for name in os.listdir(src_dir):
            if name.endswith(".log") and os.path.getsize(os.path.join(src_dir, name)) > 0:
                copy(os.path.join(src_dir, name), os.path.join(model_dest, "logs", name))
        entries.append((model["name"], route, os.path.basename(model_dest), files))
        print(f"{model['name']}: {files} source files -> {model_dest}")

    write_readme(dest, entries, leaderboard)
    print(f"Done: {dest}")


if __name__ == "__main__":
    main()
