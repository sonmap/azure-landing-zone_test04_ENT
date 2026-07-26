from __future__ import annotations

import json
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[1]
TOOLS = REPO_ROOT / "tools"


class ExcelDesignTest(unittest.TestCase):
    def test_template_generates_root_json_files(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            temp = Path(temp_dir)
            workbook = temp / "design.xlsx"
            output = temp / "generated"
            subprocess.run(
                [sys.executable, str(TOOLS / "create_excel_design_template.py"), "--output", str(workbook)],
                check=True,
            )
            subprocess.run(
                [
                    sys.executable,
                    str(TOOLS / "excel_design_to_auto_tfvars.py"),
                    "--excel", str(workbook),
                    "--out", str(output),
                    "--allow-placeholders",
                ],
                check=True,
            )
            expected = [
                "00-foundation/resource-groups/10-design.auto.tfvars.json",
                "10-platform/hub-network/10-design.auto.tfvars.json",
                "20-workload/sales-dev-spoke/10-design.auto.tfvars.json",
                "30-services/vm-sales-dev/10-design.auto.tfvars.json",
                "30-services/aks-sales-dev/10-design.auto.tfvars.json",
                "40-access/private-dns-zones/10-design.auto.tfvars.json",
            ]
            for relative in expected:
                path = output / relative
                self.assertTrue(path.is_file(), relative)
                json.loads(path.read_text(encoding="utf-8"))


if __name__ == "__main__":
    unittest.main()
