locals {
  virtual_machines = {
    for key, vm in var.virtual_machines :
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

  # optional
  enable_telemetry = false

  tags = var.tags
}

module "virtual_network" {
  source  = "Azure/avm-res-network-virtualnetwork/azurerm"
  version = "0.8.1"

  name                = var.virtual_network_name
  location            = var.location
  resource_group_name = module.resource_group.name
  address_space       = var.virtual_network_address_space

  # optional
  enable_telemetry = false
  shared_access_key_enabled = true

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

  blob_properties = {
    change_feed_enabled             = false
    default_service_version         = null
    last_access_time_enabled        = false
    versioning_enabled              = false
    delete_retention_policy         = null
    container_delete_retention_policy = null
    restore_policy                  = null
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
