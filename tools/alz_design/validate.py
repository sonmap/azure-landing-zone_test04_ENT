from __future__ import annotations

import ipaddress
from pathlib import Path
from typing import Any

from .common import Context, DesignError, MODULE_TYPES, ensure_reference, is_enabled, required


def validate_context(ctx: Context, generation_map: list[dict[str, Any]]) -> None:
    for workload_id, workload in ctx.workloads.items():
        ensure_reference(str(required(workload, "resource_group_id", "05_Workloads")), ctx.resource_groups, f"workload {workload_id}.resource_group_id")
        ensure_reference(str(required(workload, "hub_id", "05_Workloads")), ctx.hubs, f"workload {workload_id}.hub_id")

    for disk in ctx.vm_disks:
        if is_enabled(disk):
            ensure_reference(str(required(disk, "vm_id", "08_VMDisks")), ctx.vms, "08_VMDisks.vm_id")

    for cluster_id, cluster in ctx.aks_clusters.items():
        ensure_reference(str(required(cluster, "workload_id", "09_AKSClusters")), ctx.workloads, f"AKS {cluster_id}.workload_id")
        ensure_reference(str(required(cluster, "subnet_id", "09_AKSClusters")), ctx.workload_subnets, f"AKS {cluster_id}.subnet_id")

    for pool in ctx.aks_node_pools:
        if is_enabled(pool):
            ensure_reference(str(required(pool, "cluster_id", "10_AKSNodePools")), ctx.aks_clusters, "10_AKSNodePools.cluster_id")

    for ai_id, ai in ctx.ai_services.items():
        ensure_reference(str(required(ai, "workload_id", "11_AIServices")), ctx.workloads, f"AI {ai_id}.workload_id")
        ensure_reference(str(required(ai, "private_endpoint_subnet_id", "11_AIServices")), ctx.workload_subnets, f"AI {ai_id}.private_endpoint_subnet_id")
        ensure_reference(str(required(ai, "private_dns_zone_resource_group_id", "11_AIServices")), ctx.resource_groups, f"AI {ai_id}.private_dns_zone_resource_group_id")

    output_paths: set[str] = set()
    for row in generation_map:
        module_type = str(required(row, "module_type", "99_GenerationMap")).strip()
        if module_type not in MODULE_TYPES:
            raise DesignError(f"99_GenerationMap: unsupported module_type '{module_type}'")
        output_root = str(required(row, "output_root", "99_GenerationMap")).strip().replace("\\", "/")
        filename = str(row.get("output_filename") or "10-design.auto.tfvars.json").strip()
        if output_root.startswith("/") or ".." in Path(output_root).parts:
            raise DesignError(f"unsafe output_root: {output_root}")
        key = f"{output_root}/{filename}"
        if key in output_paths:
            raise DesignError(f"duplicate output path: {key}")
        output_paths.add(key)

    validate_networks(ctx)


def validate_networks(ctx: Context) -> None:
    networks: list[tuple[str, ipaddress._BaseNetwork]] = []
    for hub_id, row in ctx.hubs.items():
        networks.append((f"hub:{hub_id}", ipaddress.ip_network(str(required(row, "address_space", "03_HubNetwork")), strict=False)))
    for workload_id, row in ctx.workloads.items():
        networks.append((f"workload:{workload_id}", ipaddress.ip_network(str(required(row, "address_space", "05_Workloads")), strict=False)))
    for index, (name_a, net_a) in enumerate(networks):
        for name_b, net_b in networks[index + 1 :]:
            if net_a.overlaps(net_b):
                raise DesignError(f"CIDR overlap: {name_a} {net_a} overlaps {name_b} {net_b}")

    for row in ctx.hub_subnets:
        if not is_enabled(row):
            continue
        hub_id = str(required(row, "hub_id", "04_HubSubnets"))
        ensure_reference(hub_id, ctx.hubs, "04_HubSubnets.hub_id")
        parent = ipaddress.ip_network(str(ctx.hubs[hub_id]["address_space"]), strict=False)
        subnet = ipaddress.ip_network(str(required(row, "address_prefix", "04_HubSubnets")), strict=False)
        if not subnet.subnet_of(parent):
            raise DesignError(f"Hub subnet {subnet} is not inside {parent}")

    subnets_by_workload: dict[str, list[ipaddress._BaseNetwork]] = {}
    for subnet_id, row in ctx.workload_subnets.items():
        workload_id = str(required(row, "workload_id", "06_WorkloadSubnets"))
        ensure_reference(workload_id, ctx.workloads, "06_WorkloadSubnets.workload_id")
        parent = ipaddress.ip_network(str(ctx.workloads[workload_id]["address_space"]), strict=False)
        subnet = ipaddress.ip_network(str(required(row, "address_prefix", "06_WorkloadSubnets")), strict=False)
        if not subnet.subnet_of(parent):
            raise DesignError(f"Workload subnet {subnet_id} {subnet} is not inside {parent}")
        for other in subnets_by_workload.setdefault(workload_id, []):
            if subnet.overlaps(other):
                raise DesignError(f"Workload {workload_id}: subnet {subnet} overlaps {other}")
        subnets_by_workload[workload_id].append(subnet)

    private_ips: set[str] = set()
    for vm_id, row in ctx.vms.items():
        workload_id = str(required(row, "workload_id", "07_VMs"))
        subnet_id = str(required(row, "subnet_id", "07_VMs"))
        ensure_reference(workload_id, ctx.workloads, "07_VMs.workload_id")
        ensure_reference(subnet_id, ctx.workload_subnets, "07_VMs.subnet_id")
        if str(ctx.workload_subnets[subnet_id]["workload_id"]) != workload_id:
            raise DesignError(f"VM {vm_id}: subnet {subnet_id} belongs to another workload")
        ip_text = str(required(row, "private_ip", "07_VMs"))
        ip = ipaddress.ip_address(ip_text)
        subnet = ipaddress.ip_network(str(ctx.workload_subnets[subnet_id]["address_prefix"]), strict=False)
        if ip not in subnet:
            raise DesignError(f"VM {vm_id}: IP {ip} is not inside subnet {subnet}")
        if ip_text in private_ips:
            raise DesignError(f"duplicate private IP: {ip_text}")
        private_ips.add(ip_text)
