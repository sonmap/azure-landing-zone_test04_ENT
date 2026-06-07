output "web_private_ips" { value = { for k, v in module.web : k => v.private_ip_address } }
output "was_private_ips" { value = { for k, v in module.was : k => v.private_ip_address } }
output "internal_lb_private_ip" { value = try(azurerm_lb.web_internal[0].frontend_ip_configuration[0].private_ip_address, null) }
