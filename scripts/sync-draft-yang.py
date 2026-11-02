#!/usr/bin/env python3
"""Synchronize the standalone YANG source into the Internet-Draft."""

from __future__ import annotations

import argparse
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
DRAFT = ROOT / "draft-aravind-idr-bgp-ls-sr-policy-yang.md"
YANG_DIR = ROOT / "src" / "yang"
TREE = ROOT / "build" / "ietf-bgp-ls-sr-policy-tree.txt"
TREE_WIDTH = 69
MODULES = (
    ("ietf-bgp-ls-sr-policy", "YANG-MODEL"),
    ("iana-bgp-ls-sr-policy-types", "IANA-YANG-MODEL"),
)


def module_file_name(name: str, model: str) -> str:
    for line in model.splitlines():
        words = line.split()
        if len(words) >= 2 and words[0] == "revision":
            return f"{name}@{words[1]}.yang"
    raise RuntimeError(f"no revision statement in {name}")


def wrap_tree_line(line: str) -> list[str]:
    # pyang does not wrap list keys; wrap them at word boundaries.
    stripped = line.lstrip()
    if len(line) <= TREE_WIDTH or not stripped.startswith("["):
        return [line]
    indent = len(line) - len(stripped)
    lines: list[str] = []
    current = " " * indent
    for word in stripped.split():
        if not current.strip():
            current += word
        elif len(current) + 1 + len(word) > TREE_WIDTH:
            lines.append(current)
            current = " " * (indent + 1) + word
        else:
            current += " " + word
    lines.append(current)
    return lines


def rendered_tree() -> str:
    if not TREE.exists():
        raise RuntimeError(f"{TREE} not found; run 'make validate-yang'")
    lines: list[str] = []
    for line in TREE.read_text(encoding="utf-8").rstrip().splitlines():
        lines.extend(wrap_tree_line(line.rstrip()))
    return "\n".join(lines)


def replace_block(draft: str, marker: str, block: str) -> str:
    begin = f"<!-- {marker}:BEGIN -->"
    end = f"<!-- {marker}:END -->"
    before, separator, remainder = draft.partition(begin)
    if not separator:
        raise RuntimeError(f"missing marker {begin!r} in {DRAFT}")
    _, separator, after = remainder.partition(end)
    if not separator:
        raise RuntimeError(f"missing marker {end!r} in {DRAFT}")
    return f"{before}{begin}\n{block}\n{end}{after}"


def rendered_draft() -> str:
    draft = DRAFT.read_text(encoding="utf-8")
    for name, marker in MODULES:
        model = (YANG_DIR / f"{name}.yang").read_text(encoding="utf-8")
        model = model.rstrip()
        block = (
            "~~~ yang\n"
            f'<CODE BEGINS> file "{module_file_name(name, model)}"\n\n'
            f"{model}\n\n<CODE ENDS>\n~~~"
        )
        draft = replace_block(draft, marker, block)
    return replace_block(draft, "COMPLETE-TREE", f"~~~\n{rendered_tree()}\n~~~")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--check",
        action="store_true",
        help="fail if the embedded module is not synchronized",
    )
    args = parser.parse_args()

    rendered = rendered_draft()
    current = DRAFT.read_text(encoding="utf-8")
    if args.check:
        if current != rendered:
            print(
                "draft is stale; run 'make sync-draft'",
                file=sys.stderr,
            )
            return 1
        return 0

    if current != rendered:
        DRAFT.write_text(rendered, encoding="utf-8")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
