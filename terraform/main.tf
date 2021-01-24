## Confirm that you are using azurevm provider version 2.0 to get the azurerm_windows_virtual_machine reosurce and
## the other resources and capabilities
provider "azurerm" {
  version = "2.0.0"
  features {}
}

## To create an Azure resource group using the value of resource_group
## Variables such as Name and Location of the resource group are defined in the terraform.tfvars file.
resource "azurerm_resource_group" "cloudRG" {
  name     = var.resource_group
  location = var.location
}

## To create an availability set named cloud-as 
resource "azurerm_availability_set" "cloud-as" {
  name                = "cloud-as"
  location            = azurerm_resource_group.cloudRG.location
  resource_group_name = azurerm_resource_group.cloudRG.name
}

## To create Network Security GrouP named nsg to filter the traffic at resources 
resource "azurerm_network_security_group" "cloudnsg" {
  name                = "nsg"
  location            = azurerm_resource_group.cloudRG.location
  resource_group_name = azurerm_resource_group.cloudRG.name
  
## Rule which allows Ansible to connect to the Virtual Machines from Azure Cloud Shell
## source_address_prefix will be the IP Azure Cloud Shell is defined in variables file 
  security_rule {
    name                       = "allowWinRm"
    priority                   = 101
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5986"
    source_address_prefix      = var.cloud_shell_source
    destination_address_prefix = "*"
  }
  
## Rule for allowing Visual Studio installed on local machine to connect with the web management service to deploy app
  security_rule {
    name                       = "allowWebDeploy"
    priority                   = 102
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8172"
    source_address_prefix      = var.management_ip
    destination_address_prefix = "*"
  }
  
##Rule for allowing web clients to connect to our web application
  security_rule {
    name                       = "allowPublicWeb"
    priority                   = 103
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  
## Rule for in case we require RDP to the VMs for troubleshooting
  security_rule {
    name                       = "allowRDP"
    priority                   = 104
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = var.management_ip
    destination_address_prefix = "*"
  }
}

## Create a vNet
resource "azurerm_virtual_network" "main" {
  name                = "cloud-network"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.cloudRG.location
  resource_group_name = azurerm_resource_group.cloudRG.name
}

## Create a subnet inside of the vNet 
resource "azurerm_subnet" "internal" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.cloudRG.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefix       = "10.0.2.0/24"

  depends_on = [
    azurerm_virtual_network.main
  ]
}

## Assign public IP to the load balancer so that client applications will connect to the web app. 
## IP should be static else IP will not be assigned.
resource "azurerm_public_ip" "lbIp" {
  name                    = "publicLbIp"
  location                = azurerm_resource_group.cloudRG.location
  resource_group_name     = azurerm_resource_group.cloudRG.name
  allocation_method       = "Static"
}

## You'll need public IPs for each VM for Ansible to connect to and to deploy the web app to.
resource "azurerm_public_ip" "vmIps" {
  count                   = 2
  name                    = "publicVmIp-${count.index}"
  location                = azurerm_resource_group.cloudRG.location
  resource_group_name     = azurerm_resource_group.cloudRG.name
  allocation_method       = "Dynamic"
  domain_name_label       = "${var.domain_name_prefix}-${count.index}"
}

## to create Network Interface Cards for each Virtual Machine
resource "azurerm_network_interface" "main" {
  count               = 2
  name                = "cloud-nic-${count.index}"
  location            = azurerm_resource_group.cloudRG.location
  resource_group_name = azurerm_resource_group.cloudRG.name
  
## IP configuration for each Network Interface Card
  ip_configuration {
    name                          = "ip_config"
    subnet_id                     = azurerm_subnet.internal.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.vmIps[count.index].id
  }
  
##  Create Resource dependancy such that subnet is created before creating vNics.
  depends_on = [
    azurerm_subnet.internal
  ]
}
		
## Associate the NSG to Virtual Machines and NICs 
resource "azurerm_network_interface_security_group_association" "nsg" {
  count                     = 2
  network_interface_id      = azurerm_network_interface.main[count.index].id
  network_security_group_id = azurerm_network_security_group.cloudnsg.id
}

## Load balancer frontend configuration using the public IP address created in previous steps.
resource "azurerm_lb" "LB" {
 name                = "nobsloadbalancer"
 location            = azurerm_resource_group.cloudRG.location
 resource_group_name = azurerm_resource_group.cloudRG.name

 frontend_ip_configuration {
   name                 = "lb_frontend"
   public_ip_address_id = azurerm_public_ip.lbIp.id
 }
}

## Load balancer backend configuration
resource "azurerm_lb_backend_address_pool" "be_pool" {
 resource_group_name = azurerm_resource_group.cloudRG.name
 loadbalancer_id     = azurerm_lb.LB.id
 name                = "BackEndAddressPool"
}

## Assign both NICs and VMs to backend of Load balancer
resource "azurerm_network_interface_backend_address_pool_association" "be_assoc" {
  count                   = 2
  network_interface_id    = azurerm_network_interface.main[count.index].id
  ip_configuration_name   = "ip_config"
  backend_address_pool_id = azurerm_lb_backend_address_pool.be_pool.id
}

## Create a health probe load balancer 
resource "azurerm_lb_probe" "lbprobe" {
  resource_group_name = azurerm_resource_group.cloudRG.name
  loadbalancer_id     = azurerm_lb.LB.id
  name                = "http-running-probe"
  port                = 80
}
## Directt traffic to load balancer backend
resource "azurerm_lb_rule" "lbrule" {
  resource_group_name            = azurerm_resource_group.cloudRG.name
  loadbalancer_id                = azurerm_lb.LB.id
  name                           = "LBRule"
  probe_id                       = azurerm_lb_probe.lbprobe.id
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  backend_address_pool_id        = azurerm_lb_backend_address_pool.be_pool.id
  frontend_ip_configuration_name = "lb_frontend"
}

## Associate VMs and vNIcs created earier
resource "azurerm_windows_virtual_machine" "cloudVMs" {
  count                 = 2
  name                  = "cloudvm-${count.index}"
  location              = var.location
  resource_group_name   = azurerm_resource_group.cloudRG.name
  size                  = "Standard_DS1_v2"
  network_interface_ids = [azurerm_network_interface.main[count.index].id]
  availability_set_id   = azurerm_availability_set.cloud-as.id
  computer_name         = "cloudvm-${count.index}"
  admin_username        = "testadmin"
  admin_password        = "Password2021!"
  
  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  depends_on = [
    azurerm_network_interface.main
  ]
}

## Install the custom script VM extension at each virtual machine in the network
resource "azurerm_virtual_machine_extension" "enablewinrm" {
  count                 = 2
  name                  = "enablewinrm"
  virtual_machine_id    = azurerm_windows_virtual_machine.cloudVMs[count.index].id
  publisher            = "Microsoft.Compute" ## az vm extension image list --location eastus Do not use Microsoft.Azure.Extensions here
  type                 = "CustomScriptExtension" ## az vm extension image list --location eastus Only use CustomScriptExtension here
  type_handler_version = "1.9" ## az vm extension image list --location eastus
  auto_upgrade_minor_version = true
  settings = <<SETTINGS
    {
      "fileUris": ["https://raw.githubusercontent.com/ansible/ansible/devel/examples/scripts/ConfigureRemotingForAnsible.ps1"],
      "commandToExecute": "powershell -ExecutionPolicy Unrestricted -File ConfigureRemotingForAnsible.ps1"
    }
SETTINGS
}

output "VMIps" {
  value       = azurerm_public_ip.vmIps.*.ip_address
}

## This code will return the public ip of the load balancer. This IP address can be used to connect and test the website after the deployment.
output "Load_Balancer_IP" {
  value       = azurerm_public_ip.lbIp.ip_address
}