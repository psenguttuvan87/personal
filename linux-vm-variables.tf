################################
## Azure Linux VM - Variables ##
################################

variable "linux_vm_size" {
  type        = string
  description = "Size (SKU) of the virtual machine to create"
}

variable "linux_admin_username" {
  type        = string
  description = "Username for Virtual Machine administrator account"
  default     = ""
}

variable "linux_admin_password" {
  type        = string
  description = "Password for Virtual Machine administrator account"
  default     = ""
}

variable "linux_client_name" {
  type        = string
  description = "Client name for Virtual Machine"
  default     = ""
}

variable "linux_environment" {
  type       = string
  description = "Provisioning Environment for Virtual Machine"
  default     = "dev"
}