import argparse
import os
import re
import time
from openai import OpenAI, APITimeoutError, APIError
from tqdm import tqdm

# --- Language selection (--lang verilog|vhdl) ---
LANG_CONFIG = {
    "verilog": {"ext": ".v", "label": "Verilog", "fence": "verilog", "out_dir": "openrouter_deepseek_v4_pro"},
    "vhdl": {"ext": ".vhd", "label": "VHDL", "fence": "vhdl", "out_dir": "openrouter_deepseek_v4_pro_vhdl"},
}

parser = argparse.ArgumentParser(description="Generate RTL for the RTLLM benchmark via OpenRouter.")
parser.add_argument("--lang", choices=LANG_CONFIG.keys(), default="verilog",
                    help="Target HDL for generation (default: verilog).")
parser.add_argument("--only", default=None,
                    help="Generate just this single design (by name), for smoke-testing.")
args = parser.parse_args()
LANG = LANG_CONFIG[args.lang]


def load_env_file(env_path=None):
    """Load KEY=VALUE pairs from .env into os.environ (does not override existing vars)."""
    if env_path is None:
        env_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), ".env")
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


load_env_file()

# --- OpenRouter API Configuration ---
API_KEY = os.environ.get("OPENROUTER_API_KEY", "")
if not API_KEY:
    raise SystemExit("Error: OPENROUTER_API_KEY not set (put it in .env).")
BASE_URL = "https://openrouter.ai/api/v1"
MODEL_ID = "deepseek/deepseek-v4-pro"  # OpenRouter spec identifier for DeepSeek V4 Pro
TRIAL_NAME = "t1"

REQUEST_TIMEOUT = 600       # 10 min ceiling for large RTL generation tasks
MAX_RETRIES = 3
RETRY_BACKOFF = 5           # seconds, multiplied by attempt number

# Initialize standard OpenAI client configured for OpenRouter
client = OpenAI(
    api_key=API_KEY,
    base_url=BASE_URL,
    timeout=REQUEST_TIMEOUT,
    max_retries=0,          # Retrying natively inside custom backoff loop below
    default_headers={
        "HTTP-Referer": "https://github.com/hkust-zhiyao/RTLLM",  # Recommended by OpenRouter
        "X-OpenRouter-Title": "RTLLM Benchmark Automation",       # Appears in your dashboard
    }
)

# 1. Locate designs
design_map = {}
for root, dirs, files in os.walk("."):
    if "design_description.txt" in files and "makefile" in files:
        design_map[os.path.basename(root)] = root

if args.only:
    if args.only not in design_map:
        raise SystemExit(f"Error: design '{args.only}' not found.")
    design_map = {args.only: design_map[args.only]}

# 2. Output dir setup
output_dir = os.path.abspath(f"{LANG['out_dir']}/{TRIAL_NAME}")
os.makedirs(output_dir, exist_ok=True)

print(f"Found {len(design_map)} designs. Generating {LANG['label']} via OpenRouter...")

def generate_with_retry(prompt, name):
    last_err = None
    for attempt in range(1, MAX_RETRIES + 1):
        try:
            stream = client.chat.completions.create(
                model=MODEL_ID,
                messages=[{"role": "user", "content": prompt}],
                temperature=0.2,
                timeout=REQUEST_TIMEOUT,
                stream=True,
            )
            chunks = []
            for event in stream:
                if event.choices and event.choices[0].delta.content:
                    chunks.append(event.choices[0].delta.content)
            content = "".join(chunks)
            if not content.strip():
                raise RuntimeError("Empty response from model")
            return content
        except (APITimeoutError, APIError, Exception) as e:
            last_err = e
            if attempt < MAX_RETRIES:
                wait = RETRY_BACKOFF * attempt
                tqdm.write(f"[Retry {attempt}/{MAX_RETRIES}] '{name}' failed ({type(e).__name__}: {e}). Sleeping {wait}s...")
                time.sleep(wait)
            else:
                raise last_err

# 3. Iterate and evaluate spec blocks
for name, folder_path in tqdm(design_map.items()):
    out_file_path = os.path.join(output_dir, f"{name}{LANG['ext']}")

    # Resume support: skip already-generated, non-empty files
    if os.path.exists(out_file_path) and os.path.getsize(out_file_path) > 0:
        tqdm.write(f"[Skip] '{name}' already generated.")
        continue

    with open(os.path.join(folder_path, "design_description.txt"), "r", encoding="utf-8") as f:
        design_description = f.read()

    # Specs are authored for Verilog; retarget the wording at prompt time so the
    # same 50 description files drive either language (entity/port names match
    # the shared Verilog testbench, which XSim binds case-insensitively).
    if args.lang == "vhdl":
        design_description = re.sub(r"verilog", "VHDL", design_description, flags=re.IGNORECASE)

    prompt = (
        f"You are an expert RTL hardware engineer.\n"
        f"Generate syntactically correct {LANG['label']} code for the module specified below.\n"
        f"Ensure all pre-defined module names, input/output port names, and bit-widths "
        f"exactly match the specification requirements.\n\n"
        f"Specification:\n{design_description}\n\n"
        f"Provide the complete {LANG['label']} code wrapped cleanly inside a "
        f"```{LANG['fence']} ... ``` codeblock."
    )

    try:
        content = generate_with_retry(prompt, name)
        match = re.search(rf"```{LANG['fence']}(.*?)```", content, re.DOTALL | re.IGNORECASE)
        rtl_code = match.group(1).strip() if match else content.strip()

        with open(out_file_path, "w", encoding="utf-8") as f:
            f.write(rtl_code)

        time.sleep(0.5)
    except Exception as e:
        tqdm.write(f"[Error] Final failure for '{name}': {e}")

print(f"\nGeneration complete! Output files saved to: {output_dir}")