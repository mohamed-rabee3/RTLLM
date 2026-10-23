"""Generate RTL for every model x task x language, validate it and save it.

  python run_benchmark.py                                  # everything in config.py
  python run_benchmark.py --models Qwen/Qwen3-8B --langs v sv
  python run_benchmark.py --no-resume                      # regenerate, ignore existing results

Output (under config.WORK_DIR):
  Generated_RTL/<model>/<task>/<top>.<ext>   one valid design per file (+ raw_<lang>.txt)
  results_all_models.json                    one row per (model, task, lang)
"""
import argparse, gc, json, time
from datetime import datetime, timezone

import config
from benchmarks import load_benchmarks
from generate import free_model, generate_raw, load_model
from prompts import LANG, family
from rtl_checks import extract, validate


def run_one(tok, model, model_id, task, lang, task_dir):
    row = dict(model=model_id.split("/")[-1], task_id=task["task_id"], lang=lang, top=task["top"],
               timestamp=datetime.now(timezone.utc).isoformat(), generated=False, valid_rtl=False,
               reject_reason=None, output_file=None, gen_time_s=None)
    ext = LANG[lang]["ext"]
    for stale in task_dir.glob(f"*{ext}"):                   # never leave an old file for Vivado to pick up
        stale.unlink()
    try:
        t0  = time.time()
        raw = generate_raw(tok, model, model_id, task, lang)
        row.update(generated=True, gen_time_s=round(time.time() - t0, 1))
        if config.SAVE_RAW:
            (task_dir / f"raw_{lang}.txt").write_text(raw, encoding="utf-8")
        code = extract(raw, lang)
        row["valid_rtl"], reason = validate(code, lang, task["modules"])
        if row["valid_rtl"]:
            path = task_dir / f"{task['top']}{ext}"
            path.write_text(code, encoding="utf-8")
            row["output_file"] = str(path)
        else:
            row["reject_reason"] = reason
    except Exception as e:                                   # OOM, tokenizer errors, ...
        row["reject_reason"] = f"runtime error: {e}"
    return row


def load_results():
    p = config.RESULTS_JSON
    return json.loads(p.read_text(encoding="utf-8")) if p.exists() else []


def save_results(rows):
    """Upsert by (model, task_id, lang); everything else in the file is kept."""
    key = lambda r: (r["model"], r["task_id"], r["lang"])
    new = {key(r) for r in rows}
    config.RESULTS_JSON.parent.mkdir(parents=True, exist_ok=True)
    config.RESULTS_JSON.write_text(
        json.dumps([r for r in load_results() if key(r) not in new] + rows, indent=2, default=str),
        encoding="utf-8")


def run_model(model_id, tasks, langs, resume):
    short = model_id.split("/")[-1]
    done  = {(r["task_id"], r["lang"]) for r in load_results() if r["model"] == short and r["generated"]} if resume else set()
    todo  = {(t["task_id"], l) for t in tasks for l in langs} - done
    if not todo:
        print(f" {short}: nothing left to do"); return
    tok, model = load_model(model_id)
    print(f"\n{'='*66}\n {short}  | prompt style: {family(tok, model_id)}  | {len(todo)} to run, {len(done)} already done\n{'='*66}")
    for i, task in enumerate(tasks, 1):
        task_dir = config.OUTPUT_DIR / short / task["task_id"]
        task_dir.mkdir(parents=True, exist_ok=True)
        rows = []
        for lang in (l for l in langs if (task["task_id"], l) in todo):
            r = run_one(tok, model, model_id, task, lang, task_dir)
            rows.append(r)
            print(f"[{i:02d}/{len(tasks)}] {task['task_id']:30s} {lang:3s} "
                  f"{'✅' if r['valid_rtl'] else '❌ ' + str(r['reject_reason'])}  ({r['gen_time_s']}s)")
        if rows:
            save_results(rows)                               # saved after every task: a crash loses at most one task
    free_model(tok, model)
    mine = [r for r in load_results() if r["model"] == short]
    for lang in langs:
        print(f"   {lang:3s} valid RTL: {sum(r['valid_rtl'] for r in mine if r['lang'] == lang)}/{len(tasks)}")


def drop_cache(model_id):
    """Delete the model's Hugging Face download (Kaggle's disk is small)."""
    from huggingface_hub import scan_cache_dir
    hashes = [r.commit_hash for repo in scan_cache_dir().repos if repo.repo_id == model_id for r in repo.revisions]
    if hashes:
        scan_cache_dir().delete_revisions(*hashes).execute()


def make_zip():
    """Bundle the generated RTL (layout <model>/<task>/<top>.<ext>) for download; refreshed after every model."""
    import zipfile
    path = config.WORK_DIR / "Generated_RTL.zip"
    with zipfile.ZipFile(path, "w", zipfile.ZIP_DEFLATED) as z:
        for p in config.OUTPUT_DIR.rglob("*"):
            if p.is_file() and (config.ZIP_RAW or not p.name.startswith("raw_")):
                z.write(p, p.relative_to(config.OUTPUT_DIR))
    return path


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--models", nargs="+", default=config.MODEL_IDS, help="Hugging Face model IDs")
    ap.add_argument("--langs", nargs="+", default=config.LANGS, choices=list(LANG), help="v / sv / vhd")
    ap.add_argument("--no-resume", action="store_true", help="regenerate even if results already exist")
    a = ap.parse_args()

    tasks = load_benchmarks(config.BENCHMARKS_DIR)
    print(f" {len(tasks)} tasks from {config.BENCHMARKS_DIR}")
    for t in tasks:
        print(f"   {t['task_id']:30s} top={t['top']:24s} modules={t['modules']}")
    config.OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

    import torch
    failed = {}
    for mid in a.models:
        try:
            run_model(mid, tasks, a.langs, resume=config.RESUME and not a.no_resume)
        except Exception as e:                  # load failure, OOM, gated repo, wrong ID ...
            failed[mid] = f"{type(e).__name__}: {str(e)[:200]}"
            print(f" {mid} skipped → {failed[mid]}")
            gc.collect(); torch.cuda.empty_cache()
        finally:
            if config.DROP_HF_CACHE:
                try: drop_cache(mid)
                except Exception: pass
            make_zip()

    print("\nSkipped models:", failed or "none")
    print(f"{make_zip()}  +  {config.RESULTS_JSON}")


if __name__ == "__main__":
    main()