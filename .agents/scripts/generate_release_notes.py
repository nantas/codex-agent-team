#!/usr/bin/env python3
from __future__ import annotations

import argparse
import importlib.util
import sys
from pathlib import Path


def _load_changelog_module():
    script_path = Path(__file__).resolve().parent / "changelog_extract.py"
    spec = importlib.util.spec_from_file_location("changelog_extract", script_path)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"failed to load module from {script_path}")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Generate release notes for a target version.")
    parser.add_argument("--repo", required=True, help="GitHub repo in owner/name format")
    parser.add_argument("--version", required=True, help="Version without v prefix, e.g. 1.2.3")
    parser.add_argument(
        "--changelog-path", default="CHANGELOG.md", help="Path to changelog markdown"
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()

    changelog_path = Path(args.changelog_path)
    if not changelog_path.is_file():
        print(f"missing changelog file: {changelog_path}", file=sys.stderr)
        return 1

    try:
        mod = _load_changelog_module()
        changelog_text = changelog_path.read_text(encoding="utf-8")
        changelog_body = mod.extract_version_block(changelog_text, args.version).strip()
    except Exception as exc:  # noqa: BLE001
        print(f"failed to build changelog section: {exc}", file=sys.stderr)
        return 1

    install_url = f"https://github.com/{args.repo}/blob/v{args.version}/.agents/INSTALL.md"
    prompt_line = (
        f"请让你的 agent 按此安装指南完成 codex-agent-team v{args.version} 安装：{install_url}"
    )

    output = (
        "## Changelog\n\n"
        f"{changelog_body}\n\n"
        "## Agent Auto Install\n\n"
        f"{prompt_line}\n"
    )
    sys.stdout.write(output)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
