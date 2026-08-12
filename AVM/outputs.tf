output "resource_group_name" {
  description = "The name of the resource group."
  value       = module.resource_group.name
}

output "resource_group_location" {
  description = "The Azure region of the resource group."
  value       = module.resource_group.location
}

output "virtual_network_name" {
  description = "The name of the virtual network."
  value       = module.virtual_network.name
}

output "subnet_name" {
  description = "The name of the primary subnet."
  value       = module.virtual_network.subnets["primary"].name
}

output "storage_account_name" {
  description = "The name of the storage account."
  value       = module.storage_account.name
}

output "storage_container_name" {
  description = "The name of the primary blob container."
  value       = module.storage_account.containers["primary"].name
}

output "linux_virtual_machine_ids" {
  description = "Map of Linux virtual machine resource IDs."
  value = {
    for key, vm in module.linux_virtual_machine :
    key => try(vm.virtual_machine_azurerm.id, null)
  }
}

output "windows_virtual_machine_ids" {
  description = "Map of Windows virtual machine resource IDs."
  value = {
    for key, vm in module.windows_virtual_machine :
    key => try(vm.virtual_machine_azurerm.id, null)
  }
}

output "virtual_machine_ids" {
  description = "Combined map of all virtual machine resource IDs."
  value = merge(
    {
      for key, vm in module.linux_virtual_machine :
      key => try(vm.virtual_machine_azurerm.id, null)
    },
    {
      for key, vm in module.windows_virtual_machine :
      key => try(vm.virtual_machine_azurerm.id, null)
    }
  )
}

output "virtual_machine_private_ip_addresses" {
  description = "Combined map of all primary private IP addresses."
  value = merge(
    {
      for key, vm in module.linux_virtual_machine :
      key => try(vm.virtual_machine_azurerm.private_ip_address, null)
    },
    {
      for key, vm in module.windows_virtual_machine :
      key => try(vm.virtual_machine_azurerm.private_ip_address, null)
    }
  )
}

output "virtual_machine_names" {
  description = "Map of virtual machine names."
  value = {
    for key, vm in local.virtual_machines :
    key => vm.name
  }
}
