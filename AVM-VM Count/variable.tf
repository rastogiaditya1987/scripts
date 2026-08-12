variable "resource_group_name" {
  description = "Name of the Azure resource group."
  type        = string

  validation {
    condition     = length(var.resource_group_name) > 1
    error_message = "resource_group_name must not be empty."
  }
}

variable "location" {
  description = "Azure region where the resource group will be created."
  type        = string
}
variable "tags" {
  description = "Additional tags to apply to the resource group."
  type        = map(string)
  default     = {}
}

variable "virtual_network_name" {
  description = "Name of the Azure Virtual Network."
  type        = string
}

variable "virtual_network_address_space" {
  description = "Address space for the virtual network."
  type        = list(string)

  validation {
    condition     = length(var.virtual_network_address_space) > 0
    error_message = "virtual_network_address_space must contain at least one CIDR block."
  }
}

variable "subnet_name" {
  description = "Name of the subnet to create in the virtual network."
  type        = string
}

variable "subnet_address_prefixes" {
  description = "Address prefixes for the subnet."
  type        = list(string)

  validation {
    condition     = length(var.subnet_address_prefixes) > 0
    error_message = "subnet_address_prefixes must contain at least one CIDR block."
  }
}

variable "storage_account_name" {
  description = "Name of the Azure Storage Account."
  type        = string

  validation {
    condition     = length(var.storage_account_name) >= 3 && length(var.storage_account_name) <= 24
    error_message = "storage_account_name must be between 3 and 24 characters."
  }
}

variable "storage_container_name" {
  description = "Name of the blob container to create."
  type        = string

  validation {
    condition     = length(var.storage_container_name) >= 3
    error_message = "storage_container_name must not be empty."
  }
}

variable "virtual_machines" {
  description = "Optional manually-defined map of virtual machines to create using the AVM VM module."
  type = map(object({
    os_type = string
    name    = optional(string)

    zone = optional(string)

    sku_size = string

    account_credentials = optional(object({
      admin_credentials = optional(object({
        username                           = optional(string, "azureuser")
        password                           = optional(string)
        ssh_keys                           = optional(list(string), [])
        generate_admin_password_or_ssh_key = optional(bool, true)
      }), {})
      key_vault_configuration = optional(object({
        resource_id = string
        secret_configuration = optional(object({
          name                           = optional(string)
          expiration_date_length_in_days = optional(number, 45)
          content_type                   = optional(string, "text/plain")
          not_before_date                = optional(string)
          tags                           = optional(map(string), {})
        }), {})
      }))
      password_authentication_disabled = optional(bool, true)
    }), {})

    source_image_reference = object({
      publisher = string
      offer     = string
      sku       = string
      version   = string
    })

    os_disk = optional(object({
      caching              = optional(string, "ReadWrite")
      storage_account_type = optional(string, "Standard_LRS")
      disk_size_gb         = optional(number)
    }), {})

    computer_name            = optional(string)
    patch_mode               = optional(string)
    enable_automatic_updates = optional(bool)
    tags                     = optional(map(string), {})
  }))
  default = {}

  validation {
    condition = alltrue([
      for vm in values(var.virtual_machines) :
      contains(["linux", "windows"], lower(vm.os_type))
    ])
    error_message = "Each virtual machine os_type must be either 'linux' or 'windows'."
  }

  validation {
    condition = alltrue([
      for vm in values(var.virtual_machines) :
      lower(vm.os_type) != "windows" ||
      vm.patch_mode != "Manual" ||
      vm.enable_automatic_updates != true
    ])
    error_message = "Windows virtual machines using patch_mode \"Manual\" must set enable_automatic_updates to false or omit it."
  }
}

variable "windows_vm_config" {
  description = "Optional generated Windows VM configuration using count and prefix."
  type = object({
    enabled     = bool
    vm_count    = number
    name_prefix = string
    zone        = optional(string)

    sku_size = string

    account_credentials = object({
      admin_credentials = object({
        username                           = optional(string, "azureadmin")
        password                           = optional(string)
        ssh_keys                           = optional(list(string), [])
        generate_admin_password_or_ssh_key = optional(bool, false)
      })
      password_authentication_disabled = optional(bool, true)
    })

    source_image_reference = object({
      publisher = string
      offer     = string
      sku       = string
      version   = string
    })

    os_disk = optional(object({
      caching              = optional(string, "ReadWrite")
      storage_account_type = optional(string, "Standard_LRS")
      disk_size_gb         = optional(number)
    }), {})

    patch_mode               = optional(string, "Manual")
    enable_automatic_updates = optional(bool)
    tags                     = optional(map(string), {})
  })
  default = null

  validation {
    condition = (
      var.windows_vm_config == null ||
      var.windows_vm_config.vm_count >= 0
    )
    error_message = "windows_vm_config.vm_count must be greater than or equal to 0."
  }

  validation {
    condition = (
      var.windows_vm_config == null ||
      contains(["AutomaticByOS", "AutomaticByPlatform", "Manual"], var.windows_vm_config.patch_mode)
    )
    error_message = "windows_vm_config.patch_mode must be one of AutomaticByOS, AutomaticByPlatform, or Manual."
  }

  validation {
    condition = (
      var.windows_vm_config == null ||
      var.windows_vm_config.patch_mode != "Manual" ||
      var.windows_vm_config.enable_automatic_updates != true
    )
    error_message = "When windows_vm_config.patch_mode is \"Manual\", enable_automatic_updates must be false or omitted."
  }
}