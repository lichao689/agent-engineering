#!/usr/bin/env python3
"""Validate the Agent Engineering repository's content and distribution entrypoints."""

from __future__ import annotations

import json
from datetime import date
from pathlib import Path
import re
import sys
from urllib.parse import unquote


ROOT = Path(__file__).resolve().parents[1]
CANONICAL_REPOSITORY = "lichao689/agent-engineering"
LEGACY_REPOSITORIES = ("lichao689/skills",)
REQUIRED_FILES = (
    Path("README.md"),
    Path("AGENTS.md"),
    Path("knowledge/README.md"),
    Path("knowledge/agent-instructions/github-agents-md-lessons-2500-repositories.md"),
    Path("playbooks/designing-agents-md.md"),
    Path(".claude-plugin/plugin.json"),
)
SOURCE_NOTE_FIELDS = {
    "title",
    "source_url",
    "author",
    "published",
    "updated",
    "checked",
    "status",
}
MARKDOWN_LINK_RE = re.compile(r"!?\[[^\]]*\]\(([^)]+)\)")
URI_SCHEME_RE = re.compile(r"^[a-z][a-z0-9+.-]*:", re.IGNORECASE)


def relative(path: Path) -> str:
    return path.relative_to(ROOT).as_posix()


def markdown_files() -> list[Path]:
    files = [ROOT / "README.md", ROOT / "AGENTS.md"]
    for directory in (ROOT / "knowledge", ROOT / "playbooks"):
        if directory.is_dir():
            files.extend(sorted(directory.rglob("*.md")))
    return files


def link_target(raw_target: str) -> str:
    target = raw_target.strip()
    if target.startswith("<") and ">" in target:
        target = target[1 : target.index(">")]
    else:
        target = target.split(maxsplit=1)[0]
    return unquote(target.split("#", maxsplit=1)[0])


def check_links(path: Path, text: str) -> list[str]:
    errors: list[str] = []
    for raw_target in MARKDOWN_LINK_RE.findall(text):
        if raw_target.startswith("#") or URI_SCHEME_RE.match(raw_target):
            continue
        target = link_target(raw_target)
        if not target:
            continue
        resolved = (path.parent / target).resolve()
        try:
            resolved.relative_to(ROOT)
        except ValueError:
            errors.append(f"LINK_ESCAPE: {relative(path)} -> {raw_target}")
            continue
        if not resolved.exists():
            errors.append(f"LINK_TARGET: {relative(path)} -> {target}")
    return errors


def frontmatter(text: str) -> dict[str, str]:
    lines = text.splitlines()
    if not lines or lines[0] != "---":
        return {}
    try:
        end = lines.index("---", 1)
    except ValueError:
        return {}
    values: dict[str, str] = {}
    for line in lines[1:end]:
        key, separator, value = line.partition(":")
        if separator:
            values[key.strip()] = value.strip().strip('"\'')
    return values


def check_source_notes() -> list[str]:
    errors: list[str] = []
    source_root = ROOT / "knowledge"
    for path in sorted(source_root.rglob("*.md")):
        if path.name == "README.md":
            continue
        metadata = frontmatter(path.read_text(encoding="utf-8"))
        missing = sorted(SOURCE_NOTE_FIELDS - metadata.keys())
        if missing:
            errors.append(f"SOURCE_FIELDS: {relative(path)} missing {', '.join(missing)}")
        if metadata.get("status") != "source-note":
            errors.append(f"SOURCE_STATUS: {relative(path)} must use status: source-note")
        checked = metadata.get("checked", "")
        try:
            checked_date = date.fromisoformat(checked)
        except ValueError:
            errors.append(f"SOURCE_CHECKED: {relative(path)} needs an ISO checked date")
        else:
            if checked_date > date.today():
                errors.append(f"SOURCE_CHECKED: {relative(path)} checked date is in the future")
        source_url = metadata.get("source_url", "")
        if not source_url.startswith(("https://", "http://")):
            errors.append(f"SOURCE_URL: {relative(path)} needs an HTTP(S) source_url")
    return errors


def check_plugin_manifest() -> list[str]:
    path = ROOT / ".claude-plugin" / "plugin.json"
    try:
        payload = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        return [f"PLUGIN_JSON: {exc}"]
    errors: list[str] = []
    for item in payload.get("skills", []):
        target = (ROOT / item).resolve()
        if not (target / "SKILL.md").is_file():
            errors.append(f"PLUGIN_SKILL: missing {item}/SKILL.md")
    return errors


def validate() -> list[str]:
    errors: list[str] = []
    for item in REQUIRED_FILES:
        if not (ROOT / item).is_file():
            errors.append(f"REQUIRED: missing {item.as_posix()}")

    for path in markdown_files():
        if not path.is_file():
            continue
        payload = path.read_bytes()
        if payload.startswith(b"\xef\xbb\xbf"):
            errors.append(f"ENCODING: {relative(path)} has UTF-8 BOM")
        if b"\r\n" in payload:
            errors.append(f"LINE_ENDING: {relative(path)} has CRLF")
        text = payload.decode("utf-8-sig")
        errors.extend(check_links(path, text))

    readme = (ROOT / "README.md").read_text(encoding="utf-8")
    if CANONICAL_REPOSITORY not in readme:
        errors.append(f"REPOSITORY_NAME: README.md must name {CANONICAL_REPOSITORY}")
    for legacy in LEGACY_REPOSITORIES:
        if legacy in readme:
            errors.append(f"LEGACY_REPOSITORY: README.md still contains {legacy}")

    errors.extend(check_source_notes())
    errors.extend(check_plugin_manifest())
    return sorted(errors)


def main() -> int:
    errors = validate()
    if errors:
        for error in errors:
            print(f"FAIL: {error}")
        return 1
    print("Repository checks passed.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
