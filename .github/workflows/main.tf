

resource "azurerm_resource_group" "azlab" {
  name     = local.resource_group_name
  location = local.resource_location
}

resource "azurerm_virtual_network" "vnetprod" {
  name                = local.virtual_network.name
  address_space       = local.virtual_network.address_prefixes
  location            = local.resource_location
  resource_group_name = local.resource_group_name
}

resource "azurerm_subnet" "subnet1" {
  name                 = local.subnet_names[0]
  resource_group_name  = local.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnetprod.name
  address_prefixes     = [local.subnet_address_prefixes[0]]
}

resource "azurerm_subnet" "subnet2" {
  name                 = local.subnet_names[1]
  resource_group_name  = local.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnetprod.name
  address_prefixes     = [local.subnet_address_prefixes[1]]
}

resource "azurerm_network_interface" "networint" {
  name                = local.network_interface_name
  location            = local.resource_location
  resource_group_name = local.resource_group_name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet2.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id = azurerm_public_ip.webip01.id
  }
}

resource "azurerm_public_ip" "webip01" {
  name                = "webip01"
  resource_group_name = local.resource_group_name
  location            = local.resource_location
  allocation_method   = "Static"

}

resource "azurerm_network_security_group" "app_nsg" {
  name                = "app-nsg"
  location            = local.resource_location
  resource_group_name = local.resource_group_name

  security_rule {
    name                       = "AllowRDP"
    priority                   = 300
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "websubnet01_appnsg" {
  subnet_id                 = azurerm_subnet.subnet1.id
  network_security_group_id = azurerm_network_security_group.app_nsg.id
}

resource "azurerm_subnet_network_security_group_association" "appsubnet01_appnsg" {
  subnet_id                 = azurerm_subnet.subnet2.id
  network_security_group_id = azurerm_network_security_group.app_nsg.id
}

resource "azurerm_windows_virtual_machine" "windows" {
  name                = "window"
  resource_group_name = local.resource_group_name
  location            = local.resource_location
  size                = "Standard_F2"
  admin_username      = "vivek"
  admin_password      = "P@$$w0rd1234!"
  network_interface_ids = [
    azurerm_network_interface.networint.id,
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
