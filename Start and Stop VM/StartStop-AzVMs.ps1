param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("Start","Stop","Deallocate")]
    [string]$Action,

    [Parameter(Mandatory=$true)]
    [string]$SubscriptionId,

    [Parameter(Mandatory=$false)]
    [string]$ResourceGroup,

    [Parameter(Mandatory=$false)]
    [string[]]$VMNames,

    [Parameter(Mandatory=$false)]
    [string]$TagKey,

    [Parameter(Mandatory=$false)]
    [string]$TagValue
)

# Prereqs:
# Install-Module Az -Scope CurrentUser
# Connect-AzAccount

Set-AzContext -SubscriptionId $SubscriptionId | Out-Null

# Build VM target list
if ($VMNames -and $ResourceGroup) {
    $vms = foreach ($vmn in $VMNames) { Get-AzVM -ResourceGroupName $ResourceGroup -Name $vmn -ErrorAction SilentlyContinue }
}
elseif ($ResourceGroup -and $TagKey -and $TagValue) {
    $vms = Get-AzVM -ResourceGroupName $ResourceGroup | Where-Object { $_.Tags[$TagKey] -eq $TagValue }
}
elseif ($TagKey -and $TagValue) {
    $vms = Get-AzVM | Where-Object { $_.Tags[$TagKey] -eq $TagValue }
}
elseif ($ResourceGroup) {
    $vms = Get-AzVM -ResourceGroupName $ResourceGroup
}
else {
    throw "Provide either (ResourceGroup) or (ResourceGroup+VMNames) or (TagKey+TagValue)."
}

$vms = $vms | Where-Object { $_ -ne $null }

if (-not $vms -or $vms.Count -eq 0) {
    Write-Host "No VMs found with provided filters."
    exit 0
}

Write-Host "Action: $Action"
Write-Host "VM count: $($vms.Count)"
$vms | ForEach-Object { Write-Host " - $($_.ResourceGroupName)/$($_.Name)" }

foreach ($vm in $vms) {
    try {
        switch ($Action) {
            "Start" {
                Write-Host "Starting $($vm.Name)..." -ForegroundColor Green
                Start-AzVM -ResourceGroupName $vm.ResourceGroupName -Name $vm.Name -NoWait
            }
            "Stop" {
                Write-Host "Stopping (power off) $($vm.Name)..." -ForegroundColor Yellow
                Stop-AzVM -ResourceGroupName $vm.ResourceGroupName -Name $vm.Name -StayProvisioned -Force -NoWait
            }
            "Deallocate" {
                Write-Host "Stopping + deallocating $($vm.Name)..." -ForegroundColor Red
                Stop-AzVM -ResourceGroupName $vm.ResourceGroupName -Name $vm.Name -Force -NoWait
            }
        }
    }
    catch {
        Write-Warning "Failed for $($vm.Name): $($_.Exception.Message)"
    }
}

Write-Host "Submitted $Action operation(s). Use Get-AzVM -Status to verify."