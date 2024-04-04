using './managed-identity.bicep'

param managedIdentity = {
  name: '#{{ portalApiManagedIdentity }}'
}

param environment = '#{{ environment }}'
param location = '#{{ location }}'

param containerRegistry = {
  name: '#{{ ssvSharedAcrName }}'
  subscriptionId: '#{{ subscriptionId }}'
  resourceGroup: '#{{ ssvSharedResourceGroup }}'
}

param appKeyVault = {
  name: '#{{ ssvInfraKeyVault }}'
  subscriptionId: '#{{ subscriptionId }}'
  resourceGroup: '#{{ ssvInfraResourceGroup }}'
}

param platformKeyVault = {
  name: '#{{ ssvPlatformKeyVaultName }}'
  subscriptionId: '#{{ subscriptionId }}'
  resourceGroup: '#{{ ssvSharedResourceGroup }}'
}

param secrets = [
  'ADO-DefraGovUK-AAD-ADP-#{{ssvEnvironment}}#{{environmentId}}'
  'ADO-DefraGovUK-AAD-ADP-#{{ssvEnvironment}}#{{environmentId}}-ClientId'
  'ADO-DefraGovUK-AAD-ADP-#{{ssvEnvironment}}#{{environmentId}}-ObjectId'
]
