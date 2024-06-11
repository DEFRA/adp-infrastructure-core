
@description('Required. The parameter object for eventHub. The object must contain the name, eventHubName, eventHubConnectionSecretName and resourceGroup values.')
param eventHubNamespace object

@description('Required. The parameter object for eventHub. The object must contain the name and keyVaultName.')
param eventHub object

@description('Required. The parameter object for eventHub. The object must contain the sendFluxNotificationsToSecondEventHub, name, keyVaultName and resourceGroup.')
param secondEventHub object

@description('Required. App Configuration Managed Identity Object id.')
param appConfigMiObjectId string

@description('Optional. Date in the format yyyyMMdd-HHmmss.')
param deploymentDate string = utcNow('yyyyMMdd-HHmmss')

module eventHubSecretRbac '.bicep/keyvault-secret-rbac.bicep' = {
  name: 'eventhub-secret-rbac-${deploymentDate}'
  params: {
    eventHubNamespace: eventHubNamespace
    eventHub: eventHub
    appConfigMiObjectId: appConfigMiObjectId
  }
}

module secondEventHubSecretRbac '.bicep/keyvault-secret-rbac.bicep' = if (bool(secondEventHub.sendFluxNotificationsToSecondEventHub)) {
  scope: resourceGroup(secondEventHub.resourceGroup)
  name: 'secondeventhub-secret-rbac-${deploymentDate}'
  params: {
    eventHubNamespace: eventHubNamespace
    eventHub: secondEventHub
    appConfigMiObjectId: appConfigMiObjectId
  }
}
