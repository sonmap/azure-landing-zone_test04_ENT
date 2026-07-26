#!/usr/bin/env python3
"""Copy reviewed generated 10-design.auto.tfvars.json files into live roots."""
from __future__ import annotations

import argparse
import filecmp
import shutil
from pathlib import Path


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--source", default="generated_tfvars")
    parser.add_argument("--destination", default="live")
    parser.add_argument("--apply", action="store_true", help="Actually copy files. Without this flag, show changes only.")
    args = parser.parse_args()

    source = Path(args.source)
    destination = Path(args.destination)
    files = sorted(source.rglob("10-design.auto.tfvars.json"))
    if not files:
        raise SystemExit(f"No 10-design.auto.tfvars.json files under {source}")

    changed: list[tuple[Path, Path, str]] = []
    for src in files:
        rel = src.relative_to(source)
        dst = destination / rel
        status = "NEW" if not dst.exists() else "CHANGED" if not filecmp.cmp(src, dst, shallow=False) else "UNCHANGED"
        print(f"{status:9} {dst}")
        if status != "UNCHANGED":
            changed.append((src, dst, status))

    if not args.apply:
        print("\nPreview only. Re-run with --apply after reviewing generated files and terraform plans.")
        return

    for src, dst, _ in changed:
        dst.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(src, dst)
        print(f"published: {dst}")

    print(f"Published {len(changed)} changed file(s). Run terraform validate and plan for each affected root.")


if __name__ == "__main__":
    main()
