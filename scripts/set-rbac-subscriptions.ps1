param(
    [string][Parameter(mandatory=$true)] $SubscriptionName
)

Write-Host "Assigning UAA to Subscription $($SubscriptionName)"

Write-Host "ADO-DefraGovUK-CDO-SND1-Cont-ClientId = $(ADO-DefraGovUK-CDO-SND1-Cont-ClientId)"

Write-Host "ADO-DefraGovUK-CDO-SND2-Cont-ClientId = $(ADO-DefraGovUK-CDO-SND2-Cont-ClientId)"

Write-Host "ADO-DefraGovUK-CDO-SND3-Cont-ClientId = $(ADO-DefraGovUK-CDO-SND3-Cont-ClientId)"


Write-Host "Assigning Contributor to Subscription $($SubscriptionName)"