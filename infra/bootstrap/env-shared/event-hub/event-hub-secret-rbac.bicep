param namespaceName string = 'SSVADPINFEN3401'
param eventHubName string = 'flux-events'
param keyVaultName string = 'SSVADPINFVT3402'
param eventHubSendPolicyName string = 'FluxSendAccess'
param appConfigMiObjectId string = '2eb6fd3a-8dec-4634-8b48-512d268277ae'

var roleDefinitionId = 'db79e9a7-68ee-4b58-9aeb-b90e7c24fcba' // Key Vault Certificate User

// resource namespace 'Microsoft.EventHub/namespaces@2022-10-01-preview' existing = {
//   name: namespaceName
// }

// resource eventHub 'Microsoft.EventHub/namespaces/eventhubs@2022-10-01-preview' existing = {
//   name: eventHubName
//   parent: namespace
// }

resource keyVault 'Microsoft.KeyVault/vaults@2021-10-01' existing = {
  name: keyVaultName
}

resource eventHubPolicy 'Microsoft.EventHub/namespaces/eventhubs/authorizationRules@2022-01-01-preview' existing = {
  name: '${namespaceName}/${eventHubName}/${eventHubSendPolicyName}'
}

resource secretResource 'Microsoft.KeyVault/vaults/secrets@2022-07-01' = {
  parent: keyVault
  name: 'EVENTHUB-CONNECTION'
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
