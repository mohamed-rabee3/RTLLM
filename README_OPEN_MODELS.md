# Open-model RTL benchmark (generation → Vivado synthesis)

Measures how well open-weight code LLMs write **synthesizable RTL** (Verilog-2001 `v`, SystemVerilog `sv`,
VHDL-2008 `vhd`) for every benchmark task, then synthesizes each design in Vivado
(part `xc7s50csga324-1`, 10 ns clock). Closed-model runs live on their own branch with the same result format.

```
llm_gen/    1. generate + validate RTL with Hugging Face models   (Python, GPU)
vivado/     2. synthesize it, 3. merge the metrics                 (Vivado, Python)
results/open_models/    everything the two steps produce
```

## Run

**1 · Generate** (GPU, 4-bit, fits a T4). Edit `llm_gen/config.py` (models, languages, benchmark folder), then:
```bash
cd llm_gen
pip install -r requirements.txt
python run_benchmark.py                                   # or: --models Qwen/Qwen3-8B --langs v sv
```
in `config.py` or the env var `RTLLM_BENCHMARKS_DIR`. A restarted run resumes where it stopped (`--no-resume` to redo).
Output: `results/open_models/Generated_RTL/<model>/<task>/<top>.<ext>` and `results_all_models.json`.

**2 · Synthesize** (machine with Vivado):
```bash
cd results/open_models
vivado -mode batch -source ../../vivado/run_vivado_all_models.tcl -log vivado_all.log
```
Settings (part, clock, `RUN_IMPL`, `ONLY_MODELS`, `ONLY_FAILED_FROM`) are at the top of the TCL file.

**3 · Merge**
```bash
python ../../vivado/merge_vivado_results.py results_all_models.json vivado_metrics.jsonl vivado_all.log
```
Prints a per-model table (tasks / valid RTL / synthesized) and the most common Vivado error codes.

## Read the results

`results/open_models/results_all_models_merged.json` — one row per **(model, task_id, lang)**:

| Field | Meaning |
|---|---|
| `valid_rtl`, `reject_reason` | passed the notebook's checks (right module names, no testbench/simulation constructs) |
| `success` | Vivado synthesized it |
| `area` / `ff` / `dsp` / `bram` | LUTs / flip-flops / DSP blocks / BRAM tiles |
| `power`, `power_dynamic`, `power_static` | W |
| `wns`, `delay` | worst slack and critical-path estimate (`period − WNS`) in ns |
| `clock`, `stage` | clock port used (or `virtual`), `synth` or `impl` |
| `error` | Vivado error text for failed designs |

Per-design Vivado reports (utilization, timing, power) are in `results/open_models/vivado_work/<model>/<task>/<lang>/`.

## Caveats
- Synthesis success ≠ functional correctness (the tasks ship testbenches, so a simulation pass is the next step).
- One sample per task: a difference of one or two tasks is not significant.
- Verify every model ID in `config.py` before a long run; wrong or gated IDs are skipped and listed at the end.