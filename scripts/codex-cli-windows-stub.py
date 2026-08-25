# Stub Codex CLI for launcher tests. Reads CODEX_STUB_DIR and optional CODEX_STUB_MUTEX.
import os
import sys
from pathlib import Path

stub_dir = Path(os.environ["CODEX_STUB_DIR"])
stub_dir.mkdir(parents=True, exist_ok=True)
(stub_dir / "args.txt").write_text("\n".join(sys.argv[1:]), encoding="utf-8")
(stub_dir / "stdin.txt").write_text(sys.stdin.read(), encoding="utf-8")
if os.environ.get("CODEX_STUB_MUTEX") == "1" and sys.argv[-1:] == ["-"]:
    sys.stderr.write("error: the argument '--uncommitted' cannot be used with '[PROMPT]'\n")
    raise SystemExit(2)
print("stub-ok")
