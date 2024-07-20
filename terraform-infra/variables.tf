variable "resource_group_location" {
  description = "Localización del Grupo de Recursos Creado"
  type        = string
  default     = "West Europe"
}

variable "network_interface_name" {
  description = "Prefijo para nombres de interfaces de red"
  type        = string
  default     = "NIC-Mario"
}

variable "ssh_public_key" {
  description = "Clave SSH para acceder a las VMs"
  type        = string
}
