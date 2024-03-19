
@description('Required. The parameter object for eventHub. The object must contain the name, eventHubName, eventHubConnectionSecretName and resourceGroup values.')
param eventHubNamespace object

@description('Required. KeyVault name.')
param keyVaultName string

@description('Required. App Configuration Managed Identity Object id.')
param appConfigMiObjectId string

var roleDefinitionId = '4633458b-17de-408a-b874-0445c86b69e6' // Key Vault Secrets User

resource keyVault 'Microsoft.KeyVault/vaults@2021-10-01' existing = {
  name: keyVaultName
}

resource eventHubPolicy 'Microsoft.EventHub/namespaces/eventhubs/authorizationRules@2022-01-01-preview' existing = {
  name: '${eventHubNamespace.name}/${eventHubNamespace.eventHubName}/FluxSendAccess'
  scope: resourceGroup(eventHubNamespace.resourceGroup)
}

resource secretResource 'Microsoft.KeyVault/vaults/secrets@2022-07-01' = {
  parent: keyVault
  name: eventHubNamespace.eventHubConnectionSecretName
  properties: {
    value: eventHubPolicy.listkeys().primaryConnectionString
  }
}

resource keyVaultSecretRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, appConfigMiObjectId, roleDefinitionId, secretResource.id)
  scope: secretResource
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', roleDefinitionId) 
    principalId: appConfigMiObjectId
    principalType: 'ServicePrincipal'
  }
}
