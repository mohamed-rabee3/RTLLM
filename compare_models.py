"""Build the cross-model RTLLM comparison workbook (Verilog and VHDL, 72-design set).

Only models that were run on the full 72-design benchmark are compared. A model is
included when its auto_run.py JSON report exists for a language; PPA columns appear
when its synth_metrics.py report exists too.
"""

from __future__ import annotations

import argparse
import json
import math
import os
from collections import defaultdict
from pathlib import Path

from openpyxl import Workbook
from openpyxl.chart import BarChart, LineChart, Reference
from openpyxl.chart.series import SeriesLabel
from openpyxl.formatting.rule import ColorScaleRule
from openpyxl.styles import Alignment, Font, PatternFill
from openpyxl.utils import get_column_letter

from benchmark_config import BENCHMARK_DESIGNS
from create_excel_report import (
    LIGHT_GRAY, LIGHT_GREEN, LIGHT_RED, SLATE, add_table, count_code_lines, section_header, style_header,
    title_band,
)


ROOT_DIR = os.path.dirname(os.path.abspath(__file__))
LANGS = ("verilog", "vhdl")
LANG_LABEL = {"verilog": "Verilog", "vhdl": "VHDL"}
KS = (1, 2, 3, 4, 5)

# (display name, access route, report dir, file prefix)
MODELS = (
    ("GPT-6 Astra (high)", "ChatGPT plan via ChatMock, reasoning effort high", "gpt6_astra_high", "gpt6_astra_high"),
    ("GPT-5.6 Sol (high)", "ChatGPT plan via ChatMock, reasoning effort high", "gpt56_sol_high", "gpt56_sol_high"),
    ("GLM-5.3 Flash", "opencode Go API, temperature 0.2", "glm53_flash", "glm53_flash"),
    ("DeepSeek-V4.1 Flash", "opencode Go API, temperature 0.2", "deepseek41_flash", "deepseek41_flash"),
)
GOLDEN_PPA = os.path.join(ROOT_DIR, "outputs", "glm53_flash", "golden_ppa.json")


def parse_args():
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--out", default=os.path.join(ROOT_DIR, "outputs", "RTLLM_Model_Comparison_all72.xlsx"))
    return parser.parse_args()


def pass_at_k(c, n, k):
    if k > n:
        return None
    return 1 - math.comb(n - c, k) / math.comb(n, k)


def load_json(path):
    with open(path, encoding="utf-8") as file:
        return json.load(file)


def load_models():
    """Return [{name, route, lang: {report, designs, ppa}}] for models with 72-design reports."""
    models = []
    for name, route, folder, prefix in MODELS:
        entry = {"name": name, "route": route, "langs": {}}
        for lang in LANGS:
            report_path = os.path.join(ROOT_DIR, "outputs", folder, f"{prefix}_{lang}_all72_benchmark_results.json")
            if not os.path.isfile(report_path):
                continue
            report = load_json(report_path)
            if report.get("n_designs") != len(BENCHMARK_DESIGNS):
                continue
            designs = {item["design"]: item for item in report["design_results"]}
            ppa_path = os.path.join(ROOT_DIR, "outputs", folder, f"{prefix}_{lang}_ppa.json")
            ppa = load_json(ppa_path)["results"] if os.path.isfile(ppa_path) else None
            entry["langs"][lang] = {"report": report, "designs": designs, "ppa": ppa}
        if entry["langs"]:
            models.append(entry)
        else:
            print(f"skip {name}: no 72-design report yet")
    return models


def metrics(lang_data):
    n = lang_data["report"]["n_trials"]
    designs = lang_data["designs"].values()
    out = {"n": n}
    for kind, key in (("syntax", "syntax_success"), ("func", "functional_success")):
        for k in KS:
            scores = [pass_at_k(d[key], n, k) for d in designs]
            out[f"{kind}@{k}"] = None if None in scores else sum(scores) / len(scores)
    out["solved"] = sum(1 for d in designs if d["functional_success"] > 0)
    out["solved_all"] = sum(1 for d in designs if d["functional_success"] == n)
    out["syntax_ok"] = sum(1 for d in designs if d["syntax_success"] > 0)
    return out


def ppa_ratios(records, golden):
    """Geometric-mean model/golden ratios over designs synthesized OK on both sides."""
    if not records:
        return None
    ratios = {"logic_cells": [], "dynamic_power_w": [], "critical_path_ns": []}
    ok = 0
    for item in records:
        if item.get("status") != "ok":
            continue
        ok += 1
        gold = golden.get(item["design"])
        if not gold or gold.get("status") != "ok":
            continue
        for key in ratios:
            model_value, gold_value = item.get(key), gold.get(key)
            if isinstance(model_value, (int, float)) and isinstance(gold_value, (int, float)) \
                    and model_value > 0 and gold_value > 0:
                ratios[key].append(model_value / gold_value)
    geo = {key: (math.exp(sum(map(math.log, vals)) / len(vals)) if vals else None) for key, vals in ratios.items()}
    fmax = [i["fmax_mhz"] for i in records if i.get("status") == "ok" and isinstance(i.get("fmax_mhz"), (int, float))]
    return {"synth_ok": ok, "targets": len(records), "area": geo["logic_cells"],
            "power": geo["dynamic_power_w"], "delay": geo["critical_path_ns"],
            "fmax_median": sorted(fmax)[len(fmax) // 2] if fmax else None}


def write_row(ws, row, values, formats=None):
    for col, value in enumerate(values, 1):
        cell = ws.cell(row, col, value)
        if formats and col in formats and value is not None:
            cell.number_format = formats[col]


def pct_scale(ws, ref):
    ws.conditional_formatting.add(ref, ColorScaleRule(
        start_type="num", start_value=0, start_color=LIGHT_RED,
        mid_type="num", mid_value=0.5, mid_color="FEF3C7",
        end_type="num", end_value=1, end_color=LIGHT_GREEN))


def build_summary(wb, models):
    ws = wb.create_sheet("Summary")
    headers = ["Model", "Language", "Trials", "Syntax pass@1", "Func pass@1", "Func pass@3", "Func pass@5",
               "Designs solved (any trial)", "Designs solved (all trials)", "Designs compiling (any trial)"]
    title_band(ws, "RTLLM 72-Design Benchmark: Model Comparison",
               "Vivado XSim functional verification, unbiased pass@k over 72 designs per language", len(headers))
    row = 5
    section_header(ws, row, 1, len(headers), "Leaderboard (sorted by functional pass@1 within each language)")
    row += 1
    for col, header in enumerate(headers, 1):
        ws.cell(row, col, header)
    style_header(ws[row])
    header_row = row
    for lang in LANGS:
        ranked = sorted((m for m in models if lang in m["langs"]),
                        key=lambda m: -metrics(m["langs"][lang])["func@1"])
        for model in ranked:
            row += 1
            m = metrics(model["langs"][lang])
            write_row(ws, row, [model["name"], LANG_LABEL[lang], m["n"], m["syntax@1"], m["func@1"],
                                m["func@3"], m["func@5"], m["solved"], m["solved_all"], m["syntax_ok"]],
                      {4: "0.0%", 5: "0.0%", 6: "0.0%", 7: "0.0%"})
    add_table(ws, f"A{header_row}:{get_column_letter(len(headers))}{row}", "Leaderboard")
    pct_scale(ws, f"D{header_row + 1}:G{row}")

    # Verilog vs VHDL side by side, feeding the chart.
    row += 2
    section_header(ws, row, 1, len(headers), "Verilog vs VHDL: functional pass@1")
    row += 1
    for col, header in enumerate(["Model", "Verilog", "VHDL", "VHDL - Verilog"], 1):
        ws.cell(row, col, header)
    style_header([ws.cell(row, c) for c in range(1, 5)])
    side_header = row
    for model in models:
        row += 1
        v = metrics(model["langs"]["verilog"])["func@1"] if "verilog" in model["langs"] else None
        h = metrics(model["langs"]["vhdl"])["func@1"] if "vhdl" in model["langs"] else None
        write_row(ws, row, [model["name"], v, h, (h - v) if v is not None and h is not None else None],
                  {2: "0.0%", 3: "0.0%", 4: "+0.0%;-0.0%;0.0%"})
    add_table(ws, f"A{side_header}:D{row}", "LangGap")

    chart = BarChart()
    chart.type = "col"
    chart.title = "Functional pass@1 by model"
    chart.y_axis.title = "pass@1"
    chart.y_axis.scaling.min = 0
    chart.y_axis.scaling.max = 1
    chart.y_axis.numFmt = "0%"
    chart.add_data(Reference(ws, min_col=2, max_col=3, min_row=side_header, max_row=row), titles_from_data=True)
    chart.set_categories(Reference(ws, min_col=1, min_row=side_header + 1, max_row=row))
    chart.x_axis.delete = chart.y_axis.delete = False  # openpyxl 3.1 hides axes by default
    chart.height, chart.width = 8, 16
    ws.add_chart(chart, f"F{side_header}")

    ws.column_dimensions["A"].width = 24
    for col in range(2, len(headers) + 1):
        ws.column_dimensions[get_column_letter(col)].width = 15
    ws.freeze_panes = ws.cell(header_row + 1, 2)


def build_pass_at_k(wb, models):
    ws = wb.create_sheet("Pass@k")
    headers = ["Model", "Language"] + [f"Syntax pass@{k}" for k in KS] + [f"Func pass@{k}" for k in KS]
    title_band(ws, "pass@k curves", "Unbiased estimator 1 - C(n-c,k)/C(n,k), averaged over 72 designs", len(headers))
    row = 5
    for col, header in enumerate(headers, 1):
        ws.cell(row, col, header)
    style_header(ws[row])
    header_row = row
    for lang in LANGS:
        for model in models:
            if lang not in model["langs"]:
                continue
            row += 1
            m = metrics(model["langs"][lang])
            values = [model["name"], LANG_LABEL[lang]] + [m[f"syntax@{k}"] for k in KS] + [m[f"func@{k}"] for k in KS]
            write_row(ws, row, values, {c: "0.0%" for c in range(3, 13)})
    add_table(ws, f"A{header_row}:L{row}", "PassAtK")
    pct_scale(ws, f"C{header_row + 1}:L{row}")

    # One line chart per language: functional pass@k per model.
    chart_row = row + 2
    for index, lang in enumerate(LANGS):
        rows = [r for r in range(header_row + 1, row + 1) if ws.cell(r, 2).value == LANG_LABEL[lang]]
        if not rows:
            continue
        chart = LineChart()
        chart.title = f"{LANG_LABEL[lang]}: functional pass@k"
        chart.y_axis.numFmt = "0%"
        chart.y_axis.scaling.min = 0
        chart.y_axis.scaling.max = 1
        for r in rows:
            series_ref = Reference(ws, min_col=8, max_col=12, min_row=r)
            chart.add_data(series_ref, from_rows=True, titles_from_data=False)
            chart.series[-1].title = SeriesLabel(v=ws.cell(r, 1).value)
        chart.set_categories(Reference(ws, min_col=8, max_col=12, min_row=header_row))
        chart.x_axis.title = "k"
        chart.x_axis.delete = chart.y_axis.delete = False
        chart.height, chart.width = 8, 14
        ws.add_chart(chart, f"{'A' if index == 0 else 'H'}{chart_row}")

    ws.column_dimensions["A"].width = 24
    for col in range(2, 13):
        ws.column_dimensions[get_column_letter(col)].width = 13


def build_design_sheet(wb, models, lang):
    ws = wb.create_sheet(f"{LANG_LABEL[lang]} Designs")
    present = [m for m in models if lang in m["langs"]]
    headers = ["Design", "Category"] + [f"{m['name']} func" for m in present] + [f"{m['name']} syntax" for m in present]
    title_band(ws, f"{LANG_LABEL[lang]}: per-design pass rate",
               "Fraction of trials passing (functional = testbench passed; syntax = compiled/elaborated)",
               max(len(headers), 4))
    row = 5
    for col, header in enumerate(headers, 1):
        ws.cell(row, col, header)
    style_header(ws[row])
    header_row = row
    for design in BENCHMARK_DESIGNS:
        row += 1
        category = next((m["langs"][lang]["designs"][design].get("category") for m in present), "")
        values = [design, category]
        values += [m["langs"][lang]["designs"][design]["functional_success"] / m["langs"][lang]["report"]["n_trials"]
                   for m in present]
        values += [m["langs"][lang]["designs"][design]["syntax_success"] / m["langs"][lang]["report"]["n_trials"]
                   for m in present]
        write_row(ws, row, values, {c: "0%" for c in range(3, len(headers) + 1)})
    last_col = get_column_letter(len(headers))
    add_table(ws, f"A{header_row}:{last_col}{row}", f"Designs{LANG_LABEL[lang]}")
    pct_scale(ws, f"C{header_row + 1}:{last_col}{row}")
    ws.freeze_panes = ws.cell(header_row + 1, 3)
    ws.column_dimensions["A"].width = 28
    ws.column_dimensions["B"].width = 15
    for col in range(3, len(headers) + 1):
        ws.column_dimensions[get_column_letter(col)].width = 15


def build_categories(wb, models):
    ws = wb.create_sheet("Categories")
    categories = sorted({d.get("category", "") for m in models for l in m["langs"].values() for d in l["designs"].values()})
    headers = ["Model", "Language"] + [f"{c} func pass@1" for c in categories]
    title_band(ws, "Functional pass@1 by design category", "Category = top-level RTLLM folder", len(headers))
    row = 5
    for col, header in enumerate(headers, 1):
        ws.cell(row, col, header)
    style_header(ws[row])
    header_row = row
    for lang in LANGS:
        for model in models:
            if lang not in model["langs"]:
                continue
            row += 1
            data = model["langs"][lang]
            n = data["report"]["n_trials"]
            values = [model["name"], LANG_LABEL[lang]]
            for category in categories:
                items = [d for d in data["designs"].values() if d.get("category") == category]
                values.append(sum(d["functional_success"] / n for d in items) / len(items) if items else None)
            write_row(ws, row, values, {c: "0.0%" for c in range(3, len(headers) + 1)})
    last_col = get_column_letter(len(headers))
    add_table(ws, f"A{header_row}:{last_col}{row}", "Categories")
    pct_scale(ws, f"C{header_row + 1}:{last_col}{row}")
    ws.column_dimensions["A"].width = 24
    for col in range(2, len(headers) + 1):
        ws.column_dimensions[get_column_letter(col)].width = 17


def build_ppa(wb, models):
    if not os.path.isfile(GOLDEN_PPA):
        return
    golden = {r["design"]: r for r in load_json(GOLDEN_PPA)["results"]}
    ws = wb.create_sheet("PPA")
    headers = ["Model", "Language", "Designs synthesized", "Synthesis targets",
               "Area vs golden (geomean)", "Dynamic power vs golden (geomean)",
               "Critical path vs golden (geomean)", "Median Fmax (MHz)"]
    title_band(ws, "Synthesis PPA vs golden RTL",
               "Vivado synth, Spartan-7 xc7s100fgga676-2, 10 ns clock, 25% toggle; best passing trial per design. "
               "Ratio < 1 = better than golden", len(headers))
    row = 5
    for col, header in enumerate(headers, 1):
        ws.cell(row, col, header)
    style_header(ws[row])
    header_row = row
    for lang in LANGS:
        for model in models:
            data = model["langs"].get(lang)
            ratios = ppa_ratios(data["ppa"], golden) if data else None
            if not ratios:
                continue
            row += 1
            write_row(ws, row, [model["name"], LANG_LABEL[lang], ratios["synth_ok"], ratios["targets"],
                                ratios["area"], ratios["power"], ratios["delay"], ratios["fmax_median"]],
                      {5: "0.00", 6: "0.00", 7: "0.00", 8: "0.0"})
    if row == header_row:
        ws.cell(row + 1, 1, "No PPA reports available yet.")
        return
    add_table(ws, f"A{header_row}:H{row}", "PPA")
    ws.conditional_formatting.add(f"E{header_row + 1}:G{row}", ColorScaleRule(
        start_type="num", start_value=0.5, start_color=LIGHT_GREEN,
        mid_type="num", mid_value=1, mid_color="FEF3C7",
        end_type="num", end_value=2, end_color=LIGHT_RED))
    ws.column_dimensions["A"].width = 24
    for col in range(2, len(headers) + 1):
        ws.column_dimensions[get_column_letter(col)].width = 18


HDL_EXT = {"verilog": ".v", "vhdl": ".vhd"}
# (label, key, number format) for the per-design winner columns; lower is better for all.
BEST_METRICS = (
    ("Fewest code lines", "code_lines", "0"),
    ("Smallest area", "logic_cells", "#,##0"),
    ("Lowest dynamic power", "dynamic_power_w", "0.000"),
    ("Shortest critical path", "critical_path_ns", "0.000"),
)
BEST_VALUE_HEADERS = ("Code lines", "Logic cells", "Dynamic power (W)", "Critical path (ns)")


def short_name(model):
    return model["name"].split(" (")[0]


def candidate_metrics(model, lang, design):
    """Code lines and PPA of the passing candidate that was synthesized, or None if unsolved."""
    data = model["langs"].get(lang)
    if not data or data["designs"][design]["functional_success"] == 0:
        return None
    record = next((r for r in data["ppa"] or [] if r.get("design") == design), None) or {}
    source = record.get("source_file")
    trial = record.get("trial")
    if not source or not os.path.isfile(source):
        # No PPA record: fall back to the first functionally passing trial.
        report = data["report"]
        trial = next((t["trial"] for t in report["trial_results"]
                      if t["design"] == design and t.get("functional_pass")), None)
        source = os.path.join(report["generation_path"], str(trial), design + HDL_EXT[lang])
    synth_ok = record.get("status") == "ok"
    out = {"trial": trial, "code_lines": count_code_lines(source, lang)[1]}
    for _label, key, _fmt in BEST_METRICS[1:]:
        value = record.get(key) if synth_ok else None
        out[key] = value if isinstance(value, (int, float)) else None
    return out


def winners(candidates, key):
    """Names tied for the lowest value of ``key``, and that value."""
    scored = {name: c[key] for name, c in candidates.items() if c.get(key) is not None}
    if not scored:
        return [], None
    best = min(scored.values())
    return [n for n, v in scored.items() if math.isclose(v, best, rel_tol=1e-9, abs_tol=1e-12)], best


def overall_winners(candidates):
    """Lowest sum of competition ranks across all four metrics (models with every metric)."""
    keys = [key for _label, key, _fmt in BEST_METRICS]
    complete = {n: c for n, c in candidates.items() if all(c.get(k) is not None for k in keys)}
    if not complete:
        return []
    rank_sum = {
        name: sum(1 + sum(1 for other in complete.values() if other[k] < cand[k] - 1e-12) for k in keys)
        for name, cand in complete.items()
    }
    best = min(rank_sum.values())
    return [name for name, total in rank_sum.items() if total == best]


def golden_metrics(golden, design, lang):
    record = golden.get(design) or {}
    source = record.get("source_file")
    if source and lang == "vhdl":
        source = os.path.splitext(source)[0] + ".vhd"
    ok = record.get("status") == "ok"
    return [count_code_lines(source, lang)[1]] + [record.get(k) if ok else None for _l, k, _f in BEST_METRICS[1:]]


def winner_label(names, candidates):
    if not names:
        return None
    if len(names) > 1 and len(names) == len(candidates):
        return "All tied"
    return ", ".join(names)


def build_best_per_design(wb, models, golden, lang, tally):
    present = [m for m in models if lang in m["langs"]]
    ws = wb.create_sheet(f"Best per Design - {LANG_LABEL[lang]}")
    headers = ["Design", "Category", "Models solved", "Solved by"]
    for (label, _key, _fmt), value_header in zip(BEST_METRICS, BEST_VALUE_HEADERS):
        headers += [label, value_header]
    headers += ["Overall best (rank sum)", "Golden code lines", "Golden logic cells",
                "Golden dynamic power (W)", "Golden critical path (ns)"]
    title_band(ws, f"{LANG_LABEL[lang]}: best model per design",
               "Among models whose code passed the testbench; lower is better for every metric; ties list "
               "every tied model, \"All tied\" when every solving model is equal", len(headers))
    row = 5
    for col, header in enumerate(headers, 1):
        ws.cell(row, col, header)
    style_header(ws[row])
    ws.row_dimensions[row].height = 34
    header_row = row
    unsolved_rows = []
    for design in BENCHMARK_DESIGNS:
        row += 1
        candidates = {}
        for model in present:
            cand = candidate_metrics(model, lang, design)
            if cand:
                candidates[short_name(model)] = cand
        category = present[0]["langs"][lang]["designs"][design].get("category")
        values = [design, category, len(candidates), ", ".join(candidates) or "None"]
        formats = {}
        for index, (_label, key, fmt) in enumerate(BEST_METRICS):
            names, value = winners(candidates, key)
            values += [winner_label(names, candidates), value]
            formats[6 + index * 2] = fmt
            for name in names:
                tally[(lang, name)][key] += 1
        overall = overall_winners(candidates)
        for name in overall:
            tally[(lang, name)]["overall"] += 1
        for name in candidates:
            tally[(lang, name)]["solved"] += 1
        values.append(winner_label(overall, candidates))
        values += golden_metrics(golden, design, lang)
        formats.update({14: "0", 15: "#,##0", 16: "0.000", 17: "0.000"})
        write_row(ws, row, values, formats)
        if not candidates:
            unsolved_rows.append(row)
    last_col = get_column_letter(len(headers))
    add_table(ws, f"A{header_row}:{last_col}{row}", f"Best{LANG_LABEL[lang]}")
    for unsolved in unsolved_rows:
        for col in range(1, len(headers) + 1):
            ws.cell(unsolved, col).fill = PatternFill("solid", fgColor=LIGHT_RED)
    winner_cols = (5, 7, 9, 11, 13)
    for r in range(header_row + 1, row + 1):
        for col in (4,) + winner_cols:
            ws.cell(r, col).alignment = Alignment(wrap_text=True, vertical="center")
        for col in winner_cols:
            ws.cell(r, col).font = Font(name="Aptos", bold=True, color="166534")
    ws.freeze_panes = ws.cell(header_row + 1, 2)
    ws.column_dimensions["A"].width = 28
    ws.column_dimensions["B"].width = 15
    ws.column_dimensions["C"].width = 10
    ws.column_dimensions["D"].width = 46
    for col in range(5, len(headers) + 1):
        ws.column_dimensions[get_column_letter(col)].width = 24 if col in winner_cols else 13


def build_wins(wb, models, tally):
    ws = wb.create_sheet("Best-Model Wins")
    headers = ["Model", "Language", "Designs solved", "Fewest code lines", "Smallest area",
               "Lowest dynamic power", "Shortest critical path", "Overall best"]
    title_band(ws, "Best-model wins per design",
               "Number of designs where each model is best (ties count for every tied model)", len(headers))
    row = 5
    for col, header in enumerate(headers, 1):
        ws.cell(row, col, header)
    style_header(ws[row])
    header_row = row
    for lang in LANGS:
        for model in models:
            if lang not in model["langs"]:
                continue
            row += 1
            t = tally[(lang, short_name(model))]
            write_row(ws, row, [model["name"], LANG_LABEL[lang], t["solved"]]
                      + [t[key] for _l, key, _f in BEST_METRICS] + [t["overall"]])
    add_table(ws, f"A{header_row}:H{row}", "BestWins")
    ws.conditional_formatting.add(f"D{header_row + 1}:H{row}", ColorScaleRule(
        start_type="min", start_color="FFFFFF", end_type="max", end_color=LIGHT_GREEN))
    ws.column_dimensions["A"].width = 24
    for col in range(2, len(headers) + 1):
        ws.column_dimensions[get_column_letter(col)].width = 17


def build_code_metrics(wb, models, golden):
    ws = wb.create_sheet("Code Metrics")
    headers = ["Language", "Design", "Category", "Model", "Passed", "Trial", "Code lines", "Logic cells",
               "Dynamic power (W)", "Critical path (ns)", "Golden code lines", "Golden logic cells",
               "Golden dynamic power (W)", "Golden critical path (ns)"]
    title_band(ws, "Code size and PPA per model and design",
               "Synthesized passing candidate per model; filter by language, design, or model", len(headers))
    row = 5
    for col, header in enumerate(headers, 1):
        ws.cell(row, col, header)
    style_header(ws[row])
    header_row = row
    for lang in LANGS:
        for design in BENCHMARK_DESIGNS:
            gold = golden_metrics(golden, design, lang)
            for model in models:
                if lang not in model["langs"]:
                    continue
                row += 1
                cand = candidate_metrics(model, lang, design)
                category = model["langs"][lang]["designs"][design].get("category")
                values = [LANG_LABEL[lang], design, category, model["name"], "PASS" if cand else "FAIL"]
                if cand:
                    values += [cand["trial"], cand["code_lines"]] + [cand[k] for _l, k, _f in BEST_METRICS[1:]]
                else:
                    values += [None] * 5
                write_row(ws, row, values + gold,
                          {8: "#,##0", 9: "0.000", 10: "0.000", 12: "#,##0", 13: "0.000", 14: "0.000"})
                ws.cell(row, 5).fill = PatternFill("solid", fgColor=LIGHT_GREEN if cand else LIGHT_RED)
    add_table(ws, f"A{header_row}:N{row}", "CodeMetrics")
    ws.freeze_panes = ws.cell(header_row + 1, 3)
    ws.column_dimensions["A"].width = 10
    ws.column_dimensions["B"].width = 28
    ws.column_dimensions["C"].width = 15
    ws.column_dimensions["D"].width = 22
    for col in range(5, len(headers) + 1):
        ws.column_dimensions[get_column_letter(col)].width = 14


def build_notes(wb, models):
    ws = wb.create_sheet("Methodology")
    title_band(ws, "Methodology", "How these numbers were produced", 2)
    lines = [
        ("Benchmark", "RTLLM 2.0 (50 designs) + 22 added designs = 72 designs, each with Verilog and VHDL goldens."),
        ("Scope", "Only models evaluated on all 72 designs in both languages are compared."),
        ("Prompt", "Same design_description.txt per design; for VHDL the word 'Verilog' is replaced by 'VHDL'."),
        ("Simulator", "AMD Vivado XSim 2025.2; the Verilog testbench drives VHDL DUTs via mixed-language elaboration."),
        ("Pass criteria", "Syntax = compiles and elaborates; functional = testbench prints its pass message."),
        ("pass@k", "Unbiased estimator 1 - C(n-c,k)/C(n,k) per design, averaged over 72 designs; n = 5 trials."),
        ("PPA", "Vivado synthesis of the first passing trial per design vs the verified golden RTL."),
        ("Code lines", "Non-blank, non-comment-only lines of that same synthesized passing file."),
        ("Best per design", "Among models that passed the design: lowest code lines, logic cells, dynamic "
                            "power, and critical path; ties list every tied model. Overall best = lowest sum "
                            "of ranks across the four metrics. Dynamic power has 1 mW resolution, so ties "
                            "are common."),
    ]
    for model in models:
        manifest = next(iter(model["langs"].values()))["report"].get("generation_manifest") or {}
        lines.append((model["name"], f"{model['route']}; model id {manifest.get('model', '?')}."))
    for offset, (label, text) in enumerate(lines):
        row = 5 + offset
        ws.cell(row, 1, label).font = Font(name="Aptos", bold=True, color=SLATE)
        ws.cell(row, 2, text).alignment = Alignment(wrap_text=True, vertical="top")
        ws.cell(row, 1).fill = PatternFill("solid", fgColor=LIGHT_GRAY)
    ws.column_dimensions["A"].width = 22
    ws.column_dimensions["B"].width = 110


def main():
    args = parse_args()
    models = load_models()
    if not models:
        raise SystemExit("No 72-design reports found.")
    wb = Workbook()
    wb.remove(wb.active)
    build_summary(wb, models)
    build_pass_at_k(wb, models)
    for lang in LANGS:
        if any(lang in m["langs"] for m in models):
            build_design_sheet(wb, models, lang)
    build_categories(wb, models)
    build_ppa(wb, models)
    golden = {r["design"]: r for r in load_json(GOLDEN_PPA)["results"]} if os.path.isfile(GOLDEN_PPA) else {}
    tally = defaultdict(lambda: defaultdict(int))
    for lang in LANGS:
        if any(lang in m["langs"] for m in models):
            build_best_per_design(wb, models, golden, lang, tally)
    build_wins(wb, models, tally)
    build_code_metrics(wb, models, golden)
    build_notes(wb, models)
    output = Path(args.out).resolve()
    output.parent.mkdir(parents=True, exist_ok=True)
    wb.save(output)
    print(f"Compared {len(models)} models: {', '.join(m['name'] for m in models)}")
    print(output)


if __name__ == "__main__":
    main()
