locals {
  generated_windows_virtual_machines = (
    var.windows_vm_config != null && var.windows_vm_config.enabled
    ? {
      for i in range(var.windows_vm_config.vm_count) :
      format("%s-%02d", var.windows_vm_config.name_prefix, i + 1) => {
        os_type       = "windows"
        name          = format("%s-%02d", var.windows_vm_config.name_prefix, i + 1)
        computer_name = format("%s-%02d", var.windows_vm_config.name_prefix, i + 1)
        zone          = try(var.windows_vm_config.zone, null)
        sku_size      = var.windows_vm_config.sku_size
        patch_mode    = try(var.windows_vm_config.patch_mode, null)
        enable_automatic_updates = coalesce(
          try(var.windows_vm_config.enable_automatic_updates, null),
          try(var.windows_vm_config.patch_mode, null) == "Manual" ? false : true
        )
        account_credentials    = var.windows_vm_config.account_credentials
        source_image_reference = var.windows_vm_config.source_image_reference
        os_disk                = try(var.windows_vm_config.os_disk, {})
        tags                   = try(var.windows_vm_config.tags, {})
      }
    }
    : {}
  )

  virtual_machines_input = merge(
    var.virtual_machines,
    local.generated_windows_virtual_machines
  )

  virtual_machines = {
    for key, vm in local.virtual_machines_input :
    key => merge(vm, {
      os_type = lower(vm.os_type)
      name    = try(vm.name, key)
      zone    = try(vm.zone, null)
    })
  }

  linux_virtual_machines = {
    for key, vm in local.virtual_machines :
    key => vm if vm.os_type == "linux"
  }

  windows_virtual_machines = {
    for key, vm in local.virtual_machines :
    key => vm if vm.os_type == "windows"
  }
}

module "resource_group" {
  source  = "Azure/avm-res-resources-resourcegroup/azurerm"
  version = "0.4.0"

  name     = var.resource_group_name
  location = var.location

  enable_telemetry = false
  tags             = var.tags
}

module "virtual_network" {
  source  = "Azure/avm-res-network-virtualnetwork/azurerm"
  version = "0.8.1"

  name                = var.virtual_network_name
  location            = var.location
  resource_group_name = module.resource_group.name
  address_space       = var.virtual_network_address_space

  enable_telemetry = false

  subnets = {
    primary = {
      name             = var.subnet_name
      address_prefixes = var.subnet_address_prefixes
    }
  }

  tags = var.tags
}

module "storage_account" {
  source  = "Azure/avm-res-storage-storageaccount/azurerm"
  version = "0.7.3"

  name      = var.storage_account_name
  location  = var.location
  parent_id = module.resource_group.resource_id

  enable_telemetry = false

  account_kind             = "StorageV2"
  account_tier             = "Standard"
  account_replication_type = "LRS"
  access_tier              = "Hot"

  containers = {
    primary = {
      name = var.storage_container_name
    }
  }

  tags = var.tags
}

module "linux_virtual_machine" {
  for_each = local.linux_virtual_machines

  source  = "Azure/avm-res-compute-virtualmachine/azurerm"
  version = "0.21.0"

  name                = each.value.name
  location            = var.location
  resource_group_name = module.resource_group.name
  zone                = each.value.zone

  os_type = "Linux"

  sku_size = each.value.sku_size

  account_credentials    = each.value.account_credentials
  source_image_reference = each.value.source_image_reference
  os_disk                = each.value.os_disk
  computer_name          = try(each.value.computer_name, each.value.name)

  network_interfaces = {
    primary = {
      name = "${each.value.name}-nic"
      ip_configurations = {
        primary = {
          name                          = "ipconfig1"
          private_ip_subnet_resource_id = module.virtual_network.subnets["primary"].resource_id
        }
      }
    }
  }

  enable_telemetry = false
  tags             = each.value.tags
}

module "windows_virtual_machine" {
  for_each = local.windows_virtual_machines

  source  = "Azure/avm-res-compute-virtualmachine/azurerm"
  version = "0.21.0"

  name                = each.value.name
  location            = var.location
  resource_group_name = module.resource_group.name
  zone                = each.value.zone

  os_type = "Windows"

  sku_size = each.value.sku_size

  account_credentials    = each.value.account_credentials
  source_image_reference = each.value.source_image_reference
  os_disk                = each.value.os_disk
  computer_name          = try(each.value.computer_name, each.value.name)
  patch_mode             = try(each.value.patch_mode, null)
  enable_automatic_updates = coalesce(
    try(each.value.enable_automatic_updates, null),
    try(each.value.patch_mode, null) == "Manual" ? false : true
  )

  network_interfaces = {
    primary = {
      name = "${each.value.name}-nic"
      ip_configurations = {
        primary = {
          name                          = "ipconfig1"
          private_ip_subnet_resource_id = module.virtual_network.subnets["primary"].resource_id
        }
      }
    }
  }

  enable_telemetry = false
  tags             = each.value.tags
}