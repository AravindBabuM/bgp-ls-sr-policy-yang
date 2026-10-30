#!/usr/bin/env python3
"""Synchronize the standalone YANG source into the Internet-Draft."""

from __future__ import annotations

import argparse
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
DRAFT = ROOT / "draft-aravind-lsvr-bgp-ls-sr-policy-yang.md"
MODEL = ROOT / "src" / "yang" / "ietf-bgp-ls-sr-policy.yang"
BEGIN = "<!-- YANG-MODEL:BEGIN -->"
END = "<!-- YANG-MODEL:END -->"


def module_file_name(model: str) -> str:
    for line in model.splitlines():
        words = line.split()
        if len(words) >= 2 and words[0] == "revision":
            return f"{MODEL.stem}@{words[1]}.yang"
    raise RuntimeError(f"no revision statement in {MODEL}")


def rendered_draft() -> str:
    draft = DRAFT.read_text(encoding="utf-8")
    model = MODEL.read_text(encoding="utf-8").rstrip()
    before, separator, remainder = draft.partition(BEGIN)
    if not separator:
        raise RuntimeError(f"missing marker {BEGIN!r} in {DRAFT}")
    _, separator, after = remainder.partition(END)
    if not separator:
        raise RuntimeError(f"missing marker {END!r} in {DRAFT}")
    block = (
        f"{BEGIN}\n~~~ yang\n"
        f'<CODE BEGINS> file "{module_file_name(model)}"\n\n'
        f"{model}\n\n<CODE ENDS>\n~~~\n{END}"
    )
    return before + block + after


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
                "embedded YANG is stale; run scripts/sync-draft-yang.py",
                file=sys.stderr,
            )
            return 1
        return 0

    if current != rendered:
        DRAFT.write_text(rendered, encoding="utf-8")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
