<#
.SYNOPSIS
    One-time setup for deploying the site onto the shared portfolio base.

.DESCRIPTION
    The site runs in the Container Apps environment every portfolio app shares, in the resource group
    rg-portfolio-shared, which scox115/gameappportfolio's infra/setup-shared.ps1 creates
    (see docs/adr/0008-shared-portfolio-base.md). This creates what is only the site's:

      - its resource group (rg-portfolio-slc)
      - an app registration GitHub Actions signs in as, using OIDC (no password or key), trusted only
        for this repository's "production" environment
      - Contributor on that resource group, and on the shared environment (to run the site in it and to
        issue its managed certificates there)
      - the repository variables the deploy workflow reads

    Safe to run again: anything that already exists is reused.
    Works in Windows PowerShell 5.1 and PowerShell 7. Needs the Azure CLI (az), signed in with
    "az login" to the subscription that holds the shared base, and the GitHub CLI (gh), signed in with
    "gh auth login".

.EXAMPLE
    .\infra\setup-azure.ps1 -SubscriptionId 00000000-0000-0000-0000-000000000000
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string] $SubscriptionId,

    [string] $ResourceGroup = 'rg-portfolio-slc',
    [string] $SharedResourceGroup = 'rg-portfolio-shared',
    [string] $GitHubRepo = 'scox115/portfolio-app-slc',
    [string] $DeployAppName = 'portfolio-slc-github-deploy'
)

$ErrorActionPreference = 'Stop'

# Runs an az command and stops the script if it fails (az doesn't throw on its own).
function Invoke-Az {
    $output = & az @args
    if ($LASTEXITCODE -ne 0) { throw "az $($args -join ' ') failed." }
    return $output
}

function Grant-Role([string] $principalId, [string] $role, [string] $scope) {
    $assigned = Invoke-Az role assignment list --assignee $principalId --role $role --scope $scope --query '[0].id' --output tsv
    if (-not $assigned) {
        Write-Host "  granting $role on $($scope.Split('/')[-1])"
        Invoke-Az role assignment create --assignee-object-id $principalId --assignee-principal-type ServicePrincipal `
            --role $role --scope $scope --output none
    }
}

if (-not (Get-Command gh -ErrorAction SilentlyContinue)) { throw 'This needs the GitHub CLI (gh). Install it and run "gh auth login".' }

Write-Host "Using subscription $SubscriptionId" -ForegroundColor Cyan
Invoke-Az account set --subscription $SubscriptionId | Out-Null
$tenantId = Invoke-Az account show --query tenantId --output tsv

$environmentName = Invoke-Az deployment group show --resource-group $SharedResourceGroup --name portfolio-shared `
    --query properties.outputs.environmentName.value --output tsv
$environment = Invoke-Az containerapp env show --resource-group $SharedResourceGroup --name $environmentName `
    --query '{id: id, location: location}' --output json | ConvertFrom-Json
Write-Host "Shared environment $environmentName in $($environment.location)" -ForegroundColor Cyan

# The site's container app has to be in the environment's region, so its group is too.
Write-Host "Resource group $ResourceGroup" -ForegroundColor Cyan
Invoke-Az group create --name $ResourceGroup --location $environment.location --tags app=portfolio-slc --output none
$groupScope = Invoke-Az group show --name $ResourceGroup --query id --output tsv

Write-Host "GitHub deploy app $DeployAppName" -ForegroundColor Cyan
$appId = Invoke-Az ad app list --display-name $DeployAppName --query '[0].appId' --output tsv
if (-not $appId) {
    $appId = Invoke-Az ad app create --display-name $DeployAppName --query appId --output tsv
}
$spId = Invoke-Az ad sp list --display-name $DeployAppName --query '[0].id' --output tsv
if (-not $spId) {
    $spId = Invoke-Az ad sp create --id $appId --query id --output tsv
}

# GitHub names the repository in its sign-in token either as "owner/repo" or, for newer repositories,
# with their numeric IDs ("owner@123/repo@456"), so trust both forms.
$ids = @(& gh api "repos/$GitHubRepo" --jq '.owner.id, .id')
if ($LASTEXITCODE -ne 0 -or $ids.Count -ne 2) { throw "gh api repos/$GitHubRepo failed." }
$owner, $repo = $GitHubRepo.Split('/')
$credentials = [ordered]@{
    'github-production'     = "repo:${GitHubRepo}:environment:production"
    'github-production-ids' = "repo:${owner}@$($ids[0])/${repo}@$($ids[1]):environment:production"
}
$subjects = @(Invoke-Az ad app federated-credential list --id $appId --query '[].subject' --output tsv)
foreach ($name in $credentials.Keys) {
    if ($subjects -contains $credentials[$name]) { continue }
    Write-Host "  trusting $($credentials[$name])"
    $credentialFile = [System.IO.Path]::GetTempFileName()
    @{
        name      = $name
        issuer    = 'https://token.actions.githubusercontent.com'
        subject   = $credentials[$name]
        audiences = @('api://AzureADTokenExchange')
    } | ConvertTo-Json | Set-Content -Path $credentialFile -Encoding ASCII
    Invoke-Az ad app federated-credential create --id $appId --parameters "@$credentialFile" | Out-Null
    Remove-Item $credentialFile
}

# A sign-in that was just created can take a minute to appear for role assignments.
for ($attempt = 1; -not (Invoke-Az ad sp list --filter "id eq '$spId'" --query '[0].id' --output tsv); $attempt++) {
    if ($attempt -gt 36) { throw "$DeployAppName still isn't visible in Entra ID. Run the script again in a few minutes." }
    Start-Sleep -Seconds 5
}
Grant-Role $spId 'Contributor' $groupScope
Grant-Role $spId 'Contributor' $environment.id

Write-Host "Saving settings to GitHub ($GitHubRepo)" -ForegroundColor Cyan
$variables = [ordered]@{
    AZURE_CLIENT_ID                    = $appId
    AZURE_TENANT_ID                    = $tenantId
    AZURE_SUBSCRIPTION_ID              = $SubscriptionId
    AZURE_RESOURCE_GROUP               = $ResourceGroup
    AZURE_SHARED_RESOURCE_GROUP        = $SharedResourceGroup
    AZURE_CONTAINERAPPS_ENVIRONMENT_ID = $environment.id
}
foreach ($name in $variables.Keys) {
    & gh variable set $name --body $variables[$name] --repo $GitHubRepo
    if ($LASTEXITCODE -ne 0) { throw "gh variable set $name failed." }
}

Write-Host ''
Write-Host 'Done. Merge the pull request that moves the deploy to the shared base; its first deploy creates' -ForegroundColor Green
Write-Host 'the site in the shared environment at a new azurecontainerapps.io address, while scottcoxdev.com'
Write-Host 'keeps serving the old one. Then move the domain with infra/move-domain.ps1.'
