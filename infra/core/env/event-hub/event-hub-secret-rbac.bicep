
param eventHubNamespace object //= {
//   name: 'SSVADPINFEN3401'
//   eventHubName: 'flux-events-dev'
//   resourceGroup: 'SSVADPINFRG3401'
//   eventHubConnectionSecretName: 'EVENTHUB-CONNECTION-SND1'
// }

param keyVaultName string //= 'SSVADPINFVT3402'
param appConfigMiObjectId string //= '2eb6fd3a-8dec-4634-8b48-512d268277ae'

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
