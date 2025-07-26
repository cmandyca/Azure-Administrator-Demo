terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.0"
    }
  }
}

provider "azurerm" {
  features {}
}

# 1. Create a Resource Group
resource "azurerm_resource_group" "rg" {
  name     = "MyDemoProject-RG"
  location = "West US 2"
}

# 2. Create a Virtual Network
resource "azurerm_virtual_network" "vnet" {
  name                = "MyDemo-VNet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

# 3. Create a Network Security Group (NSG) and an RDP Rule
resource "azurerm_network_security_group" "nsg" {
  name                = "Web-Subnet-NSG"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "AllowRDP"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }
}

# 4. Create a Subnet for the Web Server
resource "azurerm_subnet" "web_subnet" {
  name                 = "Web-Subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

# 5. Associate the NSG with the Subnet
resource "azurerm_subnet_network_security_group_association" "nsg_assoc" {
  subnet_id                 = azurerm_subnet.web_subnet.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

# 6. Create a Public IP for the Web Server
resource "azurerm_public_ip" "web_pip" {
  name                = "Web-PublicIP"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

# 7. Create a Network Interface for the Web Server
resource "azurerm_network_interface" "web_nic" {
  name                = "web-server-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.web_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.web_pip.id
  }
}

# 8. Create the Web Server Virtual Machine (Windows)
resource "azurerm_windows_virtual_machine" "web_vm" {
  name                = "Web-VM"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  size                = "Standard_B1s" # Free tier eligible
  admin_username      = "azureadmin"
  admin_password      = "_masked_password_for_demo_" # IMPORTANT: Change this to a secure password
  network_interface_ids = [
    azurerm_network_interface.web_nic.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }
}

# 9. Output the Public IP address of the Web Server
output "web_server_public_ip" {
  value = azurerm_public_ip.web_pip.ip_address
}
