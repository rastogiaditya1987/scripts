# Start specific VMs in one RG
.\StartStop-AzVMs.ps1 -Action Start -SubscriptionId "<sub-id>" -ResourceGroup "rg-app" -VMNames @("vm1","vm2")

# Stop all VMs in an RG (power off, still billed for compute allocation)
.\StartStop-AzVMs.ps1 -Action Stop -SubscriptionId "" -ResourceGroup ""

# Deallocate all VMs with tag env=dev across subscription
.\StartStop-AzVMs.ps1 -Action Deallocate -SubscriptionId "<sub-id>" -TagKey "env" -TagValue "dev"
