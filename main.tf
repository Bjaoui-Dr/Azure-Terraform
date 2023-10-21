# Azure Provider source and version being used
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.0.0"
    }
  }
}

# Configure the Microsoft Azure Provider
provider "azurerm" {
  features {
  }
}

# Configure the Ressource Group
resource "azurerm_resource_group" "mtc-rsg" {
  name     = "mtc-ressources"
  location = "East Us"
  tags = {
    environment = "dev"
  }
}

#Configure the Virtual Network
resource "azurerm_virtual_network" "mtc-vn" {
  name                = "mtc-network"
  location            = azurerm_resource_group.mtc-rsg.location
  resource_group_name = azurerm_resource_group.mtc-rsg.name
  address_space       = ["10.123.0.0/16"]

  tags = {
    environment = "dev"
  }
}

#configure the Subnet
resource "azurerm_subnet" "mtc-subnet" {
  name                 = "mtc-subnet"
  resource_group_name  = azurerm_resource_group.mtc-rsg.name
  virtual_network_name = azurerm_virtual_network.mtc-vn.name
  address_prefixes     = ["10.123.1.0/24"]
}

#Configure the Security Group
resource "azurerm_network_security_group" "mtc-sg" {
  name                = "mtc-sg"
  location            = azurerm_resource_group.mtc-rsg.location
  resource_group_name = azurerm_resource_group.mtc-rsg.name

  tags = {
    environment = "dev"
  }
}

#Configure the rules for security group
resource "azurerm_network_security_rule" "mtc-dev-rule" {
  name                        = "mtc-dev-rule"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.mtc-rsg.name
  network_security_group_name = azurerm_network_security_group.mtc-sg.name
}

#Assosing the subnet with the security group rules
resource "azurerm_subnet_network_security_group_association" "mtc-sga" {
  subnet_id                 = azurerm_subnet.mtc-subnet.id
  network_security_group_id = azurerm_network_security_group.mtc-sg.id
}

#Making public ip address
resource "azurerm_public_ip" "mtc-ip" {
  name                = "mtc-ip"
  resource_group_name = azurerm_resource_group.mtc-rsg.name
  location            = azurerm_resource_group.mtc-rsg.location
  allocation_method   = "Dynamic"

  tags = {
    environment = "dev"
  }
}

#NIC
resource "azurerm_network_interface" "mtc-nic" {
  name                = "mtc-ni-nic"
  location            = azurerm_resource_group.mtc-rsg.location
  resource_group_name = azurerm_resource_group.mtc-rsg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.mtc-subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.mtc-ip.id
  }

  tags = {
    environment = "dev"
  }
}

#VM Jenkins Server
resource "azurerm_linux_virtual_machine" "mtc-vm" {
  name                = "mtc-vm"
  resource_group_name = azurerm_resource_group.mtc-rsg.name
  location            = azurerm_resource_group.mtc-rsg.location
  size                = "Standard_B2s" 
  admin_username      = "adminuser"
  network_interface_ids = [
    azurerm_network_interface.mtc-nic.id,
  ]

  custom_data = filebase64("customdata.tpl")

  admin_ssh_key {
    username   = "adminuser"
    public_key = file("~/.ssh/mtcazurekey.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts"
    version   = "latest"
  }

  tags = {
    environment = "dev"
  }
}


#VM App Server
resource "azurerm_linux_virtual_machine" "app-server" {
  name                = "app-server"
  resource_group_name = azurerm_resource_group.mtc-rsg.name
  location            = azurerm_resource_group.mtc-rsg.location
  size                = "Standard_B2s" 
  admin_username      = "adminuser"
  network_interface_ids = [
    azurerm_network_interface.mtc-nic.id,
  ]

  custom_data = filebase64("customdata.tpl")

  admin_ssh_key {
    username   = "adminuser"
    public_key = file("~/.ssh/mtcazurekey.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts"
    version   = "latest"
  }


  tags = {
    environment = "dev"
  }
}


output "test" {
  value = "Hello World!"
}
