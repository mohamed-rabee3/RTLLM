import argparse
import json
import os
import re
import time
import uuid
from concurrent.futures import ThreadPoolExecutor, as_completed
from datetime import datetime, timezone

from openai import OpenAI
from tqdm import tqdm

from benchmark_config import BENCHMARK_DESIGNS, discover_design_paths


ROOT_DIR = os.path.dirname(os.path.abspath(__file__))
LANG_CONFIG = {
    "verilog": {"ext": ".v", "label": "Verilog", "fence": "verilog"},
    "vhdl": {"ext": ".vhd", "label": "VHDL", "fence": "vhdl"},
}
DEFAULT_OPENROUTER_MODEL = "deepseek/deepseek-v4-pro"
DEFAULT_CHATMOCK_MODEL = "gpt-5.6-sol"
DEFAULT_CHATMOCK_URL = "http://127.0.0.1:8000/v1"
DEFAULT_OPENCODE_MODEL = "glm-5.3-flash"
# The Go subscription and the pay-as-you-go Zen balance share one API key but are
# billed separately and sit behind different base URLs. A Go key gets "Insufficient
# balance" from the Zen URL even though the subscription is active.
OPENCODE_URLS = {
    "go": "https://opencode.ai/zen/go/v1",
    "zen": "https://opencode.ai/zen/v1",
}


def load_env_file(env_path=None):
    """Load KEY=VALUE pairs from .env without overriding existing variables."""
    env_path = env_path or os.path.join(ROOT_DIR, ".env")
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
            if sep:
                key = key.strip()
                value = value.strip().strip('"').strip("'")
                if key and key not in os.environ:
                    os.environ[key] = value


def utc_now():
    return datetime.now(timezone.utc).isoformat().replace("+00:00", "Z")


def slugify_model(model):
    return re.sub(r"[^a-z0-9]+", "_", model.lower()).strip("_")


def default_output_dir(backend, model, lang):
    suffix = "_vhdl" if lang == "vhdl" else ""
    if backend == "chatmock":
        return f"chatmock_{slugify_model(model)}_high{suffix}"
    if backend == "opencode":
        return f"opencode_{slugify_model(model)}{suffix}"
    if model == DEFAULT_OPENROUTER_MODEL:
        return "openrouter_deepseek_v4_pro" + suffix
    # "openai/gpt-6-astra" -> "openrouter_gpt_6_astra"
    return f"openrouter_{slugify_model(model.split('/')[-1])}{suffix}"


def openrouter_reasoning_model(model):
    """OpenAI reasoning models on OpenRouter reject temperature and take a reasoning effort."""
    return model.startswith("openai/gpt-6") or model.startswith("~openai/gpt-")


def make_prompt(design_description, lang):
    language = LANG_CONFIG[lang]
    if lang == "vhdl":
        design_description = re.sub(r"verilog", "VHDL", design_description, flags=re.IGNORECASE)
    return (
        f"Generate the complete synthesizable {language['label']} RTL described below.\n"
        "Preserve the specified top-level module/entity name, every port name, direction, and width exactly.\n"
        "The code will be compiled and tested automatically, so include all required declarations and logic.\n"
        "Return only one complete HDL code block and no explanation.\n\n"
        f"Specification:\n{design_description}"
    )


def extract_rtl(content, fence):
    match = re.search(rf"```(?:{re.escape(fence)})?\s*(.*?)```", content, re.DOTALL | re.IGNORECASE)
    return (match.group(1) if match else content).strip()


def build_client(args):
    if args.backend == "chatmock":
        return OpenAI(
            api_key=os.environ.get("CHATMOCK_API_KEY", "chatmock-local"),
            base_url=args.base_url or os.environ.get("CHATMOCK_BASE_URL", DEFAULT_CHATMOCK_URL),
            timeout=args.request_timeout,
            max_retries=0,
        )

    if args.backend == "opencode":
        api_key = os.environ.get("OPENCODE_API_KEY", "")
        if not api_key:
            raise SystemExit("Error: OPENCODE_API_KEY not set (put it in .env).")
        return OpenAI(
            api_key=api_key,
            base_url=(args.base_url or os.environ.get("OPENCODE_BASE_URL")
                      or OPENCODE_URLS[args.opencode_plan]),
            timeout=args.request_timeout,
            max_retries=0,
        )

    api_key = os.environ.get("OPENROUTER_API_KEY", "")
    if not api_key:
        raise SystemExit("Error: OPENROUTER_API_KEY not set (put it in .env).")
    return OpenAI(
        api_key=api_key,
        base_url=args.base_url or "https://openrouter.ai/api/v1",
        timeout=args.request_timeout,
        max_retries=0,
        default_headers={
            "HTTP-Referer": "https://github.com/hkust-zhiyao/RTLLM",
            "X-OpenRouter-Title": "RTLLM Benchmark Automation",
        },
    )


def request_completion(client, args, prompt):
    if args.backend == "chatmock":
        stream = client.responses.create(
            model=args.model,
            input=prompt,
            reasoning={"effort": args.reasoning_effort, "summary": "none"},
            store=False,
            stream=True,
        )
        chunks = []
        try:
            for event in stream:
                if getattr(event, "type", None) == "response.output_text.delta":
                    delta = getattr(event, "delta", None)
                    if isinstance(delta, str):
                        chunks.append(delta)
                elif getattr(event, "type", None) == "response.failed":
                    response = getattr(event, "response", None)
                    error = getattr(response, "error", None)
                    raise RuntimeError(getattr(error, "message", None) or "ChatMock response failed")
        finally:
            stream.close()
        return "".join(chunks)

    extra_headers = None
    if args.backend == "opencode":
        extra_headers = {"x-opencode-session": str(uuid.uuid4())}

    sampling = {"temperature": 0.2}
    if args.backend == "openrouter" and openrouter_reasoning_model(args.model):
        sampling = {
            "max_tokens": args.max_tokens,
            "extra_body": {"reasoning": {"effort": args.reasoning_effort, "exclude": True}},
        }

    stream = client.chat.completions.create(
        model=args.model,
        messages=[{"role": "user", "content": prompt}],
        timeout=args.request_timeout,
        stream=True,
        extra_headers=extra_headers,
        **sampling,
    )
    chunks = []
    for event in stream:
        if event.choices and event.choices[0].delta.content:
            chunks.append(event.choices[0].delta.content)
    return "".join(chunks)


def generate_with_retry(client, args, prompt, task_name):
    last_error = None
    for attempt in range(1, args.retries + 1):
        try:
            content = request_completion(client, args, prompt)
            if not content or not content.strip():
                raise RuntimeError("Empty response from model")
            return content
        except Exception as exc:
            last_error = exc
            if attempt == args.retries:
                break
            wait_seconds = args.retry_backoff * attempt
            tqdm.write(
                f"[Retry {attempt}/{args.retries}] {task_name} failed "
                f"({type(exc).__name__}: {exc}); retrying in {wait_seconds}s."
            )
            time.sleep(wait_seconds)
    raise last_error


def parse_args():
    parser = argparse.ArgumentParser(description="Generate RTL for the RTLLM benchmark.")
    parser.add_argument("--lang", choices=LANG_CONFIG, default="verilog")
    parser.add_argument("--backend", choices=("openrouter", "chatmock", "opencode"), default="openrouter")
    parser.add_argument("--model", default=None,
                        help="Model ID. ChatMock default: gpt-5.6-sol. opencode default: glm-5.3-flash.")
    parser.add_argument("--base-url", default=None, help="Override the provider base URL.")
    parser.add_argument("--opencode-plan", choices=tuple(OPENCODE_URLS), default="go",
                        help="Which opencode billing route to call (default: go).")
    parser.add_argument("--reasoning-effort", choices=("low", "medium", "high", "xhigh", "max", "ultra"),
                        default="high",
                        help="Reasoning effort for ChatMock and OpenRouter reasoning models (default: high).")
    parser.add_argument("--max-tokens", type=int, default=32000,
                        help="Output token cap (incl. reasoning) for OpenRouter reasoning models (default: 32000).")
    parser.add_argument("--output-dir", default=None, help="Generated RTL output directory.")
    parser.add_argument("--only", default=None, help="Generate just one benchmark design.")
    parser.add_argument("--trials", type=int, default=5,
                        help="Independent trials t1..tN (default: 5 for pass@1..5).")
    parser.add_argument("--workers", type=int, default=1,
                        help="Concurrent generation requests (default: 1).")
    parser.add_argument("--request-timeout", type=float, default=900,
                        help="Per-request timeout in seconds (default: 900).")
    parser.add_argument("--retries", type=int, default=5)
    parser.add_argument("--retry-backoff", type=int, default=15)
    args = parser.parse_args()
    if args.trials < 1 or args.workers < 1 or args.retries < 1:
        parser.error("--trials, --workers, and --retries must all be at least 1")
    if args.backend == "chatmock" and args.reasoning_effort != "high":
        parser.error("This benchmark configuration is pinned to --reasoning-effort high.")
    if not args.model:
        args.model = {
            "chatmock": DEFAULT_CHATMOCK_MODEL,
            "opencode": DEFAULT_OPENCODE_MODEL,
        }.get(args.backend, DEFAULT_OPENROUTER_MODEL)
    return args


def main():
    args = parse_args()
    load_env_file()
    language = LANG_CONFIG[args.lang]
    output_root = os.path.abspath(
        args.output_dir or os.path.join(ROOT_DIR, default_output_dir(args.backend, args.model, args.lang))
    )
    design_paths = discover_design_paths(ROOT_DIR)
    missing = [name for name in BENCHMARK_DESIGNS if name not in design_paths]
    if missing:
        raise SystemExit(f"Error: missing benchmark design folders: {', '.join(missing)}")
    selected = [args.only] if args.only else list(BENCHMARK_DESIGNS)
    if args.only and args.only not in design_paths:
        raise SystemExit(f"Error: design '{args.only}' is not in the 72-design benchmark.")

    client = build_client(args)
    if args.backend == "chatmock":
        try:
            available = {model.id for model in client.models.list().data}
        except Exception as exc:
            raise SystemExit(f"Error: cannot reach ChatMock at {client.base_url}: {exc}") from exc
        if args.model not in available:
            raise SystemExit(
                f"Error: ChatMock is reachable, but '{args.model}' is unavailable for the signed-in account."
            )

    trial_names = [f"t{i}" for i in range(1, args.trials + 1)]
    for trial_name in trial_names:
        os.makedirs(os.path.join(output_root, trial_name), exist_ok=True)

    uses_reasoning = args.backend == "chatmock" or (
        args.backend == "openrouter" and openrouter_reasoning_model(args.model))
    manifest_path = os.path.join(output_root, "run_manifest.json")
    manifest = {
        "schema_version": 1,
        "backend": args.backend,
        "base_url": str(client.base_url),
        "model": args.model,
        "reasoning_effort": args.reasoning_effort if uses_reasoning else None,
        "temperature": None if uses_reasoning else 0.2,
        "max_tokens": args.max_tokens if args.backend == "openrouter" and uses_reasoning else None,
        "language": args.lang,
        "opencode_plan": args.opencode_plan if args.backend == "opencode" else None,
        "trials": trial_names,
        "design_count": len(selected),
        "workers": args.workers,
        "started_at": utc_now(),
        "completed_at": None,
        "generated": 0,
        "skipped_existing": 0,
        "failed": 0,
    }
    os.makedirs(output_root, exist_ok=True)
    with open(manifest_path, "w", encoding="utf-8") as file:
        json.dump(manifest, file, indent=2)

    tasks = []
    skipped = 0
    for trial_name in trial_names:
        for design in selected:
            output_path = os.path.join(output_root, trial_name, f"{design}{language['ext']}")
            if os.path.isfile(output_path) and os.path.getsize(output_path) > 0:
                skipped += 1
                continue
            description_path = os.path.join(design_paths[design], "design_description.txt")
            with open(description_path, "r", encoding="utf-8") as file:
                prompt = make_prompt(file.read(), args.lang)
            tasks.append((trial_name, design, output_path, prompt))

    effort_note = f"reasoning effort={args.reasoning_effort}; " if uses_reasoning else ""
    print(
        f"Generating {len(tasks)} missing {language['label']} candidates with {args.model} "
        f"via {args.backend}; {effort_note}workers={args.workers}."
    )
    if skipped:
        print(f"Resume mode: {skipped} existing non-empty candidates will be kept.")

    failures = []

    def run_task(task):
        trial_name, design, output_path, prompt = task
        content = generate_with_retry(client, args, prompt, f"{design}/{trial_name}")
        rtl_code = extract_rtl(content, language["fence"])
        if not rtl_code:
            raise RuntimeError("Model response did not contain HDL code")
        with open(output_path, "w", encoding="utf-8", newline="\n") as file:
            file.write(rtl_code.rstrip() + "\n")
        return trial_name, design

    with ThreadPoolExecutor(max_workers=args.workers) as executor:
        futures = {executor.submit(run_task, task): task for task in tasks}
        with tqdm(total=len(tasks), unit="candidate") as progress:
            for future in as_completed(futures):
                trial_name, design, _path, _prompt = futures[future]
                try:
                    future.result()
                except Exception as exc:
                    failures.append({"trial": trial_name, "design": design, "error": f"{type(exc).__name__}: {exc}"})
                    tqdm.write(f"[Error] {design}/{trial_name}: {type(exc).__name__}: {exc}")
                progress.update(1)

    manifest.update({
        "completed_at": utc_now(),
        "generated": len(tasks) - len(failures),
        "skipped_existing": skipped,
        "failed": len(failures),
        "failures": failures,
    })
    with open(manifest_path, "w", encoding="utf-8") as file:
        json.dump(manifest, file, indent=2)

    if failures:
        raise SystemExit(f"Generation finished with {len(failures)} failed candidates; rerun to resume.")
    print(f"Generation complete: {output_root}")


if __name__ == "__main__":
    main()
