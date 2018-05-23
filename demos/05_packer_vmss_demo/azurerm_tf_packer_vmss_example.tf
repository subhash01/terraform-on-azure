# This is an example of a basic Terraform configuration file that sets up a new demo resource group,
# and creates a new demo network with a virtual machine scale set using a custom image generated by
# packer in a public subnet behind a load balancer.

# IMPORTANT: Make sure subscription_id, client_id, client_secret, and tenant_id are configured!

# Configure the Azure Provider
provider "azurerm" {}

# Create a resource group
resource "azurerm_resource_group" "demo05_resource_group" {
  name     = "demo05_resource_group"
  location = "westus2"

  tags {
    environment = "demo"
    build       = "demo05"
  }
}

/*
# Create a virtual network within the resource group
resource "azurerm_virtual_network" "demo05_network" {
  name                = "demo05_network"
  address_space       = ["10.0.0.0/16"]
  location            = "${azurerm_resource_group.demo05_resource_group.location}"
  resource_group_name = "${azurerm_resource_group.demo05_resource_group.name}"

  subnet {
    name           = "demo05_public_subnet"
    address_prefix = "10.0.1.0/24"
  }

  subnet {
    name           = "demo05_private_subnet"
    address_prefix = "10.0.2.0/24"
  }

  tags {
    environment = "demo"
    build       = "demo05"
  }
}
*/
module "network" "demo05_network" {
  source              = "Azure/network/azurerm"
  resource_group_name = "${azurerm_resource_group.demo05_resource_group.name}"
  location            = "${azurerm_resource_group.demo05_resource_group.location}"
  address_space       = "10.0.0.0/16"
  subnet_prefixes     = ["10.0.1.0/24", "10.0.2.0/24"]
  subnet_names        = ["demo05_public_subnet", "demo05_private_subnet"]
  vnet_name           = "demo05_network"

  tags {
    environment = "demo"
    build       = "demo05"
  }
}

resource "azurerm_subnet" "demo05_public_subnet" {
  name                      = "demo05_public_subnet"
  address_prefix            = "10.0.1.0/24"
  resource_group_name       = "${azurerm_resource_group.demo05_resource_group.name}"
  virtual_network_name      = "demo05_network"
  network_security_group_id = "${azurerm_network_security_group.demo05_public_security_group.id}"
}

resource "azurerm_network_security_group" "demo05_public_security_group" {
  depends_on          = ["module.network"]
  name                = "demo05_public_security_group"
  location            = "${azurerm_resource_group.demo05_resource_group.location}"
  resource_group_name = "${azurerm_resource_group.demo05_resource_group.name}"

  security_rule {
    name                       = "demo05_allow_web"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags {
    environment = "demo"
    build       = "demo05"
  }
}

/*
resource "azurerm_network_interface" "demo05_network_interface" {
  name                      = "demo05_network_interface"
  location                  = "${azurerm_resource_group.demo05_resource_group.location}"
  resource_group_name       = "${azurerm_resource_group.demo05_resource_group.name}"
  network_security_group_id = "${azurerm_network_security_group.demo05_public_security_group.id}"

  ip_configuration {
    name                                    = "demo05_ip_configuration"
    subnet_id                               = "${azurerm_subnet.demo05_public_subnet.id}"
    private_ip_address_allocation           = "dynamic"
    load_balancer_backend_address_pools_ids = ["${module.loadbalancer.azurerm_lb_backend_address_pool_id}"]
  }

  tags {
    environment = "demo"
    build       = "demo05"
  }
}

resource "azurerm_managed_disk" "demo05_managed_disk" {
  name                 = "demo05_managed_disk"
  location             = "${azurerm_resource_group.demo05_resource_group.location}"
  resource_group_name  = "${azurerm_resource_group.demo05_resource_group.name}"
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = "1023"

  tags {
    environment = "demo"
    build       = "demo05"
  }
}

resource "azurerm_virtual_machine" "demo05_web01" {
  name                  = "demo05_web01"
  location              = "${azurerm_resource_group.demo05_resource_group.location}"
  resource_group_name   = "${azurerm_resource_group.demo05_resource_group.name}"
  network_interface_ids = ["${azurerm_network_interface.demo05_network_interface.id}"]
  vm_size               = "Standard_B1s"

  # Uncomment this line to delete the OS disk automatically when deleting the VM
  delete_os_disk_on_termination = true

  # Uncomment this line to delete the data disks automatically when deleting the VM
  delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }

  storage_os_disk {
    name              = "demo05_storage_os_disk1"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
 
  storage_data_disk {
    name            = "${azurerm_managed_disk.demo05_managed_disk.name}"
    managed_disk_id = "${azurerm_managed_disk.demo05_managed_disk.id}"
    create_option   = "Attach"
    lun             = 1
    disk_size_gb    = "${azurerm_managed_disk.demo05_managed_disk.disk_size_gb}"
  }

  os_profile {
    computer_name  = "demo05web01"
    admin_username = "testadmin"
    admin_password = "Password1234!"
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }

  tags {
    environment = "demo"
    build       = "demo05"
  }
}

resource "azurerm_virtual_machine_extension" "demo05_web_build" {
  name                 = "demo05_web_build"
  location             = "${azurerm_resource_group.demo05_resource_group.location}"
  resource_group_name  = "${azurerm_resource_group.demo05_resource_group.name}"
  virtual_machine_name = "${azurerm_virtual_machine.demo05_web01.name}"
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.0"

  settings = <<SETTINGS
    {
        "commandToExecute": "sudo apt-get update -y && sudo apt-get install nginx -y"
    }
SETTINGS

  tags {
    environment = "demo"
    build       = "demo05"
  }
} */

module "loadbalancer" "demo05_load_balancer" {
  source              = "Azure/loadbalancer/azurerm"
  resource_group_name = "${azurerm_resource_group.demo05_resource_group.name}"
  location            = "${azurerm_resource_group.demo05_resource_group.location}"
  prefix              = "demo05"

  lb_port = {
    http = ["80", "Tcp", "8080"]
  }

  frontend_name = "demo05-public-vip"

  tags {
    environment = "demo"
    build       = "demo05"
  }
}

module "computegroup" "demo05_computegroup" {
  source                                 = "Azure/computegroup/azurerm"
  vmscaleset_name                        = "demo05_vmscaleset"
  resource_group_name                    = "${azurerm_resource_group.demo05_resource_group.name}"
  location                               = "${azurerm_resource_group.demo05_resource_group.location}"
  vm_size                                = "Standard_B1S"
  admin_username                         = "azureuser"
  admin_password                         = "BestPasswordEver"
  ssh_key                                = "~/.ssh/id_rsa.pub"
  nb_instance                            = 4
  vnet_subnet_id                         = "${module.network.vnet_subnets[0]}"
  load_balancer_backend_address_pool_ids = "${module.loadbalancer.azurerm_lb_backend_address_pool_id}"

  #vm_os_simple                           = "UbuntuServer"

  # Using the custom packer-todo-demo image I created from the 'demo_image.json' file using Packer
  vm_os_id = "/subscriptions/d7e02429-9aef-419e-b1e3-a9ca66b40864/resourceGroups/PACKERDEMO/providers/Microsoft.Compute/images/packer-todo-demo"
  tags = {
    environment = "demo"
    build       = "demo05"
  }
}

output "azurerm_public_ip_address" {
  value = "${module.loadbalancer.azurerm_public_ip_address}"
}
