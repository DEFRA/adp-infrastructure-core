param(
    [string][Parameter(mandatory=$true)] $SubscriptionName,
    [string][Parameter(mandatory=$true)] $KeyVaultName,
    [string][Parameter(mandatory=$true)] $Tier2ApplicationClientIdSecretName
)

Write-Host "Param:KeyVaultName =  $($KeyVaultName)"
Write-Host "Param:Tier2ApplicationClientIdSecretName =  $($Tier2ApplicationClientIdSecretName)"

$tier2ApplicationClientId = Get-AzKeyVaultSecret -VaultName $KeyVaultName -Name $Tier2ApplicationClientIdSecretName -AsPlainText

Write-Host "Tier2ApplicationClientId value is =  $($tier2ApplicationClientId)"

Write-Host "Assigning $($tier2ApplicationClientId) User Acess Administrator role to Subscription $($SubscriptionName)"

Write-Host "Assigning $($tier2ApplicationClientId) Contributor role to Subscription $($SubscriptionName)"

