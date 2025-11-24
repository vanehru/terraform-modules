output "vm_id" {
  description = "ID of the virtual machine"
  value       = var.os_type == "Linux" ? azurerm_linux_virtual_machine.vm[0].id : azurerm_windows_virtual_machine.vm[0].id
}

output "vm_name" {
  description = "Name of the virtual machine"
  value       = var.vm_name
}

output "vm_private_ip" {
  description = "Private IP address of the VM"
  value       = azurerm_network_interface.vm_nic.private_ip_address
}

output "vm_public_ip" {
  description = "Public IP address of the VM (if enabled)"
  value       = var.enable_public_ip ? azurerm_public_ip.vm_pip[0].ip_address : null
}

output "vm_identity_principal_id" {
  description = "Principal ID of the VM's system-assigned identity"
  value       = var.os_type == "Linux" ?
    azurerm_linux_virtual_machine.vm[0].identity[0].principal_id :
    azurerm_windows_virtual_machine.vm[0].identity[0].principal_id
}

output "bastion_host_dns" {
  description = "DNS name of the Bastion host (if enabled)"
  value       = var.enable_bastion ? azurerm_bastion_host.bastion[0].dns_name : null
}

output "connection_command" {
  description = "Command to connect to the VM"
  value = var.os_type == "Linux" ? (
    var.enable_public_ip ? 
      "ssh ${var.admin_username}@${azurerm_public_ip.vm_pip[0].ip_address}" : 
      "Connect via Azure Bastion or VPN"
  ) : (
    var.enable_public_ip ? 
      "mstsc /v:${azurerm_public_ip.vm_pip[0].ip_address}" : 
      "Connect via Azure Bastion or VPN"
  )
}
