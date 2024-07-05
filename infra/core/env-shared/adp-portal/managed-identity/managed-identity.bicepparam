using './managed-identity.bicep'

param managedIdentity = {
  name: '#{{ portalWebManagedIdentity }}'
}

param environment = '#{{ environment }}'

param location = '#{{ location }}'

param containerRegistry = {
  name: '#{{ ssvSharedAcrName }}'
  subscriptionId: '#{{ subscriptionId }}'
  resourceGroup: '#{{ ssvSharedResourceGroup }}'
}

param keyVault = {
  name: '#{{ ssvInfraKeyVault }}'
  subscriptionId: '#{{ subscriptionId }}'
  resourceGroup: '#{{ ssvInfraResourceGroup }}'
}

param appInsights = {
  name: '#{{ applicationInsightsName }}'
  resourceGroup: '#{{ ssvSharedResourceGroup }}'
  subscriptionId: '#{{ subscriptionId }}'
}

param resourceLockEnabled = #{{ resourceLockEnabled }}
