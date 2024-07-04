@description('Optional. Name of the User Assigned Identity.')
param managedIdentity object

@description('Required. The name of the container registry.')
param containerRegistry object

@description('Required. The name of the Key vault.')
param keyVault object

@description('Required. List of secrects to be Rbac to the managed identity.')
param secrets array = []

@description('Optional. Location for all resources.')
param location string = resourceGroup().location

@description('Required. Environment name.')
param environment string

@description('Required. Sub Environment name.')
param subEnvironment string

@description('Optional. Array of role assignment objects that contain the \'roleDefinitionIdOrName\' and \'principalId\' to define RBAC role assignments on this resource. In the roleDefinitionIdOrName attribute, you can provide either the display name of the role definition, or its fully qualified ID in the following format: \'/providers/Microsoft.Authorization/roleDefinitions/c2f4ef07-c644-48eb-af81-4b1b4947fb11\'.')
param roleAssignments array = []

@description('Optional. Date in the format yyyyMMdd-HHmmss.')
param deploymentDate string = utcNow('yyyyMMdd-HHmmss')

@description('Optional. Date in the format yyyy-MM-dd.')
param createdDate string = utcNow('yyyy-MM-dd')

@description('Optional. Application Insights object.')
param appInsights object

@description('Required. Boolean value to enable or disable resource lock.')
param resourceLockEnabled bool

var customTags = {
  Location: location
  CreatedDate: createdDate
  Environment: environment
  SubEnvironment: subEnvironment
}

var defaultTags = union(json(loadTextContent('../../../../common/default-tags.json')), customTags)

var managedIdentityTags = {
  Name: managedIdentity.name
  Purpose: 'ADP FluxNotification Container App Managed Identity'
  Tier: 'Shared'
}

module managedIdentities 'br/SharedDefraRegistry:managed-identity.user-assigned-identity:0.4.3' = {
  name: 'managed-identity-${deploymentDate}'
  params: {
    name: managedIdentity.name
    tags: union(defaultTags, managedIdentityTags)
    lock: resourceLockEnabled ? 'CanNotDelete' : null
    roleAssignments: roleAssignments
  }
}

module sharedAcrPullRoleAssignment '../../.bicep/acr-pull.bicep' = {
  name: '${containerRegistry.Name}-acr-pull-role-${deploymentDate}'
  scope: resourceGroup(containerRegistry.subscriptionId, containerRegistry.resourceGroup)
  dependsOn: [
    managedIdentities
  ]
  params: {
    principalId: managedIdentities.outputs.principalId 
    containerRegistryName: '${containerRegistry.Name}'
  }
}

resource sharedKeyVault 'Microsoft.KeyVault/vaults@2023-02-01' existing = {
  name: keyVault.Name
}

resource clientIDSecret 'Microsoft.KeyVault/vaults/secrets@2019-09-01' = {
  name: 'CALLBACKAPI-MI-CLIENT-ID'
  parent: sharedKeyVault
  properties: {
    value: managedIdentities.outputs.clientId
  }
}

module appKvSecretsSecretsUserRoleAssignment '../../.bicep/kv-secrect-role-secrets-user.bicep' = [for (secret, index) in secrets: {
  name: '${keyVault.Name}-secrect-user-role-${deploymentDate}-${index}'
  scope: resourceGroup(keyVault.subscriptionId, keyVault.resourceGroup)
  dependsOn: [
    clientIDSecret
  ]
  params: {
    principalId: managedIdentities.outputs.principalId 
    keyVaultName: '${keyVault.Name}'
    secretName: secret
  }
}]

module appInsightsPublisherRoleAssignment '../../.bicep/appinsights-role-publisher.bicep' = {
  name: '${appInsights.name}-publisher-role-${deploymentDate}'
  scope: resourceGroup(appInsights.subscriptionId, appInsights.resourceGroup)
  dependsOn: [
    managedIdentities
  ]
  params: {
    principalId: managedIdentities.outputs.principalId 
    appInsightsName: '${appInsights.name}'
  }
}
