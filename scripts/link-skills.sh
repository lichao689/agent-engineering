#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: scripts/link-skills.sh [--target codex|claude|all] [--dest PATH] [--strategy copy|link]

Options:
  --target   Agent skill directory to install into. Default: codex.
  --dest     Explicit destination directory. Cannot be combined with --target all.
  --strategy Install strategy. Default: copy for Codex, link for Claude.
  -h,--help  Show this help text.
USAGE
}

REPO="$(cd "$(dirname "$0")/.." && pwd)"
TARGET="codex"
DEST=""
STRATEGY=""

while [ "$#" -gt 0 ]; do
  case "$1" in
    --target)
      TARGET="${2:-}"
      shift 2
      ;;
    --dest)
      DEST="${2:-}"
      shift 2
      ;;
    --strategy)
      STRATEGY="${2:-}"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "error: unknown argument: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

resolve_path() {
  python3 -c 'import os, sys; print(os.path.realpath(sys.argv[1]))' "$1"
}

dest_for_target() {
  case "$1" in
    codex) echo "$HOME/.codex/skills" ;;
    claude) echo "$HOME/.claude/skills" ;;
    *)
      echo "error: unsupported target: $1" >&2
      exit 1
      ;;
  esac
}

install_into_dest() {
  local dest="$1"
  local strategy="$2"
  local resolved_dest
  local backup_root

  if [ "$strategy" = "link" ] && [ -L "$dest" ]; then
    resolved_dest="$(resolve_path "$dest")"
    case "$resolved_dest" in
      "$REPO"|"$REPO"/*)
        echo "error: $dest is a symlink into this repo ($resolved_dest)." >&2
        echo "Remove it and re-run; this script expects a real directory for per-skill links." >&2
        exit 1
        ;;
    esac
  fi

  mkdir -p "$dest"
  backup_root="$dest/.backup-$(date +%Y%m%d%H%M%S)"

  find "$REPO/skills" -name SKILL.md -not -path '*/node_modules/*' -not -path '*/deprecated/*' -print0 |
  while IFS= read -r -d '' skill_md; do
    local src
    local name
    local target

    src="$(dirname "$skill_md")"
    name="$(basename "$src")"
    target="$dest/$name"

    if [ -e "$target" ] && [ ! -L "$target" ]; then
      mkdir -p "$backup_root"
      mv "$target" "$backup_root/$name"
      echo "backed up existing $target -> $backup_root/$name"
    fi

    if [ -L "$target" ]; then
      rm "$target"
    fi

    case "$strategy" in
      copy)
        cp -R "$src" "$target"
        echo "copied $name -> $target"
        ;;
      link)
        ln -sfn "$src" "$target"
        echo "linked $name -> $src"
        ;;
      *)
        echo "error: unsupported strategy: $strategy" >&2
        exit 1
        ;;
    esac
  done
}

default_strategy_for_target() {
  case "$1" in
    codex) echo "copy" ;;
    claude) echo "link" ;;
    *)
      echo "error: unsupported target: $1" >&2
      exit 1
      ;;
  esac
}

if [ -n "$DEST" ] && [ "$TARGET" = "all" ]; then
  echo "error: --dest cannot be combined with --target all" >&2
  exit 1
fi

case "$TARGET" in
  all)
    install_into_dest "$(dest_for_target codex)" "${STRATEGY:-$(default_strategy_for_target codex)}"
    install_into_dest "$(dest_for_target claude)" "${STRATEGY:-$(default_strategy_for_target claude)}"
    ;;
  codex|claude)
    install_into_dest "${DEST:-$(dest_for_target "$TARGET")}" "${STRATEGY:-$(default_strategy_for_target "$TARGET")}"
    ;;
  *)
    echo "error: unsupported target: $TARGET" >&2
    usage >&2
    exit 1
    ;;
esac
