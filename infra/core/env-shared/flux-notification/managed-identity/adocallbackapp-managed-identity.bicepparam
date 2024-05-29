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

param keyVault = {
  name: '#{{ ssvInfraKeyVault }}'
  subscriptionId: '#{{ subscriptionId }}'
  resourceGroup: '#{{ ssvInfraResourceGroup }}'
}

param secrets = [
  'POSTGRES-HOST'
  'CALLBACKAPI-MI-CLIENT-ID'
  'API-AUTH-BACKEND-APP-REG-CLIENT-ID'
  'SHARED-APPINSIGHTS-CONNECTIONSTRING'
]


param appInsights = {
  name: '#{{ applicationInsightsName }}'
  resourceGroup: '#{{ ssvSharedResourceGroup }}'
  subscriptionId: '#{{ subscriptionId }}'
}

