variable "client_id" {}
variable "client_secret" {}
variable "ssh_public_key" {}

variable "agent_count" {
  default = 3
}

variable "dns_prefix" {
  default = "k8s"
}

variable cluster_name {
  default = "k8scluster"
}

variable resource_group_name {
  default = "k8s-rg"
}

variable location {
  default = "East US"
}