"""Launch ChatMock with a newer Codex catalog client version.

ChatMock 1.40 asks the ChatGPT Codex catalog for models as client 0.146.0, and the
catalog hides every model whose ``minimal_client_version`` is newer than that. The
GPT-6 family (gpt-6-astra needs 0.153.0, gpt-6-sol/luna 0.155.0) is therefore
missing from /v1/models even when the signed-in account has it. This wrapper raises
the advertised version and drops an on-disk catalog cache written under a different
version, then hands off to the normal ``chatmock`` CLI with the same arguments.

Usage: python chatmock_serve.py serve --host 127.0.0.1 --port 8000 ...
"""

import json
import sys

from chatmock import cli, model_catalog

CLIENT_VERSION = "0.155.0"

model_catalog.CODEX_MODELS_CLIENT_VERSION = CLIENT_VERSION
_original_load_cache = model_catalog.ModelCatalog._load_cache


def _load_cache_for_this_version(self):
    try:
        with self.cache_path.open("r", encoding="utf-8") as cache_file:
            cached_version = json.load(cache_file).get("client_version")
    except (OSError, ValueError, AttributeError):
        cached_version = None
    if cached_version == CLIENT_VERSION:
        _original_load_cache(self)


model_catalog.ModelCatalog._load_cache = _load_cache_for_this_version

if __name__ == "__main__":
    sys.argv[0] = "chatmock"
    cli.main()
