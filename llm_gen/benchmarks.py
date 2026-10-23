"""Load benchmark tasks: one sub-folder per task, each holding a prompt*.txt file."""
import re
from pathlib import Path

def load_benchmarks(root):
    """One task per sub-folder holding prompt*.txt. The required module names are read from the
    prompt ("module name: X"); the LAST one is the top level (SHA-256 asks for a core, then a wrapper)."""
    root = Path(root)
    if not list(root.glob("*/prompt*.txt")) and (root / root.name).is_dir():
        root = root / root.name                       # archive was extracted into a nested folder
    tasks = []
    for d in sorted(p for p in root.iterdir() if p.is_dir()):
        files = sorted(d.glob("prompt*.txt"))
        if not files:
            print(f" no prompt file in '{d.name}' – skipped"); continue
        prompt  = files[0].read_text(encoding="utf-8").replace("\r\n", "\n").strip()
        task_id = d.name.replace(" ", "_")            # Vivado-path safe
        mods    = list(dict.fromkeys(re.findall(r"module name:\s*(\w+)", prompt, re.I))) or [task_id]
        tasks.append(dict(task_id=task_id, prompt=prompt, modules=mods, top=mods[-1]))
    return tasks