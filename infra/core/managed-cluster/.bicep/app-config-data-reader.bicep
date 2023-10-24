@description('Required. The parameter object for the managed identity. The object must contain the name and principalId values.')
param principalId string
@description('Required. The name of the app configuration service.')
param appConfigName string

resource appconfig 'Microsoft.AppConfiguration/configurationStores@2023-03-01' existing = {
  name: appConfigName
}

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, principalId, 'appConfigurationDataReader')
  scope: appconfig
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '516239f1-63e1-4d78-a4de-a74fb236a071') // App Configuration Data Reader
    principalId: principalId
    principalType: 'ServicePrincipal'
  }
}
