variable "vm_name" {
  description = "Name of the virtual machine"
  type        = string
}

variable "location" {
  description = "Azure region for the VM"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID where VM will be deployed"
  type        = string
}

variable "vm_size" {
  description = "Size of the VM (e.g., Standard_B2s, Standard_D2s_v3)"
  type        = string
  default     = "Standard_B2s"
}

variable "os_type" {
  description = "Operating system type (Linux or Windows)"
  type        = string
  default     = "Linux"
  validation {
    condition     = contains(["Linux", "Windows"], var.os_type)
    error_message = "os_type must be either Linux or Windows"
  }
}

variable "admin_username" {
  description = "Administrator username for the VM"
  type        = string
  default     = "azureadmin"
}

variable "admin_password" {
  description = "Administrator password for the VM (required for Windows, optional for Linux)"
  type        = string
  sensitive   = true
  default     = null
}

variable "ssh_key" {
  description = "SSH public key for Linux VM authentication"
  type        = string
  default     = null
}

variable "disk_type" {
  description = "OS disk type (Standard_LRS, StandardSSD_LRS, Premium_LRS)"
  type        = string
  default     = "StandardSSD_LRS"
}

variable "disk_size_gb" {
  description = "OS disk size in GB"
  type        = number
  default     = 128
}

variable "enable_public_ip" {
  description = "Enable public IP for direct internet access"
  type        = bool
  default     = false
}

variable "allowed_source_ip" {
  description = "Source IP address allowed to access VM (for RDP/SSH)"
  type        = string
  default     = "*"
}

variable "enable_bastion" {
  description = "Enable Azure Bastion for secure access"
  type        = bool
  default     = false
}

variable "virtual_network_name" {
  description = "Virtual network name (required if enable_bastion is true)"
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
