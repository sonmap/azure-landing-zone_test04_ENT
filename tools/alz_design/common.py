from __future__ import annotations

import os
import re
from dataclasses import dataclass
from typing import Any, Iterable

ENV_PATTERN = re.compile(r"^\$\{ENV:([A-Za-z_][A-Za-z0-9_]*)\}$")
MODULE_TYPES = {
    "resource_groups",
    "hub_network",
    "workload_spoke",
    "vm",
    "aks",
    "ai",
    "private_dns_zones",
}


class DesignError(RuntimeError):
    pass


@dataclass
class Context:
    global_values: dict[str, Any]
    resource_groups: dict[str, dict[str, Any]]
    hubs: dict[str, dict[str, Any]]
    hub_subnets: list[dict[str, Any]]
    workloads: dict[str, dict[str, Any]]
    workload_subnets: dict[str, dict[str, Any]]
    vms: dict[str, dict[str, Any]]
    vm_disks: list[dict[str, Any]]
    aks_clusters: dict[str, dict[str, Any]]
    aks_node_pools: list[dict[str, Any]]
    ai_services: dict[str, dict[str, Any]]
    private_dns_rows: list[dict[str, Any]]


def rows(ws) -> list[dict[str, Any]]:
    values = list(ws.iter_rows(values_only=True))
    if not values:
        return []
    headers = [str(v or "").strip() for v in values[0]]
    result: list[dict[str, Any]] = []
    for line_number, row_values in enumerate(values[1:], 2):
        if not any(v not in (None, "") for v in row_values):
            continue
        item = {headers[i]: row_values[i] for i in range(min(len(headers), len(row_values))) if headers[i]}
        item["__line__"] = line_number
        result.append(item)
    return result


def key_values(ws) -> dict[str, Any]:
    result: dict[str, Any] = {}
    for row in rows(ws):
        key = str(row.get("key", "")).strip()
        if not key:
            continue
        if key in result:
            raise DesignError(f"{ws.title}: duplicate key '{key}'")
        result[key] = row.get("value")
    return result


def is_enabled(row: dict[str, Any]) -> bool:
    return str(row.get("enabled", "Y")).strip().lower() in {"y", "yes", "true", "1", "사용", "예"}


def as_bool(value: Any, default: bool = False) -> bool:
    if value in (None, ""):
        return default
    return str(value).strip().lower() in {"y", "yes", "true", "1", "사용", "예", "enabled"}


def as_int(value: Any, field: str) -> int:
    try:
        return int(float(str(value).strip()))
    except (TypeError, ValueError) as exc:
        raise DesignError(f"{field}: integer required, got {value!r}") from exc


def split_list(value: Any) -> list[str]:
    if value in (None, ""):
        return []
    return [part.strip() for part in str(value).replace(";", "|").split("|") if part.strip()]


def resolve_value(value: Any, allow_placeholders: bool) -> Any:
    if not isinstance(value, str):
        return value
    match = ENV_PATTERN.match(value.strip())
    if not match:
        return value
    name = match.group(1)
    env_value = os.environ.get(name)
    if env_value not in (None, ""):
        return env_value
    if allow_placeholders:
        return value
    raise DesignError(f"environment variable '{name}' is required for {value}")


def index_by(rows_: Iterable[dict[str, Any]], key: str, sheet: str) -> dict[str, dict[str, Any]]:
    result: dict[str, dict[str, Any]] = {}
    for row in rows_:
        if not is_enabled(row):
            continue
        value = str(row.get(key, "")).strip()
        if not value:
            raise DesignError(f"{sheet} line {row.get('__line__')}: '{key}' is required")
        if value in result:
            raise DesignError(f"{sheet}: duplicate {key} '{value}'")
        result[value] = row
    return result


def required(row: dict[str, Any], key: str, sheet: str) -> Any:
    value = row.get(key)
    if value in (None, ""):
        raise DesignError(f"{sheet} line {row.get('__line__')}: '{key}' is required")
    return value


def ensure_reference(ref: str, mapping: dict[str, Any], field: str) -> None:
    if ref not in mapping:
        raise DesignError(f"{field}: reference '{ref}' does not exist")


def common_tags(global_values: dict[str, Any]) -> dict[str, str]:
    return {
        "project": str(global_values.get("project", "azure-landing-zone")),
        "managed_by": str(global_values.get("managed_by", "terraform")),
    }


def row_tags(row: dict[str, Any], base: dict[str, str]) -> dict[str, str]:
    tags = dict(base)
    for column in ("environment", "department", "owner", "costcenter", "data_class", "itsm_ticket"):
        value = row.get(column)
        if value not in (None, ""):
            tags[column] = str(value)
    return tags


def image_for(os_name: Any) -> dict[str, str]:
    text = str(os_name or "").lower()
    if "win" in text:
        return {"image_publisher": "MicrosoftWindowsServer", "image_offer": "WindowsServer", "image_sku": "2022-datacenter-g2"}
    if "ubuntu" in text:
        return {"image_publisher": "Canonical", "image_offer": "0001-com-ubuntu-server-jammy", "image_sku": "22_04-lts-gen2"}
    return {"image_publisher": "RedHat", "image_offer": "RHEL", "image_sku": "9-lvm-gen2"}


def vm_bucket(role: Any) -> str:
    text = str(role or "agent").strip().lower()
    if text == "web":
        return "web_vms"
    if text in {"was", "app", "ap"}:
        return "was_vms"
    if text == "db":
        return "db_vms"
    return "agent_vms"


def vnet_id(subscription_id: str, rg_name: str, vnet_name: str) -> str:
    return f"/subscriptions/{subscription_id}/resourceGroups/{rg_name}/providers/Microsoft.Network/virtualNetworks/{vnet_name}"
