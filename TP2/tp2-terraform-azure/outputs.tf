# ============================================================
#  outputs.tf — Informations exposées après déploiement
# ============================================================

output "resource_group_name" {
  description = "Nom du Resource Group créé"
  value       = azurerm_resource_group.main.name
}

output "load_balancer_public_ip" {
  description = "IP publique du Load Balancer (point d'entrée de l'application)"
  value       = azurerm_public_ip.lb.ip_address
}

output "web_vm_public_ips" {
  description = "IP publiques des deux VM web"
  value       = azurerm_public_ip.web[*].ip_address
}

output "storage_account_name" {
  description = "Nom du Storage Account documentaire"
  value       = azurerm_storage_account.docs.name
}
