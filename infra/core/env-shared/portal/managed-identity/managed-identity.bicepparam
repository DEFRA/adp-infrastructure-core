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
  name: '#{{ portalAppKeyVaultName }}'
  subscriptionId: '#{{ subscriptionId }}'
  resourceGroup: '#{{ portalResourceGroup }}'
}
