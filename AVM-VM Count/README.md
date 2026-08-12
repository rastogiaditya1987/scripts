# Azure AVM Infrastructure Deployment

This Terraform configuration deploys Azure infrastructure using Azure Verified Modules (AVM).

## Resources

The configuration creates:

- One resource group
- One virtual network
- One subnet
- One StorageV2 storage account
- One blob container
- Zero or more Linux and Windows virtual machines
- One network interface for each virtual machine

## VM creation options

This configuration supports two ways to create VMs:

### 1. Manual VM map
You can define VMs explicitly using `virtual_machines`.

### 2. Generated Windows VMs using count + prefix
You can define a single `windows_vm_config` object and Terraform will generate multiple VMs automatically.

Example:

```hcl
windows_vm_config = {
  enabled     = true
  vm_count    = 3
  name_prefix = "Aditya-win"
  zone        = null
  sku_size    = "Standard_B2ms"
  patch_mode  = "Manual"

  account_credentials = {
    admin_credentials = {
      username                           = "azureadmin"
      password                           = "<secure-password>"
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
```

This creates:

- `Aditya-win-01`
- `Aditya-win-02`
- `Aditya-win-03`

## Notes

- `virtual_machines` and `windows_vm_config` can both be used
- generated Windows VMs are merged into the same internal VM map
- numbering uses `01`, `02`, `03` format
- if `vm_count = 0`, no generated Windows VMs are created
- if `enabled = false`, no generated Windows VMs are created

## Deploy

```powershell
terraform fmt
terraform init
terraform validate
terraform plan
terraform apply
```