# ============================================================
#  compute.tf — IP publiques, interfaces réseau et 2 VM Linux
# ============================================================

resource "azurerm_public_ip" "web" {
  count               = 2
  name                = "pip-${local.prefix}-web-${count.index + 1}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = local.common_tags
}

resource "azurerm_network_interface" "web" {
  count               = 2
  name                = "nic-${local.prefix}-web-${count.index + 1}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = local.common_tags

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.web.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.web[count.index].id
  }
}

resource "azurerm_linux_virtual_machine" "web" {
  count               = 2
  name                = "vm-${local.prefix}-web-${count.index + 1}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  size                = "Standard_B2ats_v2" # B1s indisponible sur Azure for Students (cf. TP1)
  admin_username      = var.admin_username

  network_interface_ids = [
    azurerm_network_interface.web[count.index].id
  ]

  admin_ssh_key {
    username = var.admin_username
    # pathexpand() : Terraform file() ne développe pas "~" → expansion explicite du chemin
    public_key = file(pathexpand(var.ssh_public_key_path))
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  custom_data = base64encode(templatefile("${path.module}/templates/cloud-init.yml", {
    server_index = count.index + 1
  }))

  tags = local.common_tags
}
