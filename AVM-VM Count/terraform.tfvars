resource_group_name = "Aditya-RG"
location            = "Central India"

virtual_network_name          = "Aditya-VNet"
virtual_network_address_space = ["192.1.0.0/25"]

subnet_name             = "snet-Aditya"
subnet_address_prefixes = ["192.1.0.0/27"]

storage_account_name   = "adityastoragesa"
storage_container_name = "aditya-container"

tags = {
  owner      = "Aditya"
  Created_by = "AVM Terraform"
  Managed_by = "Terraform"
}

virtual_machines = {}

windows_vm_config = {
  enabled     = true
  vm_count    = 0
  name_prefix = "Aditya-win"
  zone        = null
  sku_size    = "Standard_B2ms"
  patch_mode  = "Manual"

  account_credentials = {
    admin_credentials = {
      username                           = "azureadmin"
      password                           = "ChangeMe123!"
      generate_admin_password_or_ssh_key = false
    }
    password_authentication_disabled = true
  }

  source_image_reference = {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-datacenter"
    version   = "latest"
  }

  os_disk = {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = 128
  }

  tags = {
    owner      = "Aditya"
    Created_by = "AVM Terraform"
    Managed_by = "Terraform"
  }
}