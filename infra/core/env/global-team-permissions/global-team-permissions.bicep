@description('Required. The name of the Application Insights resource.')
param appInsightsName string

@description('Required. The name of the Application Key Vault resource.')
param appKeyVaultName string

@description('Required. The name of the Application Configuration resource.')
param appConfigurationName string

@description('Required. The principal ID of the group to assign the role to.')
param principalId string

resource appInsights 'Microsoft.Insights/components@2020-02-02-preview' existing = {
  name: appInsightsName
}

resource appKeyVault 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
  name: appKeyVaultName
}

resource appConfiguration 'Microsoft.AppConfiguration/configurationStores@2023-03-01' existing = {
  name: appConfigurationName
}

resource roleAssignmentAppInsights 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, principalId, appInsightsName, 'monitoringReader')
  scope: appInsights
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '43d0d8ad-25c7-4714-9337-8ba259a9fe05') // Monitoring Reader
    principalId: principalId
    principalType: 'Group'
  }
}

resource roleAssignmentAppKeyVault 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, principalId, appKeyVaultName, 'keyVaultReader')
  scope: appKeyVault
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '21090545-7ca7-4776-b22c-e363652d74d2') // Key Vault Reader
    principalId: principalId
    principalType: 'Group'
  }
}

resource roleAssignmentAppConfiguration 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, principalId, appConfigurationName, 'appConfigurationDataReader')
  scope: appConfiguration
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '516239f1-63e1-4d78-a4de-a74fb236a071') // App Configuration Data Reader
    principalId: principalId
    principalType: 'Group'
  }
}
