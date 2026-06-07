#!/usr/bin/env python3
import argparse
import json
from pathlib import Path

parser = argparse.ArgumentParser()
parser.add_argument("--input", required=True, help="terraform output -json 결과 파일")
parser.add_argument("--out", required=True)
parser.add_argument("--user", default="azureuser")
args = parser.parse_args()

data = json.loads(Path(args.input).read_text(encoding="utf-8"))
lines = []

def add_group(name, value_key):
    values = data.get(value_key, {}).get("value", {})
    if not values:
        return
    lines.append(f"[{name}]")
    for host, ip in values.items():
        lines.append(f"{host} ansible_host={ip} ansible_user={args.user}")
    lines.append("")

add_group("web", "web_private_ips")
add_group("was", "was_private_ips")

if not lines and "private_ip_address" in data:
    lines.extend(["[vm]", f"vm ansible_host={data['private_ip_address']['value']} ansible_user={args.user}", ""])

lines.extend(["[all:vars]", "ansible_ssh_common_args='-o StrictHostKeyChecking=no'", ""])
Path(args.out).parent.mkdir(parents=True, exist_ok=True)
Path(args.out).write_text("\n".join(lines), encoding="utf-8")
print(f"created: {args.out}")
