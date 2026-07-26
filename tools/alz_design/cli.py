from __future__ import annotations

import argparse
import json
import shutil
import sys
from pathlib import Path

from .builders import BUILDERS
from .common import DesignError
from .loader import load_context
from .validate import validate_context


def write_json(path: Path, data: dict) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"created: {path}")


def publish_tree(source: Path, destination: Path) -> None:
    for file in source.rglob("10-design.auto.tfvars.json"):
        target = destination / file.relative_to(source)
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(file, target)
        print(f"published: {target}")


def run() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--excel", required=True, help="Excel design workbook")
    parser.add_argument("--out", default="generated_tfvars", help="Staging output directory")
    parser.add_argument("--publish-live", action="store_true")
    parser.add_argument("--live-root", default="live")
    parser.add_argument("--allow-placeholders", action="store_true")
    parser.add_argument("--validate-only", action="store_true")
    args = parser.parse_args()

    try:
        ctx, generation_map = load_context(Path(args.excel), args.allow_placeholders)
        validate_context(ctx, generation_map)
        print("validation: OK")
        if args.validate_only:
            return

        out = Path(args.out)
        for generation in generation_map:
            module_type = str(generation["module_type"]).strip()
            source_key = str(generation.get("source_key") or "all").strip()
            output_root = Path(str(generation["output_root"]).replace("\\", "/"))
            output_filename = str(generation.get("output_filename") or "10-design.auto.tfvars.json")
            write_json(out / output_root / output_filename, BUILDERS[module_type](ctx, source_key))

        if args.publish_live:
            publish_tree(out, Path(args.live_root))
    except (DesignError, KeyError, ValueError) as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        raise SystemExit(2) from exc
