###########################
## Azure Linux VM - Main ##
###########################

# Create Security Group to access linux
resource "azurerm_network_security_group" "linux-vm-nsg" {
  depends_on=[azurerm_resource_group.network-rg]

  name                = "${lower(var.environment)}-nsg"
  location            = azurerm_resource_group.network-rg.location
  resource_group_name = azurerm_resource_group.network-rg.name

  security_rule {
    name                       = "AllowHTTP"
    description                = "Allow HTTP"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowSSH"
    description                = "Allow SSH"
    priority                   = 150
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }
  tags = {
    environment = var.environment
    client = var.client_name
    application = var.app_name
  }
}

# Associate the linux NSG with the subnet
resource "azurerm_subnet_network_security_group_association" "linux-vm-nsg-association" {
  depends_on=[azurerm_resource_group.network-rg]

  subnet_id                 = azurerm_subnet.network-subnet.id
  network_security_group_id = azurerm_network_security_group.linux-vm-nsg.id
}

# Get a Static Public IP
resource "azurerm_public_ip" "linux-vm-ip" {
  depends_on=[azurerm_resource_group.network-rg]

  name                = "${var.client_short_name}-${var.app_name}-${var.environment}-ip"
  location            = azurerm_resource_group.network-rg.location
  resource_group_name = azurerm_resource_group.network-rg.name
  allocation_method   = "Static"
  
  tags = { 
    environment = var.environment
    client = var.client_name
    application = var.app_name
   }
}

# Create Network Card for linux VM
resource "azurerm_network_interface" "linux-vm-nic" {
  depends_on=[azurerm_resource_group.network-rg]

  name                = "${var.client_short_name}-${var.app_name}-${var.environment}-nic"
  location            = azurerm_resource_group.network-rg.location
  resource_group_name = azurerm_resource_group.network-rg.name
  
  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.network-subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.linux-vm-ip.id
  }

  tags = { 
    environment = var.environment
    client = var.client_name
    application = var.app_name
  }
}

# Create Linux VM with linux server
resource "azurerm_linux_virtual_machine" "linux-vm" {
  depends_on=[azurerm_network_interface.linux-vm-nic]

  location              = azurerm_resource_group.network-rg.location
  resource_group_name   = azurerm_resource_group.network-rg.name
  name                  = "${var.client_short_name}-${var.app_name}-${var.environment}-vm"
  network_interface_ids = [azurerm_network_interface.linux-vm-nic.id]
  size                  = var.linux_vm_size

  source_image_reference {
    offer     = var.linux_vm_image_offer_22
    publisher = var.linux_vm_image_publisher
    sku       = var.ubuntu_2204_gen2_sku
    version   = "latest"
  }

  os_disk {
    name                 = "${var.client_short_name}-${var.app_name}-${var.environment}-disk"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  computer_name  = "${var.client_short_name}-${var.app_name}-${var.environment}-vm"
  admin_username = var.linux_admin_username
  admin_password = var.linux_admin_password
  custom_data    = base64encode(data.template_file.linux-vm-cloud-init.rendered)

  disable_password_authentication = false

  tags = {
    environment = var.environment
    application = var.app_name
    client = var.client_name
  }
}

# Template for bootstrapping
data "template_file" "linux-vm-cloud-init" {
  template = file("azure-user-data.sh")
}
