# Crear Grupo de Recursos
resource "azurerm_resource_group" "my_resource_group" {
  name     = "GR_Server"
  location = var.resource_group_location
}

# Crear Red Virtual
resource "azurerm_virtual_network" "my_virtual_network" {
  name                = "Vnet-Mario"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.my_resource_group.location
  resource_group_name = azurerm_resource_group.my_resource_group.name
}

# Crear Subred
resource "azurerm_subnet" "my_subnet" {
  name                 = "Subnet-Mario"
  resource_group_name  = azurerm_resource_group.my_resource_group.name
  virtual_network_name = azurerm_virtual_network.my_virtual_network.name
  address_prefixes     = ["10.0.0.0/24"]
}

# Crear Grupo de Seguridad
resource "azurerm_network_security_group" "my_nsg" {
  name                = "NSG-Mario"
  location            = azurerm_resource_group.my_resource_group.location
  resource_group_name = azurerm_resource_group.my_resource_group.name

  security_rule {
    name                       = "web-http"
    priority                   = 1000
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "10.0.0.0/24"
  }

  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "web-https"
    priority                   = 1020
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "10.0.0.0/24"
  }

  security_rule {
    name                       = "grafana"
    priority                   = 1040
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3000"
    source_address_prefix      = "*"
    destination_address_prefix = "10.0.0.0/24"
  }
}

# Asociar el Grupo de Seguridad a la Subred
resource "azurerm_subnet_network_security_group_association" "my_nsg_association" {
  subnet_id                 = azurerm_subnet.my_subnet.id
  network_security_group_id = azurerm_network_security_group.my_nsg.id
}

# Crear una IP Pública para cada VM
resource "azurerm_public_ip" "my_vm_public_ip" {
  count               = 2
  name                = "IPpublic-Mario-${count.index}"
  location            = azurerm_resource_group.my_resource_group.location
  resource_group_name = azurerm_resource_group.my_resource_group.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

# Crear Interfaz de Red
resource "azurerm_network_interface" "my_nic" {
  count               = 2
  name                = "${var.network_interface_name}${count.index}"
  location            = azurerm_resource_group.my_resource_group.location
  resource_group_name = azurerm_resource_group.my_resource_group.name

  ip_configuration {
    name                          = "ipconfig${count.index}"
    subnet_id                     = azurerm_subnet.my_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = element(azurerm_public_ip.my_vm_public_ip.*.id, count.index)
    primary                       = true
  }
}

# Crear Máquina Virtual
resource "azurerm_linux_virtual_machine" "my_vm" {
  count                 = 2
  name                  = "Server-Mario-${count.index}"
  location              = azurerm_resource_group.my_resource_group.location
  resource_group_name   = azurerm_resource_group.my_resource_group.name
  network_interface_ids = [element(azurerm_network_interface.my_nic.*.id, count.index)]
  size                  = "Standard_DS1_v2"

  os_disk {
    name                 = "osdisk-Mario-${count.index}"
    caching              = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts-gen2"
    version   = "latest"
  }

  admin_username                  = "mario"
  disable_password_authentication = true

  admin_ssh_key {
    username   = "mario"
    public_key = var.ssh_public_key
  }
}

# Crear IP Pública del Balanceador de Carga
resource "azurerm_public_ip" "my_lb_public_ip" {
  name                = "public-ip-lb-Mario"
  location            = azurerm_resource_group.my_resource_group.location
  resource_group_name = azurerm_resource_group.my_resource_group.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

# Crear Balanceador de Carga Público
resource "azurerm_lb" "my_lb" {
  name                = "LoadBalancer-Mario"
  location            = azurerm_resource_group.my_resource_group.location
  resource_group_name = azurerm_resource_group.my_resource_group.name
  sku                 = "Standard"

  frontend_ip_configuration {
    name                 = "Ipconf-Front-Mario"
    public_ip_address_id = azurerm_public_ip.my_lb_public_ip.id
  }
}

# Crear grupo de back-end del Balanceador de Carga
resource "azurerm_lb_backend_address_pool" "my_lb_pool" {
  loadbalancer_id = azurerm_lb.my_lb.id
  name            = "Ip-Back-Mario"
}

# Asociar cada NIC al grupo de back-end del Balanceador de Carga
resource "azurerm_network_interface_backend_address_pool_association" "nic_to_backend_pool" {
  count                   = 2
  network_interface_id    = azurerm_network_interface.my_nic[count.index].id
  ip_configuration_name   = "ipconfig${count.index}"
  backend_address_pool_id = azurerm_lb_backend_address_pool.my_lb_pool.id
}

# Crear Sondas
resource "azurerm_lb_probe" "https_probe" {
  resource_group_name = azurerm_resource_group.my_resource_group.name
  loadbalancer_id     = azurerm_lb.my_lb.id
  name                = "https-probe"
  protocol            = "Https"
  port                = 443
  request_path        = "/"
  interval_in_seconds = 5
  number_of_probes    = 2
}

resource "azurerm_lb_probe" "http_probe" {
  resource_group_name = azurerm_resource_group.my_resource_group.name
  loadbalancer_id     = azurerm_lb.my_lb.id
  name                = "http-probe"
  protocol            = "Http"
  port                = 80
  request_path        = "/"
  interval_in_seconds = 5
  number_of_probes    = 2
}

# Crear Reglas de Balanceo de Carga
resource "azurerm_lb_rule" "https_rule" {
  resource_group_name            = azurerm_resource_group.my_resource_group.name
  loadbalancer_id                = azurerm_lb.my_lb.id
  name                           = "https-rule"
  protocol                       = "Tcp"
  frontend_port                  = 443
  backend_port                   = 443
  enable_floating_ip             = false
  frontend_ip_configuration_name = "Ipconf-Front-Mario"
  probe_id                       = azurerm_lb_probe.https_probe.id
  backend_address_pool_ids        = [azurerm_lb_backend_address_pool.my_lb_pool.id]
}

resource "azurerm_lb_rule" "http_rule" {
  resource_group_name            = azurerm_resource_group.my_resource_group.name
  loadbalancer_id                = azurerm_lb.my_lb.id
  name                           = "http-rule"
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  enable_floating_ip             = false
  frontend_ip_configuration_name = "Ipconf-Front-Mario"
  probe_id                       = azurerm_lb_probe.http_probe.id
  backend_address_pool_ids        = [azurerm_lb_backend_address_pool.my_lb_pool.id]
}
