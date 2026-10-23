"""All settings for the open-model generation run. Edit MODEL_IDS / LANGS here.

Paths (override with environment variables):
  RTLLM_RESULTS_DIR     where Generated_RTL/ and results_all_models.json are written
  RTLLM_BENCHMARKS_DIR  folder with one sub-folder per task (each containing prompt*.txt)
"""
import os
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[1]

# ── what to run ───────────────────────────────────────────────
# Models run sequentially; a model that fails to load is skipped and listed at the end.
MODEL_IDS = [
    "Qwen/Qwen2.5-Coder-7B-Instruct",
    "Qwen/Qwen2.5-Coder-7B",                      # base twin of the line above
    "Qwen/Qwen2.5-Coder-3B-Instruct",
    "Qwen/Qwen2.5-Coder-14B-Instruct",
    "deepseek-ai/deepseek-coder-1.3b-instruct",
    "codellama/CodeLlama-7b-Instruct-hf",
    "ibm-granite/granite-8b-code-instruct-4k",
    "Qwen/Qwen3-8B",
    "bigcode/starcoder2-7b",
]
# Earlier runs: ishorn5/RTLCoder-v1.1 · deepseek-ai/deepseek-coder-6.7b-instruct
# Verify every ID before a long run: a wrong or gated ID is simply skipped.

# Prompted by completing a partial file instead of the chat template.
BASE_MODELS = {"bigcode/starcoder2-7b", "Qwen/Qwen2.5-Coder-7B"}

LANGS          = ["v", "sv", "vhd"]   # v = Verilog-2001 · sv = SystemVerilog · vhd = VHDL-2008
TEMPERATURE    = 0.1
MAX_NEW_TOKENS = 4096                 # AES / SHA-256 need far more than 1024
MAX_NEW_TOKENS_FOR = {"ibm-granite/granite-8b-code-instruct-4k": 3000}   # 4k context: prompt + output must fit
RESUME         = True                 # skip (model, task, lang) already in results_all_models.json
SAVE_RAW       = True                 # keep raw_<lang>.txt (untouched model output) next to each design
ZIP_RAW        = False                # include raw_<lang>.txt in Generated_RTL.zip

# ── where things live ─────────────────────────────────────────
ON_KAGGLE = os.path.exists("/kaggle/working")
ON_COLAB  = os.path.exists("/content/drive")

if ON_KAGGLE:
    _results    = Path("/kaggle/working")
    _benchmarks = Path("/kaggle/input/datasets/fakeacc0unt/rtl-data/Benchmarks_Final")
elif ON_COLAB:
    _results    = Path("/content/drive/MyDrive")
    _benchmarks = _results / "Benchmarks_Final"
else:                                                    # local machine
    _results    = REPO_ROOT / "results" / "open_models"
    _benchmarks = REPO_ROOT / "benchmarks"               # TODO: point at the repo's benchmark folder

WORK_DIR       = Path(os.environ.get("RTLLM_RESULTS_DIR", _results))
BENCHMARKS_DIR = Path(os.environ.get("RTLLM_BENCHMARKS_DIR", _benchmarks))
OUTPUT_DIR     = WORK_DIR / "Generated_RTL"
RESULTS_JSON   = WORK_DIR / "results_all_models.json"

# Kaggle's disk is small, so delete each model's download after use. Never on a local machine.
DROP_HF_CACHE = ON_KAGGLE