from __future__ import annotations

from typing import Any

from .common import (
    Context, DesignError, as_bool, as_int, common_tags, ensure_reference, image_for,
    is_enabled, required, row_tags, split_list, vm_bucket, vnet_id,
)


def rg_name(ctx: Context, resource_group_id: str) -> str:
    ensure_reference(resource_group_id, ctx.resource_groups, "resource_group_id")
    return str(ctx.resource_groups[resource_group_id]["name"])


def hub_vnet_resource_id(ctx: Context, hub_id: str) -> str:
    hub = ctx.hubs[hub_id]
    return vnet_id(
        str(ctx.global_values["subscription_id"]),
        rg_name(ctx, str(hub["resource_group_id"])),
        str(hub["vnet_name"]),
    )


def build_resource_groups(ctx: Context, source_key: str) -> dict[str, Any]:
    base = common_tags(ctx.global_values)
    groups = {
        rg_id: {
            "name": str(row["name"]),
            "location": str(row.get("location") or ctx.global_values.get("default_location", "koreacentral")),
            "tags": row_tags(row, base),
        }
        for rg_id, row in ctx.resource_groups.items()
    }
    return {
        "tenant_id": str(ctx.global_values["tenant_id"]),
        "subscription_id": str(ctx.global_values["subscription_id"]),
        "location": str(ctx.global_values.get("default_location", "koreacentral")),
        "common_tags": base,
        "resource_groups": groups,
    }


def build_hub_network(ctx: Context, hub_id: str) -> dict[str, Any]:
    ensure_reference(hub_id, ctx.hubs, "hub_network source_key")
    hub = ctx.hubs[hub_id]
    subnet_rows = [r for r in ctx.hub_subnets if is_enabled(r) and str(r.get("hub_id")) == hub_id]
    subnets = {
        str(r["subnet_id"]): {
            "name": str(r["name"]),
            "address_prefixes": [str(r["address_prefix"])],
            "create_nsg": as_bool(r.get("create_nsg")),
            "delegate_dns_resolver": as_bool(r.get("delegate_dns_resolver")),
        }
        for r in subnet_rows
    }
    return {
        "tenant_id": str(ctx.global_values["tenant_id"]),
        "subscription_id": str(ctx.global_values["subscription_id"]),
        "location": str(hub.get("location") or ctx.global_values.get("default_location", "koreacentral")),
        "resource_group_name": rg_name(ctx, str(hub["resource_group_id"])),
        "hub_name": str(hub["vnet_name"]),
        "address_space": [str(hub["address_space"])],
        "dns_servers": split_list(hub.get("dns_servers")),
        "subnets": subnets,
        "enable_private_dns_resolver": as_bool(hub.get("enable_private_dns_resolver"), True),
        "dns_inbound_subnet_key": str(hub["dns_inbound_subnet_id"]),
        "dns_outbound_subnet_key": str(hub["dns_outbound_subnet_id"]),
        "common_tags": common_tags(ctx.global_values),
    }


def build_workload_spoke(ctx: Context, workload_id: str) -> dict[str, Any]:
    ensure_reference(workload_id, ctx.workloads, "workload_spoke source_key")
    workload = ctx.workloads[workload_id]
    hub_id = str(workload["hub_id"])
    hub = ctx.hubs[hub_id]
    subnet_rows = [r for r in ctx.workload_subnets.values() if str(r.get("workload_id")) == workload_id]
    subnets = {
        str(r["subnet_id"]): {
            "name": str(r["name"]),
            "address_prefixes": [str(r["address_prefix"])],
            "create_nsg": as_bool(r.get("create_nsg"), True),
            "associate_route_table": as_bool(r.get("associate_route_table"), True),
            "private_endpoint_network_policies": str(r.get("private_endpoint_network_policies") or "Enabled"),
        }
        for r in subnet_rows
    }
    return {
        "tenant_id": str(ctx.global_values["tenant_id"]),
        "subscription_id": str(ctx.global_values["subscription_id"]),
        "location": str(workload.get("location") or ctx.global_values.get("default_location", "koreacentral")),
        "common_tags": row_tags(workload, common_tags(ctx.global_values)),
        "resource_group_name": rg_name(ctx, str(workload["resource_group_id"])),
        "spoke_name": str(workload["vnet_name"]),
        "address_space": [str(workload["address_space"])],
        "dns_servers": split_list(workload.get("dns_servers")),
        "hub_vnet_id": hub_vnet_resource_id(ctx, hub_id),
        "hub_resource_group_name": rg_name(ctx, str(hub["resource_group_id"])),
        "hub_vnet_name": str(hub["vnet_name"]),
        "firewall_private_ip": str(ctx.global_values.get("firewall_private_ip", "")),
        "subnets": subnets,
    }


def build_vm(ctx: Context, workload_id: str) -> dict[str, Any]:
    ensure_reference(workload_id, ctx.workloads, "vm source_key")
    workload = ctx.workloads[workload_id]
    vm_rows = [(vm_id, row) for vm_id, row in ctx.vms.items() if str(row.get("workload_id")) == workload_id]
    if not vm_rows:
        raise DesignError(f"no enabled VM rows for workload '{workload_id}'")
    os_profiles = {str(row.get("os") or "RHEL9").lower() for _, row in vm_rows}
    admin_users = {str(row.get("admin_username") or "azureuser") for _, row in vm_rows}
    if len(os_profiles) != 1:
        raise DesignError(f"VM root '{workload_id}' contains mixed OS families; split them into separate roots")
    if len(admin_users) != 1:
        raise DesignError(f"VM root '{workload_id}' contains multiple admin_username values")

    disks_by_vm: dict[str, dict[str, Any]] = {}
    lun_by_vm: dict[str, set[int]] = {}
    for disk in ctx.vm_disks:
        if not is_enabled(disk):
            continue
        vm_id = str(disk["vm_id"])
        if vm_id not in ctx.vms or str(ctx.vms[vm_id].get("workload_id")) != workload_id:
            continue
        lun = as_int(disk.get("lun"), f"disk {disk.get('disk_id')}.lun")
        if lun in lun_by_vm.setdefault(vm_id, set()):
            raise DesignError(f"VM {vm_id}: duplicate LUN {lun}")
        lun_by_vm[vm_id].add(lun)
        name = str(required(disk, "disk_name", "08_VMDisks"))
        disks_by_vm.setdefault(vm_id, {})[name] = {
            "size_gb": as_int(disk.get("size_gb"), f"disk {name}.size_gb"),
            "storage_account_type": str(disk.get("storage_type") or "Premium_LRS"),
            "lun": lun,
            "caching": str(disk.get("caching") or "None"),
        }

    buckets: dict[str, dict[str, Any]] = {"web_vms": {}, "was_vms": {}, "db_vms": {}, "agent_vms": {}}
    for vm_id, row in vm_rows:
        subnet_id = str(row["subnet_id"])
        buckets[vm_bucket(row.get("role"))][vm_id] = {
            "name": str(row["vm_name"]),
            "subnet_name": str(ctx.workload_subnets[subnet_id]["name"]),
            "private_ip_address": str(row["private_ip"]),
            "vm_size": str(row["vm_size"]),
            "os_disk_size_gb": as_int(row.get("os_disk_gb"), f"VM {vm_id}.os_disk_gb"),
            "role": str(row.get("role") or "agent"),
            "itsm_ticket": str(row.get("itsm_ticket") or ""),
            "data_disks": disks_by_vm.get(vm_id, {}),
        }

    return {
        "resource_group_name": rg_name(ctx, str(workload["resource_group_id"])),
        "location": str(workload.get("location") or ctx.global_values.get("default_location", "koreacentral")),
        "vnet_resource_group_name": rg_name(ctx, str(workload["resource_group_id"])),
        "vnet_name": str(workload["vnet_name"]),
        "admin_username": next(iter(admin_users)),
        "ssh_public_key": str(ctx.global_values["ssh_public_key"]),
        "image_version": "latest",
        "os_disk_storage_type": "Premium_LRS",
        "common_tags": row_tags(workload, common_tags(ctx.global_values)),
        **image_for(next(iter(os_profiles))),
        **buckets,
    }


def node_pool_object(row: dict[str, Any]) -> dict[str, Any]:
    return {
        "name": str(row["name"]),
        "vm_size": str(row["vm_size"]),
        "node_count": as_int(row.get("node_count"), f"node pool {row.get('node_pool_id')}.node_count"),
        "auto_scaling_enabled": as_bool(row.get("auto_scaling_enabled"), True),
        "min_count": as_int(row.get("min_count"), f"node pool {row.get('node_pool_id')}.min_count"),
        "max_count": as_int(row.get("max_count"), f"node pool {row.get('node_pool_id')}.max_count"),
        "os_disk_size_gb": as_int(row.get("os_disk_size_gb"), f"node pool {row.get('node_pool_id')}.os_disk_size_gb"),
    }


def build_aks(ctx: Context, cluster_id: str) -> dict[str, Any]:
    ensure_reference(cluster_id, ctx.aks_clusters, "aks source_key")
    cluster = ctx.aks_clusters[cluster_id]
    workload = ctx.workloads[str(cluster["workload_id"])]
    subnet = ctx.workload_subnets[str(cluster["subnet_id"])]
    pool_rows = [r for r in ctx.aks_node_pools if is_enabled(r) and str(r.get("cluster_id")) == cluster_id]
    default_rows = [r for r in pool_rows if str(r.get("pool_type", "")).lower() == "default"]
    if len(default_rows) != 1:
        raise DesignError(f"AKS {cluster_id}: exactly one enabled default node pool is required")
    user_pools = {
        str(r["node_pool_id"]): {**node_pool_object(r), "mode": str(r.get("mode") or "User")}
        for r in pool_rows if str(r.get("pool_type", "")).lower() == "user"
    }
    return {
        "resource_group_name": rg_name(ctx, str(workload["resource_group_id"])),
        "location": str(workload.get("location") or ctx.global_values.get("default_location", "koreacentral")),
        "tags": row_tags(workload, common_tags(ctx.global_values)),
        "vnet_resource_group_name": rg_name(ctx, str(workload["resource_group_id"])),
        "vnet_name": str(workload["vnet_name"]),
        "aks_subnet_name": str(subnet["name"]),
        "cluster": {
            "name": str(cluster["name"]),
            "kubernetes_version": str(cluster["kubernetes_version"]),
            "dns_prefix": str(cluster["dns_prefix"]),
            "private_cluster_enabled": as_bool(cluster.get("private_cluster_enabled"), True),
            "sku_tier": str(cluster.get("sku_tier") or "Free"),
            "local_account_disabled": as_bool(cluster.get("local_account_disabled"), True),
        },
        "default_node_pool": node_pool_object(default_rows[0]),
        "user_node_pools": user_pools,
        "network_profile": {
            "network_plugin": str(cluster.get("network_plugin") or "azure"),
            "network_policy": str(cluster.get("network_policy") or "azure"),
            "service_cidr": str(cluster["service_cidr"]),
            "dns_service_ip": str(cluster["dns_service_ip"]),
            "outbound_type": str(cluster.get("outbound_type") or "userDefinedRouting"),
        },
        "monitoring": {
            "enabled": as_bool(cluster.get("monitoring_enabled"), True),
            "log_analytics_workspace_id": str(ctx.global_values["aks_log_analytics_workspace_id"]),
        },
    }


def build_ai(ctx: Context, ai_id: str) -> dict[str, Any]:
    ensure_reference(ai_id, ctx.ai_services, "ai source_key")
    ai = ctx.ai_services[ai_id]
    workload = ctx.workloads[str(ai["workload_id"])]
    subnet = ctx.workload_subnets[str(ai["private_endpoint_subnet_id"])]
    rg = rg_name(ctx, str(workload["resource_group_id"]))
    return {
        "resource_group_name": rg,
        "location": str(workload.get("location") or ctx.global_values.get("default_location", "koreacentral")),
        "tags": row_tags(workload, common_tags(ctx.global_values)),
        "vnet_resource_group_name": rg,
        "vnet_name": str(workload["vnet_name"]),
        "private_endpoint_subnet_name": str(subnet["name"]),
        "private_dns_zone_resource_group_name": rg_name(ctx, str(ai["private_dns_zone_resource_group_id"])),
        "openai": {"enabled": as_bool(ai.get("openai_enabled"), True), "name": str(ai["openai_name"]), "sku_name": str(ai.get("openai_sku") or "S0"), "public_network_access": "Disabled", "custom_subdomain_name": str(ai["openai_name"])},
        "search": {"enabled": as_bool(ai.get("search_enabled"), True), "name": str(ai["search_name"]), "sku": str(ai.get("search_sku") or "basic"), "replica_count": 1, "partition_count": 1, "public_network_access": "Disabled"},
        "storage": {"enabled": as_bool(ai.get("storage_enabled"), True), "name": str(ai["storage_name"]), "account_tier": "Standard", "account_replication_type": str(ai.get("storage_replication") or "LRS"), "public_network_access": "Disabled", "allow_blob_public_access": False, "default_action": "Deny", "containers": ["landing", "rag", "audit"]},
        "keyvault": {"enabled": as_bool(ai.get("keyvault_enabled"), True), "name": str(ai["keyvault_name"]), "sku_name": "standard", "tenant_id": str(ctx.global_values["tenant_id"]), "public_network_access": "Disabled", "purge_protection": as_bool(ai.get("purge_protection"), True)},
        "private_endpoints": {"openai": True, "search": True, "blob": True, "keyvault": True},
        "private_dns_zones": {"openai": "privatelink.openai.azure.com", "search": "privatelink.search.windows.net", "blob": "privatelink.blob.core.windows.net", "keyvault": "privatelink.vaultcore.azure.net"},
    }


def build_private_dns_zones(ctx: Context, dns_set_id: str) -> dict[str, Any]:
    rows_ = [r for r in ctx.private_dns_rows if is_enabled(r) and str(r.get("dns_set_id")) == dns_set_id]
    if not rows_:
        raise DesignError(f"no Private DNS rows for source_key '{dns_set_id}'")
    resource_group_ids = {str(r["resource_group_id"]) for r in rows_}
    if len(resource_group_ids) != 1:
        raise DesignError(f"Private DNS set {dns_set_id}: multiple resource groups are not supported in one root")
    links: dict[str, Any] = {}
    zones: set[str] = set()
    for row in rows_:
        zone_name = str(row["zone_name"])
        zones.add(zone_name)
        hub_id = str(row["hub_id"])
        ensure_reference(hub_id, ctx.hubs, "12_PrivateDNSZones.hub_id")
        links[str(row["link_id"])] = {"zone_name": zone_name, "name": str(row["link_name"]), "virtual_network_id": hub_vnet_resource_id(ctx, hub_id), "registration_enabled": as_bool(row.get("registration_enabled"), False)}
    return {
        "tenant_id": str(ctx.global_values["tenant_id"]),
        "subscription_id": str(ctx.global_values["subscription_id"]),
        "resource_group_name": rg_name(ctx, next(iter(resource_group_ids))),
        "zones": sorted(zones),
        "virtual_network_links": links,
        "common_tags": common_tags(ctx.global_values),
    }


BUILDERS = {
    "resource_groups": build_resource_groups,
    "hub_network": build_hub_network,
    "workload_spoke": build_workload_spoke,
    "vm": build_vm,
    "aks": build_aks,
    "ai": build_ai,
    "private_dns_zones": build_private_dns_zones,
}
