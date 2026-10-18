"""Create a polished RTLLM pass@k workbook from auto_run.py JSON output."""

from __future__ import annotations

import argparse
import json
import os
from pathlib import Path

from openpyxl import Workbook
from openpyxl.chart import LineChart, Reference
from openpyxl.comments import Comment
from openpyxl.formatting.rule import CellIsRule, ColorScaleRule, FormulaRule
from openpyxl.styles import Alignment, Border, Font, PatternFill, Side
from openpyxl.utils import get_column_letter
from openpyxl.worksheet.table import Table, TableStyleInfo


NAVY = "172554"
BLUE = "2563EB"
TEAL = "0F766E"
GREEN = "16A34A"
RED = "DC2626"
AMBER = "D97706"
SLATE = "475569"
LIGHT_BLUE = "DBEAFE"
LIGHT_GREEN = "DCFCE7"
LIGHT_RED = "FEE2E2"
LIGHT_GRAY = "F1F5F9"
MID_GRAY = "CBD5E1"
WHITE = "FFFFFF"


def parse_args():
    parser = argparse.ArgumentParser(description="Build an Excel workbook from an RTLLM JSON report.")
    parser.add_argument("json_report")
    parser.add_argument("xlsx_output")
    parser.add_argument("--ppa", action="append", default=[],
                        help="synth_metrics.py --mode model JSON. Repeatable (e.g. one per language).")
    parser.add_argument("--ppa-golden", default=None,
                        help="synth_metrics.py --mode golden JSON, used as the PPA baseline.")
    return parser.parse_args()


def count_code_lines(path, hdl=None):
    """Return (total lines, code lines) for an HDL file, or (None, None) if it is missing.

    Code lines exclude blank lines and lines holding only comments: ``//`` and
    ``/* */`` for Verilog, ``--`` (and VHDL-2008 ``/* */``) for VHDL.
    """
    if not path or not os.path.isfile(path):
        return None, None
    if hdl is None:
        hdl = "vhdl" if path.lower().endswith((".vhd", ".vhdl")) else "verilog"
    line_comment = "--" if hdl == "vhdl" else "//"
    with open(path, encoding="utf-8", errors="replace") as file:
        lines = file.read().splitlines()
    code = 0
    in_block = False
    for line in lines:
        text = line
        has_code = False
        while text:
            if in_block:
                end = text.find("*/")
                if end < 0:
                    text = ""
                    break
                text = text[end + 2:]
                in_block = False
                continue
            starts = [i for i in (text.find(line_comment), text.find("/*")) if i >= 0]
            first = min(starts) if starts else -1
            if first < 0:
                has_code = has_code or bool(text.strip())
                break
            has_code = has_code or bool(text[:first].strip())
            if text.startswith(line_comment, first):
                break
            text = text[first + 2:]
            in_block = True
        code += has_code
    return len(lines), code


def title_band(ws, title, subtitle, end_col):
    ws.merge_cells(start_row=1, start_column=1, end_row=2, end_column=end_col)
    cell = ws.cell(1, 1, title)
    cell.font = Font(name="Aptos Display", size=22, bold=True, color=WHITE)
    cell.fill = PatternFill("solid", fgColor=NAVY)
    cell.alignment = Alignment(vertical="center", horizontal="left")
    for row in ws.iter_rows(min_row=1, max_row=2, min_col=1, max_col=end_col):
        for item in row:
            item.fill = PatternFill("solid", fgColor=NAVY)
    ws.merge_cells(start_row=3, start_column=1, end_row=3, end_column=end_col)
    sub = ws.cell(3, 1, subtitle)
    sub.font = Font(name="Aptos", size=10, italic=True, color=SLATE)
    sub.alignment = Alignment(vertical="center")
    ws.row_dimensions[1].height = 26
    ws.row_dimensions[2].height = 12
    ws.row_dimensions[3].height = 22


def section_header(ws, row, start_col, end_col, text):
    ws.merge_cells(start_row=row, start_column=start_col, end_row=row, end_column=end_col)
    cell = ws.cell(row, start_col, text)
    cell.font = Font(name="Aptos", size=11, bold=True, color=WHITE)
    cell.fill = PatternFill("solid", fgColor=SLATE)
    cell.alignment = Alignment(vertical="center")
    for col in range(start_col, end_col + 1):
        ws.cell(row, col).fill = PatternFill("solid", fgColor=SLATE)
    ws.row_dimensions[row].height = 22


def style_header(row_cells):
    for cell in row_cells:
        cell.fill = PatternFill("solid", fgColor=BLUE)
        cell.font = Font(name="Aptos", size=10, bold=True, color=WHITE)
        cell.alignment = Alignment(horizontal="center", vertical="center", wrap_text=True)


def add_table(ws, ref, name):
    table = Table(displayName=name, ref=ref)
    table.tableStyleInfo = TableStyleInfo(
        name="TableStyleMedium2",
        showFirstColumn=False,
        showLastColumn=False,
        showRowStripes=True,
        showColumnStripes=False,
    )
    ws.add_table(table)


def style_kpi(ws, start_col, end_col, label, formula, fill_color):
    ws.merge_cells(start_row=5, start_column=start_col, end_row=5, end_column=end_col)
    ws.merge_cells(start_row=6, start_column=start_col, end_row=7, end_column=end_col)
    label_cell = ws.cell(5, start_col, label)
    value_cell = ws.cell(6, start_col, formula)
    for row in range(5, 8):
        for col in range(start_col, end_col + 1):
            ws.cell(row, col).fill = PatternFill("solid", fgColor=fill_color)
    label_cell.font = Font(name="Aptos", size=10, bold=True, color=WHITE)
    label_cell.alignment = Alignment(horizontal="center", vertical="center")
    value_cell.font = Font(name="Aptos Display", size=22, bold=True, color=WHITE)
    value_cell.alignment = Alignment(horizontal="center", vertical="center")
    value_cell.number_format = "0.0%"


def build_workbook(report, ppa_records=None, golden_records=None):
    wb = Workbook()
    wb.remove(wb.active)
    wb.calculation.fullCalcOnLoad = True
    wb.calculation.forceFullCalc = True
    wb.calculation.calcMode = "auto"

    dashboard = wb.create_sheet("Dashboard")
    pass_sheet = wb.create_sheet("Pass@k")
    design_sheet = wb.create_sheet("Design Results")
    trial_sheet = wb.create_sheet("Trial Results")
    calc_sheet = wb.create_sheet("Calculations")
    ppa_sheet = wb.create_sheet("PPA") if ppa_records else None
    method_sheet = wb.create_sheet("Methodology")

    for ws in wb.worksheets:
        ws.sheet_view.showGridLines = False

    manifest = report.get("generation_manifest") or {}
    model = manifest.get("model") or "Unknown"
    effort = manifest.get("reasoning_effort") or "Not recorded"
    language = report.get("language", "Unknown").upper()
    n_trials = int(report.get("n_trials") or 0)
    design_results = report.get("design_results") or []
    trial_results = report.get("trial_results") or []
    n_designs = len(design_results)

    # Design Results: source-of-truth counts with formula-derived rates/statuses.
    title_band(
        design_sheet,
        "RTLLM Design Results",
        "Per-design syntax and functional outcomes across all generated trials",
        9,
    )
    headers = [
        "Design", "Category", "Syntax Successes", "Functional Successes", "Trials",
        "Syntax Rate", "Functional Rate", "Syntax Status", "Functional Status",
    ]
    for col, header in enumerate(headers, 1):
        design_sheet.cell(5, col, header)
    style_header(design_sheet[5])
    for row_index, item in enumerate(design_results, 6):
        design_sheet.cell(row_index, 1, item.get("design"))
        design_sheet.cell(row_index, 2, item.get("category"))
        design_sheet.cell(row_index, 3, int(item.get("syntax_success") or 0))
        design_sheet.cell(row_index, 4, int(item.get("functional_success") or 0))
        design_sheet.cell(row_index, 5, int(item.get("n_trials") or n_trials))
        design_sheet.cell(row_index, 6, f'=IF(E{row_index}=0,0,C{row_index}/E{row_index})')
        design_sheet.cell(row_index, 7, f'=IF(E{row_index}=0,0,D{row_index}/E{row_index})')
        design_sheet.cell(row_index, 8, f'=IF(C{row_index}>0,"PASS","FAIL")')
        design_sheet.cell(row_index, 9, f'=IF(D{row_index}>0,"PASS","FAIL")')
    last_design_row = 5 + n_designs
    add_table(design_sheet, f"A5:I{last_design_row}", "DesignResultsTable")
    design_sheet.freeze_panes = "C6"
    design_sheet.column_dimensions["A"].width = 25
    design_sheet.column_dimensions["B"].width = 17
    for col in "CDE":
        design_sheet.column_dimensions[col].width = 18
    for col in "FG":
        design_sheet.column_dimensions[col].width = 17
        for row in range(6, last_design_row + 1):
            design_sheet[f"{col}{row}"].number_format = "0.0%"
    for col in "HI":
        design_sheet.column_dimensions[col].width = 18
    design_sheet.conditional_formatting.add(
        f"F6:G{last_design_row}",
        ColorScaleRule(start_type="num", start_value=0, start_color=LIGHT_RED,
                       mid_type="num", mid_value=0.5, mid_color="FEF3C7",
                       end_type="num", end_value=1, end_color=LIGHT_GREEN),
    )
    design_sheet.conditional_formatting.add(
        f"H6:I{last_design_row}",
        FormulaRule(formula=['H6="PASS"'], fill=PatternFill("solid", fgColor=LIGHT_GREEN),
                    font=Font(color="166534", bold=True)),
    )
    design_sheet.conditional_formatting.add(
        f"H6:I{last_design_row}",
        FormulaRule(formula=['H6="FAIL"'], fill=PatternFill("solid", fgColor=LIGHT_RED),
                    font=Font(color="991B1B", bold=True)),
    )

    # Calculation sheet: formula-driven unbiased pass@k estimator by design.
    title_band(
        calc_sheet,
        "Pass@k Calculations",
        "Formula: 1 - COMBIN(n - c, k) / COMBIN(n, k), averaged over designs",
        15,
    )
    calc_headers = ["Design", "Category", "Syntax c", "Functional c", "n"]
    calc_headers += [f"Syntax pass@{k}" for k in range(1, 6)]
    calc_headers += [f"Functional pass@{k}" for k in range(1, 6)]
    for col, header in enumerate(calc_headers, 1):
        calc_sheet.cell(5, col, header)
    style_header(calc_sheet[5])
    for row_index in range(6, last_design_row + 1):
        source_row = row_index
        calc_sheet.cell(row_index, 1, f"='Design Results'!A{source_row}")
        calc_sheet.cell(row_index, 2, f"='Design Results'!B{source_row}")
        calc_sheet.cell(row_index, 3, f"='Design Results'!C{source_row}")
        calc_sheet.cell(row_index, 4, f"='Design Results'!D{source_row}")
        calc_sheet.cell(row_index, 5, f"='Design Results'!E{source_row}")
        for k in range(1, 6):
            syntax_col = 5 + k
            func_col = 10 + k
            calc_sheet.cell(row_index, syntax_col,
                            f"=IF($E{row_index}-$C{row_index}<{k},1,"
                            f"1-COMBIN($E{row_index}-$C{row_index},{k})/COMBIN($E{row_index},{k}))")
            calc_sheet.cell(row_index, func_col,
                            f"=IF($E{row_index}-$D{row_index}<{k},1,"
                            f"1-COMBIN($E{row_index}-$D{row_index},{k})/COMBIN($E{row_index},{k}))")
            calc_sheet.cell(row_index, syntax_col).number_format = "0.0%"
            calc_sheet.cell(row_index, func_col).number_format = "0.0%"
    add_table(calc_sheet, f"A5:O{last_design_row}", "PassCalculationsTable")
    calc_sheet.freeze_panes = "F6"
    calc_sheet.column_dimensions["A"].width = 25
    calc_sheet.column_dimensions["B"].width = 17
    for col in range(3, 16):
        calc_sheet.column_dimensions[chr(64 + col)].width = 17

    # Pass@k summary. Each metric references a per-design formula column.
    title_band(pass_sheet, "RTLLM Pass@k Summary", "Syntax and functional pass probability for k = 1 through 5", 10)
    for col, header in enumerate(("k", "Syntax pass@k", "Functional pass@k"), 1):
        pass_sheet.cell(5, col, header)
    style_header(pass_sheet[5][:3])
    for k in range(1, 6):
        row = 5 + k
        syntax_letter = chr(ord("E") + k)
        func_letter = chr(ord("J") + k)
        pass_sheet.cell(row, 1, k)
        pass_sheet.cell(row, 2, f"=AVERAGE('Calculations'!{syntax_letter}$6:{syntax_letter}${last_design_row})")
        pass_sheet.cell(row, 3, f"=AVERAGE('Calculations'!{func_letter}$6:{func_letter}${last_design_row})")
        pass_sheet.cell(row, 2).number_format = "0.0%"
        pass_sheet.cell(row, 3).number_format = "0.0%"
    add_table(pass_sheet, "A5:C10", "PassAtKTable")
    pass_sheet.column_dimensions["A"].width = 10
    pass_sheet.column_dimensions["B"].width = 22
    pass_sheet.column_dimensions["C"].width = 25
    pass_sheet.freeze_panes = "A6"
    pass_sheet["B5"].comment = Comment(
        f"Average unbiased pass@k estimate over all {n_designs} designs.", "User"
    )
    pass_sheet["C5"].comment = Comment("Functional success requires the testbench's explicit 'Your Design Passed' marker.", "User")

    # Trial-level audit table.
    title_band(trial_sheet, "RTLLM Trial Audit", "Every generated candidate and its Vivado outcome", 9)
    trial_headers = ["Trial", "Design", "Category", "Syntax Pass", "Functional Pass", "Status", "Runtime (s)",
                     "Code Lines", "Total Lines"]
    for col, header in enumerate(trial_headers, 1):
        trial_sheet.cell(5, col, header)
    style_header(trial_sheet[5])
    hdl = (report.get("language") or "verilog").lower()
    generation_path = report.get("generation_path") or ""
    hdl_ext = ".vhd" if hdl == "vhdl" else ".v"
    for row_index, item in enumerate(trial_results, 6):
        total_lines, code_lines = count_code_lines(
            os.path.join(generation_path, str(item.get("trial")), f"{item.get('design')}{hdl_ext}"), hdl)
        trial_sheet.cell(row_index, 8, code_lines)
        trial_sheet.cell(row_index, 9, total_lines)
        trial_sheet.cell(row_index, 1, item.get("trial"))
        trial_sheet.cell(row_index, 2, item.get("design"))
        trial_sheet.cell(row_index, 3, item.get("category"))
        trial_sheet.cell(row_index, 4, bool(item.get("syntax_pass")))
        trial_sheet.cell(row_index, 5, bool(item.get("functional_pass")))
        trial_sheet.cell(row_index, 6, item.get("status"))
        trial_sheet.cell(row_index, 7, float(item.get("runtime_seconds") or 0))
        trial_sheet.cell(row_index, 7).number_format = "0.0"
    last_trial_row = 5 + len(trial_results)
    add_table(trial_sheet, f"A5:I{last_trial_row}", "TrialResultsTable")
    trial_sheet.column_dimensions["H"].width = 13
    trial_sheet.column_dimensions["I"].width = 13
    trial_sheet.freeze_panes = "D6"
    trial_sheet.column_dimensions["A"].width = 10
    trial_sheet.column_dimensions["B"].width = 25
    trial_sheet.column_dimensions["C"].width = 17
    trial_sheet.column_dimensions["D"].width = 15
    trial_sheet.column_dimensions["E"].width = 18
    trial_sheet.column_dimensions["F"].width = 24
    trial_sheet.column_dimensions["G"].width = 15
    trial_sheet.conditional_formatting.add(
        f"D6:E{last_trial_row}",
        CellIsRule(operator="equal", formula=["TRUE"], fill=PatternFill("solid", fgColor=LIGHT_GREEN)),
    )
    trial_sheet.conditional_formatting.add(
        f"D6:E{last_trial_row}",
        CellIsRule(operator="equal", formula=["FALSE"], fill=PatternFill("solid", fgColor=LIGHT_RED)),
    )

    # Synthesis PPA: area, power, and delay per design, against the golden RTL.
    ppa_summary = {}
    if ppa_sheet is not None:
        golden_by_design = {}
        for item in golden_records or []:
            if item.get("status") == "ok":
                golden_by_design[item.get("design")] = item

        title_band(
            ppa_sheet,
            "Synthesis PPA",
            "AMD Vivado synthesis: area, power, delay, and code lines for the best passing candidate "
            "per design, measured against the repository's golden RTL",
            28,
        )
        ppa_headers = [
            "Design", "Category", "Language", "Trial", "Synth Status",
            "Logic Cells", "LUTs", "Registers", "CARRY", "DSP", "BRAM",
            "Total Power (W)", "Dynamic Power (W)", "Critical Path (ns)", "Fmax (MHz)", "Logic Levels",
            "Golden Logic Cells", "Golden Total Power (W)", "Golden Dynamic Power (W)",
            "Golden Critical Path (ns)", "Golden Fmax (MHz)",
            "Area vs Golden", "Dyn Power vs Golden", "Delay vs Golden",
            "Code Lines", "Golden Code Lines", "Code Lines vs Golden",
        ]
        header_row = 8
        for col, header in enumerate(ppa_headers, 1):
            ppa_sheet.cell(header_row, col, header)
        style_header(ppa_sheet[header_row])

        def metric(item, *keys):
            for key in keys:
                value = (item or {}).get(key)
                if isinstance(value, (int, float)):
                    return value
            return None

        ppa_sorted = sorted(
            ppa_records,
            key=lambda item: (str(item.get("design")), str(item.get("language")), str(item.get("trial") or "")),
        )
        for offset, item in enumerate(ppa_sorted):
            row = header_row + 1 + offset
            golden = golden_by_design.get(item.get("design"))
            values = [
                item.get("design"), item.get("category"), item.get("language"), item.get("trial"),
                item.get("status"),
                metric(item, "logic_cells"), metric(item, "luts"), metric(item, "regs"),
                metric(item, "carry"), metric(item, "dsp"), metric(item, "bram"),
                metric(item, "total_power_w"), metric(item, "dynamic_power_w"),
                metric(item, "critical_path_ns", "delay_ns"), metric(item, "fmax_mhz"),
                metric(item, "logic_path_levels", "logic_levels"),
                metric(golden, "logic_cells"), metric(golden, "total_power_w"),
                metric(golden, "dynamic_power_w"),
                metric(golden, "critical_path_ns", "delay_ns"), metric(golden, "fmax_mhz"),
            ]
            for col, value in enumerate(values, 1):
                ppa_sheet.cell(row, col, value)
            ppa_sheet.cell(row, 22, f'=IFERROR(F{row}/Q{row},"")')
            ppa_sheet.cell(row, 23, f'=IFERROR(M{row}/S{row},"")')
            ppa_sheet.cell(row, 24, f'=IFERROR(N{row}/T{row},"")')
            item_hdl = (item.get("language") or "verilog").lower()
            golden_source = (golden or {}).get("source_file")
            if golden_source and item_hdl == "vhdl":
                golden_source = os.path.splitext(golden_source)[0] + ".vhd"
            ppa_sheet.cell(row, 25, count_code_lines(item.get("source_file"), item_hdl)[1])
            ppa_sheet.cell(row, 26, count_code_lines(golden_source, item_hdl)[1])
            ppa_sheet.cell(row, 27, f'=IFERROR(Y{row}/Z{row},"")')
            ppa_sheet.cell(row, 27).number_format = "0.00"
            for col in (12, 13, 18, 19):
                ppa_sheet.cell(row, col).number_format = "0.000"
            for col in (14, 20):
                ppa_sheet.cell(row, col).number_format = "0.000"
            for col in (15, 21):
                ppa_sheet.cell(row, col).number_format = "0.0"
            for col in (22, 23, 24):
                ppa_sheet.cell(row, col).number_format = "0.00"

        last_ppa_row = header_row + len(ppa_sorted)
        if ppa_sorted:
            add_table(ppa_sheet, f"A{header_row}:AA{last_ppa_row}", "PPATable")
            first_data_row = header_row + 1
            ppa_sheet.conditional_formatting.add(
                f"V{first_data_row}:X{last_ppa_row} AA{first_data_row}:AA{last_ppa_row}",
                ColorScaleRule(start_type="num", start_value=0.5, start_color=LIGHT_GREEN,
                               mid_type="num", mid_value=1, mid_color="FEF3C7",
                               end_type="num", end_value=2, end_color=LIGHT_RED),
            )
            summary_cells = [
                ("Designs synthesized", f'=COUNTIF(E{first_data_row}:E{last_ppa_row},"ok")', "0"),
                ("Median area vs golden", f'=IFERROR(MEDIAN(V{first_data_row}:V{last_ppa_row}),"")', "0.00"),
                ("Median dyn power vs golden", f'=IFERROR(MEDIAN(W{first_data_row}:W{last_ppa_row}),"")', "0.00"),
                ("Median delay vs golden", f'=IFERROR(MEDIAN(X{first_data_row}:X{last_ppa_row}),"")', "0.00"),
                ("Median Fmax (MHz)", f'=IFERROR(MEDIAN(O{first_data_row}:O{last_ppa_row}),"")', "0.0"),
                ("Total logic cells", f'=SUM(F{first_data_row}:F{last_ppa_row})', "#,##0"),
                ("Median code lines", f'=IFERROR(MEDIAN(Y{first_data_row}:Y{last_ppa_row}),"")', "0"),
            ]
            section_header(ppa_sheet, 5, 1, 28, "Summary")
            for index, (label, formula, fmt) in enumerate(summary_cells):
                col = 1 + index * 4
                ppa_sheet.merge_cells(start_row=6, start_column=col, end_row=6, end_column=col + 3)
                ppa_sheet.merge_cells(start_row=7, start_column=col, end_row=7, end_column=col + 3)
                label_cell = ppa_sheet.cell(6, col, label)
                label_cell.font = Font(name="Aptos", size=9, bold=True, color=SLATE)
                label_cell.alignment = Alignment(horizontal="center", vertical="center")
                value_cell = ppa_sheet.cell(7, col, formula)
                value_cell.font = Font(name="Aptos Display", size=14, bold=True, color=NAVY)
                value_cell.alignment = Alignment(horizontal="center", vertical="center")
                value_cell.number_format = fmt
                for span in range(col, col + 4):
                    ppa_sheet.cell(6, span).fill = PatternFill("solid", fgColor=LIGHT_GRAY)
                    ppa_sheet.cell(7, span).fill = PatternFill("solid", fgColor=LIGHT_BLUE)
            ppa_summary = {
                "first_row": first_data_row,
                "last_row": last_ppa_row,
                "n_ok": sum(1 for item in ppa_sorted if item.get("status") == "ok"),
            }
        ppa_sheet.freeze_panes = f"C{header_row + 1}"
        ppa_sheet.column_dimensions["A"].width = 25
        ppa_sheet.column_dimensions["B"].width = 16
        for index in range(3, 29):
            ppa_sheet.column_dimensions[get_column_letter(index)].width = 16
        ppa_sheet.row_dimensions[header_row].height = 34

    # Dashboard.
    title_band(
        dashboard,
        f"{model} - RTLLM Benchmark",
        f"{language} - {n_trials} independent trials - AMD Vivado XSim"
        + (f" - reasoning effort {effort}" if effort and effort != "Not recorded" else ""),
        14,
    )
    section_header(dashboard, 5, 1, 4, "Run configuration")
    metadata = [
        ("Model", model),
        ("Reasoning effort", effort),
        ("Language", language),
        ("Trials", n_trials),
        ("Designs", n_designs),
    ]
    for offset, (label, value) in enumerate(metadata, 6):
        dashboard.cell(offset, 1, label).font = Font(name="Aptos", bold=True, color=SLATE)
        dashboard.merge_cells(start_row=offset, start_column=2, end_row=offset, end_column=4)
        dashboard.cell(offset, 2, value)
        dashboard.cell(offset, 2).fill = PatternFill("solid", fgColor=LIGHT_GRAY)
    style_kpi(dashboard, 6, 8, "Functional pass@1", "='Pass@k'!C6", TEAL)
    style_kpi(dashboard, 9, 11, "Functional pass@5", "='Pass@k'!C10", GREEN)
    style_kpi(dashboard, 12, 14, "Syntax pass@5", "='Pass@k'!B10", BLUE)

    section_header(dashboard, 12, 1, 8, "Pass@k trend")
    chart = LineChart()
    chart.title = "Syntax and functional pass@k"
    chart.style = 13
    chart.height = 8.2
    chart.width = 14.5
    chart.y_axis.title = "Pass rate"
    chart.y_axis.scaling.min = 0
    chart.y_axis.scaling.max = 1
    chart.y_axis.numFmt = "0%"
    chart.x_axis.title = "k"
    data = Reference(pass_sheet, min_col=2, max_col=3, min_row=5, max_row=10)
    categories = Reference(pass_sheet, min_col=1, min_row=6, max_row=10)
    chart.add_data(data, titles_from_data=True)
    chart.set_categories(categories)
    chart.legend.position = "b"
    dashboard.add_chart(chart, "A13")

    categories_list = sorted({item.get("category", "Unknown") for item in design_results})
    section_header(dashboard, 12, 10, 14, "Category performance")
    category_headers = ["Category", "Designs", "Syntax pass@1", "Functional pass@1", "Functional pass@5"]
    for col, header in enumerate(category_headers, 10):
        dashboard.cell(13, col, header)
    style_header(dashboard[13][9:14])
    for row, category in enumerate(categories_list, 14):
        dashboard.cell(row, 10, category)
        dashboard.cell(row, 11, f'=COUNTIF(\'Calculations\'!$B$6:$B${last_design_row},J{row})')
        dashboard.cell(row, 12, f'=AVERAGEIF(\'Calculations\'!$B$6:$B${last_design_row},J{row},\'Calculations\'!$F$6:$F${last_design_row})')
        dashboard.cell(row, 13, f'=AVERAGEIF(\'Calculations\'!$B$6:$B${last_design_row},J{row},\'Calculations\'!$K$6:$K${last_design_row})')
        dashboard.cell(row, 14, f'=AVERAGEIF(\'Calculations\'!$B$6:$B${last_design_row},J{row},\'Calculations\'!$O$6:$O${last_design_row})')
        for col in range(12, 15):
            dashboard.cell(row, col).number_format = "0.0%"
    category_last_row = 13 + len(categories_list)
    add_table(dashboard, f"J13:N{category_last_row}", "CategoryPerformanceTable")
    if ppa_summary:
        section_header(dashboard, 32, 1, 8,
                       "Synthesis PPA vs golden RTL (ratio < 1.00 means smaller / lower / faster)")
        ppa_tiles = [
            ("Designs synthesized", "='PPA'!A7", "0"),
            ("Median area vs golden", "='PPA'!E7", "0.00"),
            ("Median dyn power vs golden", "='PPA'!I7", "0.00"),
            ("Median delay vs golden", "='PPA'!M7", "0.00"),
        ]
        for index, (label, formula, fmt) in enumerate(ppa_tiles):
            row = 33 + index
            dashboard.cell(row, 1, label).font = Font(name="Aptos", bold=True, color=SLATE)
            dashboard.merge_cells(start_row=row, start_column=2, end_row=row, end_column=4)
            value_cell = dashboard.cell(row, 2, formula)
            value_cell.number_format = fmt
            value_cell.fill = PatternFill("solid", fgColor=LIGHT_GRAY)
            value_cell.font = Font(name="Aptos", bold=True, color=NAVY)

    dashboard.freeze_panes = "A5"
    for col, width in {"A": 20, "B": 18, "C": 13, "D": 13, "E": 3,
                       "F": 14, "G": 14, "H": 14, "I": 3, "J": 17,
                       "K": 11, "L": 17, "M": 20, "N": 20}.items():
        dashboard.column_dimensions[col].width = width

    # Methodology and sources.
    title_band(method_sheet, "Methodology & Sources", "How this workbook was produced and how to audit it", 6)
    method_rows = [
        ("Benchmark", report.get("benchmark", "RTLLM")),
        ("Simulator", report.get("simulator", "AMD Vivado XSim")),
        ("Generation backend", manifest.get("backend", "Unknown")),
        ("Model", model),
        ("Reasoning effort", effort),
        ("Trials", n_trials),
        ("Pass@k estimator", "1 - COMBIN(n - c, k) / COMBIN(n, k), averaged across designs"),
        ("Syntax pass", "DUT and testbench compile and elaborate successfully."),
        ("Functional pass", "Simulation output contains the explicit 'Your Design Passed' marker."),
        ("Generated at", report.get("generated_at", "")),
    ]
    if ppa_records:
        sample = ppa_records[0]
        method_rows += [
            ("PPA tool", "AMD Vivado synth_design (in-context; out-of-context fallback when the pinout will not fit)"),
            ("PPA target part", sample.get("part") or "See synth_metrics report"),
            ("PPA clock period", f"{sample.get('clock_period_ns')} ns (constraints applied to the synthesized netlist)"),
            ("Area metric", "Logic Cells = LUT + FF + CARRY + MUXF + DSP + BRAM + SRL primitives; "
                            "I/O and clock buffers are excluded so the golden ratio is not distorted."),
            ("Power metric", "Vivado vectorless estimate. Total On-Chip Power is dominated by device static "
                             "power at this design scale, so Dynamic Power is the discriminating figure. "
                             "Vivado reports power at 1 mW resolution."),
            ("Delay metric", "Critical path = worst register-to-register path where one exists, otherwise the "
                             "combinational input-to-output path. Fmax = 1000 / critical path (ns)."),
            ("PPA candidate", "The first functionally-passing trial for each design; designs with no passing "
                              "candidate have no PPA row."),
            ("Code lines", "Non-blank lines that are not comment-only, counted in the synthesized source file; "
                           "the golden figure counts the repository's verified RTL in the same language "
                           "(blank for VHDL on the original 50 RTLLM designs, which ship Verilog-only goldens)."),
        ]
    section_header(method_sheet, 5, 1, 6, "Run and scoring method")
    for row, (label, value) in enumerate(method_rows, 6):
        method_sheet.cell(row, 1, label).font = Font(bold=True, color=SLATE)
        method_sheet.merge_cells(start_row=row, start_column=2, end_row=row, end_column=6)
        method_sheet.cell(row, 2, value)
        method_sheet.cell(row, 2).alignment = Alignment(wrap_text=True, vertical="top")
    source_start = 6 + len(method_rows) + 2
    section_header(method_sheet, source_start, 1, 6, "Sources")
    for row, (label, url) in enumerate((report.get("sources") or {}).items(), source_start + 1):
        method_sheet.cell(row, 1, label.replace("_", " ").title()).font = Font(bold=True, color=SLATE)
        method_sheet.merge_cells(start_row=row, start_column=2, end_row=row, end_column=6)
        method_sheet.cell(row, 2, url)
        method_sheet.cell(row, 2).font = Font(color=BLUE, underline="single")
        method_sheet.cell(row, 2).hyperlink = url
    method_sheet.column_dimensions["A"].width = 24
    for col in "BCDEF":
        method_sheet.column_dimensions[col].width = 18

    # Common finishing touches.
    thin = Side(style="thin", color=MID_GRAY)
    for ws in wb.worksheets:
        ws.sheet_properties.pageSetUpPr.fitToPage = True
        ws.page_setup.fitToWidth = 1
        ws.page_setup.fitToHeight = 0
        ws.sheet_view.zoomScale = 90
        ws.oddFooter.center.text = f"RTLLM - {model}"
        ws.oddFooter.right.text = "Page &P of &N"
    finishing = [pass_sheet, design_sheet, trial_sheet, calc_sheet]
    if ppa_sheet is not None:
        finishing.append(ppa_sheet)
    for ws in finishing:
        used = ws.calculate_dimension()
        for row in ws[used]:
            for cell in row:
                cell.alignment = Alignment(
                    horizontal=cell.alignment.horizontal,
                    vertical="center",
                    wrap_text=cell.alignment.wrap_text,
                )
        if ws is not ppa_sheet:
            ws.row_dimensions[5].height = 34

    calc_sheet.sheet_state = "hidden"
    wb.active = wb.sheetnames.index("Dashboard")
    return wb


def load_ppa(paths):
    """Flatten one or more synth_metrics.py reports into a single result list."""
    records = []
    for path in paths or []:
        if not path or not os.path.isfile(path):
            continue
        with open(path, encoding="utf-8") as file:
            payload = json.load(file)
        for item in payload.get("results") or []:
            item = dict(item)
            item.setdefault("part", payload.get("part"))
            item.setdefault("clock_period_ns", payload.get("clock_period_ns"))
            records.append(item)
    return records


def main():
    args = parse_args()
    with open(args.json_report, encoding="utf-8") as file:
        report = json.load(file)
    ppa_records = load_ppa(args.ppa)
    golden_records = load_ppa([args.ppa_golden] if args.ppa_golden else [])
    output = Path(args.xlsx_output).resolve()
    output.parent.mkdir(parents=True, exist_ok=True)
    workbook = build_workbook(report, ppa_records, golden_records)
    workbook.save(output)
    print(output)


if __name__ == "__main__":
    main()
