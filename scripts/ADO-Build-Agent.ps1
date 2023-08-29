[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string] $imageGalleryTenant,
    [Parameter(Mandatory)]
    [string] $tenantId,
    [Parameter(Mandatory)]
    [string] $subscriptionName,
    [Parameter(Mandatory)]
    [string] $resourceGroup,
    [Parameter(Mandatory)]
    [string] $vmssName,
    [Parameter(Mandatory)]
    [string] $subnetId,
    [Parameter(Mandatory)]
    [string] $imageId,
    [Parameter(Mandatory)] 
    [string] $adoAgentPass
)

az account clear

if ($imageGalleryTenant -ne $tenantId) {
    az login --service-principal -u $env:servicePrincipalId -p $env:servicePrincipalKey --tenant $imageGalleryTenant
    az account get-access-token    
}

az login --service-principal -u $env:servicePrincipalId -p $env:servicePrincipalKey --tenant $tenantId
az account get-access-token

az account set --subscription $subscriptionName

az vmss create `
    --resource-group $resourceGroup `
    --name $vmssName `
    --computer-name-prefix $vmssName `
    --vm-sku Standard_D4s_v4 `
    --instance-count 2 `
    --subnet $subnetId `
    --image "$imageId" `
    --authentication-type password `
    --admin-username azureuser `
    --admin-password "$adoAgentPass" `
    --disable-overprovision `
    --upgrade-policy-mode Manual `
    --public-ip-address '""'
