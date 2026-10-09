<#
.SYNOPSIS
    Moves scottcoxdev.com and www.scottcoxdev.com to the site's container app on the shared base.

.DESCRIPTION
    Run once, after the first deploy to the shared base has created the new container app. It:

      1. prints the DNS records to change at GoDaddy (the apex A record and its asuid TXT record, the www
         CNAME and its asuid.www TXT record), with the new values;
      2. waits until the new records are visible;
      3. adds both hostnames to the new container app and binds each with a free managed certificate,
         issued in the shared environment.

    From the DNS change until the certificates are issued (usually 5 to 15 minutes) visitors may see a
    certificate warning. The old app keeps its own bindings until its subscription is cleaned up.
    See docs/adr/0008-shared-portfolio-base.md.

    Works in Windows PowerShell 5.1 and PowerShell 7. Needs the Azure CLI (az), signed in with
    "az login" to the subscription that holds the shared base.

.EXAMPLE
    .\infra\move-domain.ps1 -SubscriptionId 00000000-0000-0000-0000-000000000000
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string] $SubscriptionId,

    [string] $Domain = 'scottcoxdev.com',
    [string] $ResourceGroup = 'rg-portfolio-slc',
    [string] $SharedResourceGroup = 'rg-portfolio-shared',
    [string] $ContainerApp = 'portfolio-app-slc'
)

$ErrorActionPreference = 'Stop'

function Invoke-Az {
    $output = & az @args
    if ($LASTEXITCODE -ne 0) { throw "az $($args -join ' ') failed." }
    return $output
}

# Public DNS answers for one record, or an empty list. Asks Google's resolver, so a stale answer cached
# on this computer doesn't hide the change.
function Get-Dns([string] $name, [string] $type) {
    try {
        $answers = Resolve-DnsName -Name $name -Type $type -Server 8.8.8.8 -DnsOnly -ErrorAction Stop
    }
    catch { return @() }
    switch ($type) {
        'A' { return @($answers | Where-Object { $_.Type -eq 'A' } | ForEach-Object { $_.IPAddress }) }
        'TXT' { return @($answers | Where-Object { $_.Type -eq 'TXT' } | ForEach-Object { $_.Strings -join '' }) }
        'CNAME' { return @($answers | Where-Object { $_.Type -eq 'CNAME' } | ForEach-Object { $_.NameHost.TrimEnd('.') }) }
    }
}

Invoke-Az account set --subscription $SubscriptionId | Out-Null

$environmentName = Invoke-Az deployment group show --resource-group $SharedResourceGroup --name portfolio-shared `
    --query properties.outputs.environmentName.value --output tsv
$environment = Invoke-Az containerapp env show --resource-group $SharedResourceGroup --name $environmentName `
    --query '{id: id, ip: properties.staticIp, verification: properties.customDomainConfiguration.customDomainVerificationId}' `
    --output json | ConvertFrom-Json
$fqdn = Invoke-Az containerapp show --resource-group $ResourceGroup --name $ContainerApp `
    --query properties.configuration.ingress.fqdn --output tsv
if (-not $fqdn) { throw "$ContainerApp isn't in $ResourceGroup yet. Run the Deploy to Azure workflow first." }

$www = "www.$Domain"
$records = @(
    [pscustomobject]@{ Type = 'A';     Name = '@';         Value = $environment.ip;           Check = { (Get-Dns $Domain 'A') -contains $environment.ip } }
    [pscustomobject]@{ Type = 'TXT';   Name = 'asuid';     Value = $environment.verification; Check = { (Get-Dns "asuid.$Domain" 'TXT') -contains $environment.verification } }
    [pscustomobject]@{ Type = 'CNAME'; Name = 'www';       Value = $fqdn;                     Check = { (Get-Dns $www 'CNAME') -contains $fqdn } }
    [pscustomobject]@{ Type = 'TXT';   Name = 'asuid.www'; Value = $environment.verification; Check = { (Get-Dns "asuid.$www" 'TXT') -contains $environment.verification } }
)

Write-Host "The new site is already live at https://$fqdn" -ForegroundColor Cyan
Write-Host ''
Write-Host "At GoDaddy (DNS for $Domain), change these four records to the new values:" -ForegroundColor Cyan
$records | Format-Table Type, Name, Value -AutoSize | Out-String | Write-Host
Write-Host 'Replace the old values rather than adding new records. Leave the "play" record alone.'
Read-Host 'Press Enter once you have saved them'

Write-Host 'Waiting for the new records to be visible (this can take a few minutes)...' -ForegroundColor Cyan
for ($attempt = 1; ; $attempt++) {
    $waiting = @($records | Where-Object { -not (& $_.Check) })
    if ($waiting.Count -eq 0) { break }
    if ($attempt -gt 60) { throw "Still waiting for: $(($waiting | ForEach-Object { "$($_.Type) $($_.Name)" }) -join ', '). Check them at GoDaddy, then run this again." }
    Write-Host "  still waiting for $(($waiting | ForEach-Object { "$($_.Type) $($_.Name)" }) -join ', ')"
    Start-Sleep -Seconds 30
}

# The apex is validated over HTTP (its A record), www through its CNAME.
foreach ($binding in @(@{ Name = $Domain; Validation = 'HTTP' }, @{ Name = $www; Validation = 'CNAME' })) {
    $existing = Invoke-Az containerapp hostname list --resource-group $ResourceGroup --name $ContainerApp `
        --query "[?name=='$($binding.Name)'].bindingType | [0]" --output tsv
    if ($existing -eq 'SniEnabled') {
        Write-Host "$($binding.Name) is already bound." -ForegroundColor Green
        continue
    }
    if (-not $existing) {
        Invoke-Az containerapp hostname add --resource-group $ResourceGroup --name $ContainerApp --hostname $binding.Name --output none
    }
    Write-Host "Issuing a certificate for $($binding.Name) (usually 5 to 15 minutes)..." -ForegroundColor Cyan
    Invoke-Az containerapp hostname bind --resource-group $ResourceGroup --name $ContainerApp --hostname $binding.Name `
        --environment $environment.id --validation-method $binding.Validation --output none
}

Write-Host ''
Write-Host "Done. https://$Domain and https://$www now serve the site from the shared base." -ForegroundColor Green
