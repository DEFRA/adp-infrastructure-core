using './fluxnotificationapp-managed-identity.bicep'

param managedIdentity = {
  name: '#{{ fluxNotificationApiManagedIdentity }}'
}

param environment = '#{{ environment }}'
param subEnvironment = '#{{ subEnvironment }}'
param location = '#{{ location }}'

param containerRegistry = {
  name: '#{{ ssvSharedAcrName }}'
  resourceGroup: '#{{ ssvSharedResourceGroup }}'
}

param keyVaultName = '#{{ ssvInfraKeyVault }}'

param secrets = [
  'POSTGRES-HOST'
  'FLUXNOTIFY-MI-CLIENT-ID'
  'SHARED-APPINSIGHTS-CONNECTIONSTRING'
]

param eventHub = {
  namespaceName: '#{{ ssvInfraResourceNamePrefix }}#{{nc_resource_eventhub }}#{{nc_shared_instance_regionid }}01'
  eventHubName: 'flux-events-#{{ subEnvironment }}'
  resourceGroup: '#{{ ssvSharedResourceGroup }}'
}

param storageAccount = {
  name: '#{{ fluxNotificationStorageAccountName }}'
  containerName: '#{{ fluxNotificationContainerAppId }}'
}

param appInsights = {
  name: '#{{ applicationInsightsName }}'
  resourceGroup: '#{{ ssvSharedResourceGroup }}'
  subscriptionId: '#{{ subscriptionId }}'
}
