# Azure AVM Infrastructure Deployment

This Terraform configuration deploys Azure infrastructure using
[Azure Verified Modules (AVM)](https://azure.github.io/Azure-Verified-Modules/).

## Resources

The configuration creates:

- One resource group
- One virtual network
- One subnet
- One StorageV2 storage account
- One blob container
- Zero or more Linux and Windows virtual machines
- One network interface for each virtual machine

All virtual machines connect to the primary subnet. The configuration does not
create network security groups, public IP addresses, NAT gateways, or route
tables.

## Project Files

| File | Purpose |
| --- | --- |
| `version.tf` | Terraform, provider, and provider-version requirements |
| `main.tf` | AVM module declarations and resource configuration |
| `variable.tf` | Input types, defaults, and validation |
| `terraform.tfvars` | Environment-specific input values |
| `output.tf` | Resource names, VM IDs, and private IP outputs |
| `.terraform.lock.hcl` | Selected provider versions |

The `.terraform/` directory and `terraform.tfstate*` files are generated
locally and should not be committed to source control.

## Module Versions

| Module | Version |
| --- | --- |
| `Azure/avm-res-resources-resourcegroup/azurerm` | `0.4.0` |
| `Azure/avm-res-network-virtualnetwork/azurerm` | `0.8.1` |
| `Azure/avm-res-storage-storageaccount/azurerm` | `0.7.3` |
| `Azure/avm-res-compute-virtualmachine/azurerm` | `0.21.0` |

Terraform `>= 1.10.0, < 2.0.0` is required.

## Prerequisites

- Terraform 1.10 or later
- Azure CLI
- An Azure account with permission to create the configured resources

Authenticate and select the required subscription:

```powershell
az login
az account set --subscription '<subscription-id>'
az account show --output table
```

## Configuration

Set the required values in `terraform.tfvars`.

### Base infrastructure

```hcl
resource_group_name = "example-rg"
location            = "Central India"

virtual_network_name          = "example-vnet"
virtual_network_address_space = ["10.0.0.0/16"]

subnet_name             = "example-snet"
subnet_address_prefixes = ["10.0.1.0/24"]

storage_account_name   = "examplestorage123"
storage_container_name = "example-container"

tags = {
  ManagedBy = "Terraform"
}
```

Storage account names must be globally unique, contain only lowercase letters
and numbers, and be between 3 and 24 characters.

### Windows Server 2019 VM

```hcl
virtual_machines = {
  win-vm-01 = {
    os_type      = "windows"
    name         = "example-win-01"
    zone         = null
    sku_size     = "Standard_B2ms"
    patch_mode   = "Manual"

    account_credentials = {
      admin_credentials = {
        username                           = "azureadmin"
        password                           = "<supply-securely>"
        generate_admin_password_or_ssh_key = false
      }
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
  }
}
```

`version = "latest"` selects the latest patched release of the specified
Windows Server 2019 SKU; it does not change the operating system to a later
Windows Server version.

When `patch_mode = "Manual"`, the configuration automatically sets
`enable_automatic_updates = false`, as required by Azure. An explicit value of
`true` with Manual patch mode is rejected by input validation.

### Linux VM

```hcl
virtual_machines = {
  linux-vm-01 = {
    os_type  = "linux"
    name     = "example-linux-01"
    zone     = null
    sku_size = "Standard_B2s"

    account_credentials = {
      admin_credentials = {
        username                           = "azureuser"
        generate_admin_password_or_ssh_key = true
      }
      password_authentication_disabled = true
    }

    source_image_reference = {
      publisher = "Canonical"
      offer     = "0001-com-ubuntu-server-jammy"
      sku       = "22_04-lts-gen2"
      version   = "latest"
    }
  }
}
```

Set `virtual_machines = {}` to deploy no virtual machines. Linux-only,
Windows-only, and mixed maps are supported.

## Sensitive Values

Do not commit `terraform.tfvars` when it contains real passwords. Supply the
`virtual_machines` value through a protected pipeline variable, generate a
temporary `.auto.tfvars` file in the deployment job, or use the AVM credential
generation and Key Vault configuration supported by the input object.

If a password has already been committed or shared, rotate it immediately.
Terraform state can also contain sensitive information and must be protected.
For team or production use, configure an Azure Storage remote backend with
state locking and restricted access.

## Deploy

Format and validate:

```powershell
terraform fmt -check
terraform init
terraform validate
```

Review and apply a saved plan:

```powershell
terraform plan -out='deployment.tfplan'
terraform apply 'deployment.tfplan'
```

Review the outputs:

```powershell
terraform output
```

## State and Azure Drift

List resources managed by the current state:

```powershell
terraform state list
```

Compare the state with resources currently returned by Azure:

```powershell
terraform plan -refresh-only
```

After reviewing the refresh-only plan, update the state if required:

```powershell
terraform apply -refresh-only
```

Resources shown in the Azure portal but absent from `terraform state list`
were not created or adopted by this Terraform state. Use the Azure Activity
Log to identify their creating user, service principal, managed identity,
policy, or deployment.

## Destroy

Review and destroy everything managed by this configuration:

```powershell
terraform plan -destroy -out='destroy.tfplan'
terraform apply 'destroy.tfplan'
```

To destroy one Windows VM module instance and its module-managed resources:

```powershell
terraform plan -destroy `
  -target='module.windows_virtual_machine["win-vm-01"]' `
  -out='vm-destroy.tfplan'

terraform apply 'vm-destroy.tfplan'
```

Remove that VM entry from `terraform.tfvars`; otherwise, a later normal
`terraform apply` will propose recreating it. Targeted operations are intended
for exceptional recovery or maintenance workflows. Always review the plan.

## Outputs

| Output | Description |
| --- | --- |
| `resource_group_name` | Resource group name |
| `resource_group_location` | Resource group Azure region |
| `virtual_network_name` | Virtual network name |
| `subnet_name` | Primary subnet name |
| `storage_account_name` | Storage account name |
| `storage_container_name` | Blob container name |
| `linux_virtual_machine_ids` | Linux VM IDs keyed by input map key |
| `windows_virtual_machine_ids` | Windows VM IDs keyed by input map key |
| `virtual_machine_ids` | Combined map of VM IDs |
| `virtual_machine_private_ip_addresses` | Combined map of private IPs |
| `virtual_machine_names` | VM names keyed by input map key |

## Terraform Module Downloads

`terraform init` downloads all child modules statically declared by an AVM
module, including optional child modules not used by the selected inputs.
Consequently, the storage AVM module creates several folders under
`.terraform/modules/`. These folders are local dependency cache entries and
do not mean that corresponding Azure resources will be deployed.
