provider "azurerm" {
  features {}
  subscription_id = var.azure_subscription_id
}

resource "azurerm_resource_group" "rg" {
  name     = "sing-box-vpn"
  location = "eastasia" # Hong Kong
}

resource "azurerm_virtual_network" "vnet" {
  name                = "sing-box-vpn-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "subnet1" {
  name                 = "sing-box-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_public_ip" "publicip" {
  name                = "sing-box-publicip"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  allocation_method   = "Static"
  sku                 = "Basic"
}

resource "azurerm_network_security_group" "net_sg" {
  name                = "sing-box-sg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_network_security_rule" "allow_ssh" {
  name                        = "allow-ssh"
  priority                    = 1000
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.net_sg.name
}

resource "azurerm_network_security_rule" "allow_https" {
  name                        = "allow-https"
  priority                    = 1001
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "443"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.net_sg.name
}

resource "azurerm_network_interface" "nic" {
  name                = "sing-box-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet1.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.publicip.id
  }
}

resource "azurerm_network_interface_security_group_association" "nic_nsg" {
  network_interface_id      = azurerm_network_interface.nic.id
  network_security_group_id = azurerm_network_security_group.net_sg.id
}

resource "azurerm_linux_virtual_machine" "vm" {
  name                = "sing-box"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  size                = "Standard_B1s"
  depends_on          = [azurerm_network_interface_security_group_association.nic_nsg]

  network_interface_ids = [azurerm_network_interface.nic.id]

  admin_username = "vpn"

  admin_ssh_key {
    username   = "vpn"
    public_key = file(var.ssh_public_key_path)
  }

  disable_password_authentication = true

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    // Intentionally using image default size (30 GiB) by not setting disk_size_gb
  }

  source_image_reference {
    publisher = "Debian"
    offer     = "debian-12"
    sku       = "12-gen2"
    version   = "latest"
  }

  provisioner "file" {
    source      = "../scripts/initialize-server.sh"
    destination = "/tmp/initialize-server.sh"

    connection {
      type        = "ssh"
      user        = "vpn"
      private_key = file(var.ssh_private_key_path)
      host        = azurerm_public_ip.publicip.ip_address
    }
  }

  provisioner "file" {
    source      = "../../output/server.json"
    destination = "/tmp/config.json"

    connection {
      type        = "ssh"
      user        = "vpn"
      private_key = file(var.ssh_private_key_path)
      host        = azurerm_public_ip.publicip.ip_address
    }
  }

  provisioner "remote-exec" {
    inline = [
      "sudo bash /tmp/initialize-server.sh",
      "sudo mkdir -p /etc/sing-box",
      "sudo mv /tmp/config.json /etc/sing-box/config.json",
      "sudo systemctl restart sing-box"
    ]

    connection {
      type        = "ssh"
      user        = "vpn"
      private_key = file(var.ssh_private_key_path)
      host        = azurerm_public_ip.publicip.ip_address
    }
  }
}

output "public_ip_address" {
  value = azurerm_public_ip.publicip.ip_address
}
