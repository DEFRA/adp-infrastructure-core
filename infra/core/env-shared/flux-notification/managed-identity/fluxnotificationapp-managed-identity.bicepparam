using './fluxnotificationapp-managed-identity.bicep'

param managedIdentity = {
  name: '#{{ fluxNotificationApiManagedIdentity }}'
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
  'FLUXNOTIFY-MI-CLIENT-ID'
]

param eventHub = {
  namespaceName: '#{{ ssvInfraResourceNamePrefix }}#{{nc_resource_eventhub }}#{{nc_shared_instance_regionid }}01'
  eventHubName: 'flux-events-#{{ subEnvironment }}'
}

param storageAccount = {
  name: '#{{ fluxNotificationStorageAccountName }}'
  containerName: '#{{ fluxNotificationContainerName }}'
}
