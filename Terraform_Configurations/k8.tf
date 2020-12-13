resource "azurerm_resource_group" "k8s" {
  name     = "${var.resource_group_name}"
  location = "${var.location}"
}

resource "azurerm_kubernetes_cluster" "k8s" {
  name                = "${var.cluster_name}"
  location            = "${azurerm_resource_group.k8s.location}"
  resource_group_name = "${azurerm_resource_group.k8s.name}"
  dns_prefix          = "${var.dns_prefix}"

  linux_profile {
    admin_username = "ubuntu"

    ssh_key {
      key_data = "${file("${var.ssh_public_key}")}"
    }
  }

  default_node_pool {
    name            = "agent"
    node_count      = "${var.agent_count}"
    vm_size         = "Standard_DS1_v2"
  }

  service_principal {
    client_id     = "${var.client_id}"
    client_secret = "${var.client_secret}"
  }

  tags = {
    Environment = "Development"
  }
}