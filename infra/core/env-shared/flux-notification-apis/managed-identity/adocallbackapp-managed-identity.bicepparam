using './adocallbackapp-managed-identity.bicep'

param managedIdentity = {
  name: '#{{ adoCallbackApiManagedIdentity }}'
}

param environment = '#{{ environment }}'
param subEnvironment = '#{{ subEnvironment }}'
param location = '#{{ location }}'

param containerRegistry = {
  name: '#{{ ssvSharedAcrName }}'
  subscriptionId: '#{{ subscriptionId }}'
  resourceGroup: '#{{ ssvSharedResourceGroup }}'
}

