#!/usr/bin/env bash
set -euo pipefail

EXCEL="${EXCEL:-design/azure_landingzone_design.xlsx}"
OUT="${OUT:-generated_tfvars}"

args=(tools/excel_design_to_auto_tfvars.py --excel "$EXCEL" --out "$OUT")
if [[ "${PUBLISH_LIVE:-false}" == "true" ]]; then
  args+=(--publish-live --live-root live)
fi
if [[ "${ALLOW_PLACEHOLDERS:-false}" == "true" ]]; then
  args+=(--allow-placeholders)
fi

python3 "${args[@]}"
