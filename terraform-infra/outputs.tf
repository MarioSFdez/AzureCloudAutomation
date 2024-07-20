output "IPs_VM" {
  value       = [for ip in azurerm_public_ip.my_vm_public_ip : ip.ip_address]
  description = "Lista de las IP públicas asignadas a las VMs"
}

output "IP_Balanceador_Carga" {
  value       = azurerm_public_ip.my_lb_public_ip.ip_address
  description = "IP pública del Balanceador de Carga"
}
