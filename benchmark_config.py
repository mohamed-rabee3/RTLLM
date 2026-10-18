"""Shared RTLLM benchmark manifest and design discovery helpers."""

from __future__ import annotations

import os


BENCHMARK_DESIGNS = (
    "adder_8bit", "adder_16bit", "adder_32bit", "adder_pipe_64bit", "adder_bcd", "adder",
    "adder_CLA", "adder_high_speed", "adder_low_area", "adder_low_power", "sub_64bit",
    "multi_8bit", "multi_16bit", "multi_booth_8bit", "multi_pipe_4bit", "multi_pipe_8bit",
    "multiplier", "multiplier_booth", "multiplier_high_speed", "multiplier_low_area",
    "multiplier_low_power", "div_16bit", "radix2_div", "fixed_point_divider",
    "float_point_divider", "comparator_3bit", "comparator_4bit", "accu", "fixed_point_adder",
    "fixed_point_substractor", "float_multi", "binary to BCD 16 bit", "Math_calc_32_bit",
    "sort_3_numbers", "square_root", "asyn_fifo", "LIFObuffer", "right_shifter", "LFSR",
    "barrel_shifter", "fsm", "sequence_detector", "counter_12", "JC_counter", "ring_counter",
    "up_down_counter", "signal_generator", "square_wave", "clkgenerator", "instr_reg", "ROM", "RAM",
    "alu", "pe", "freq_div", "freq_divbyeven", "freq_divbyodd", "freq_divbyfrac", "calendar",
    "traffic_light", "width_8to16", "synchronizer", "edge_detect", "pulse_detect", "parallel2serial",
    "serial2parallel", "AES-128_pipelined", "AES-128_unpipelined", "FIR_Filter",
    "haar filter 2D forward mode", "interpolation_filter", "SHA-256",
)


def discover_design_paths(root_dir: str) -> dict[str, str]:
    """Find all 72 benchmark designs below ``root_dir``."""
    wanted = set(BENCHMARK_DESIGNS)
    found: dict[str, str] = {}
    for root, _dirs, files in os.walk(root_dir):
        name = os.path.basename(root)
        if name in wanted and "design_description.txt" in files and "makefile" in files:
            found[name] = os.path.abspath(root)
    return found


def design_category(root_dir: str, design_path: str) -> str:
    """Return the top-level RTLLM category for a discovered design path."""
    relative = os.path.relpath(design_path, root_dir)
    return relative.split(os.sep, 1)[0]
