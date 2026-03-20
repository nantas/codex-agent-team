#!/usr/bin/env python3
from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path


VERSION_HEADER_RE = re.compile(r"^## \[(\d+\.\d+\.\d+)\]\s*-\s*.+$")


def extract_version_block(text: str, version: str) -> str:
    lines = text.splitlines()
    start = -1
    end = len(lines)

    for i, line in enumerate(lines):
        match = VERSION_HEADER_RE.match(line.strip())
        if not match:
            continue
        found = match.group(1)
        if start < 0 and found == version:
            start = i + 1
            continue
        if start >= 0:
            end = i
            break

    if start < 0:
        raise ValueError(f"version not found: {version}")
    return "\n".join(lines[start:end]).strip() + "\n"


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Extract changelog section body by version.")
    parser.add_argument("--version", required=True, help="Target semver, e.g. 1.2.3")
    parser.add_argument(
        "--changelog-path", default="CHANGELOG.md", help="Path to changelog file"
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    path = Path(args.changelog_path)
    if not path.is_file():
        print(f"missing changelog file: {path}", file=sys.stderr)
        return 1

    try:
        content = path.read_text(encoding="utf-8")
        section = extract_version_block(content, args.version)
    except ValueError as exc:
        print(str(exc), file=sys.stderr)
        return 1

    sys.stdout.write(section)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
