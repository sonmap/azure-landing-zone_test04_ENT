locals {
  inventory_lines = flatten([
    for group_name, hosts in var.groups : concat(
      ["[${group_name}]"],
      [for h in hosts : "${h.name} ansible_host=${h.ip} ansible_user=${h.ansible_user}"],
      [""]
    )
  ])
}

resource "local_file" "inventory" {
  filename = var.output_path
  content  = join("\n", concat(local.inventory_lines, ["[all:vars]", "ansible_ssh_common_args='-o StrictHostKeyChecking=no'", ""]))
}
