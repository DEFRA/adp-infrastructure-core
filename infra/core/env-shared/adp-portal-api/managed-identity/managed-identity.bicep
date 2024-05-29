@description('Optional. Name of the User Assigned Identity.')
param managedIdentity object

@description('Required. The name of the container registry.')
param containerRegistry object

@description('Required. The name of the Key vault.')
param appKeyVault object

@description('Required. The name of the Key vault.')
param platformKeyVault object

@description('Required. List of secrects to be Rbac to the managed identity.')
param secrets array = []

@description('Optional. Location for all resources.')
param location string = resourceGroup().location

@description('Required. Environment name.')
param environment string

@description('Optional. Array of role assignment objects that contain the \'roleDefinitionIdOrName\' and \'principalId\' to define RBAC role assignments on this resource. In the roleDefinitionIdOrName attribute, you can provide either the display name of the role definition, or its fully qualified ID in the following format: \'/providers/Microsoft.Authorization/roleDefinitions/c2f4ef07-c644-48eb-af81-4b1b4947fb11\'.')
param roleAssignments array = []

@description('Optional. Date in the format yyyyMMdd-HHmmss.')
param deploymentDate string = utcNow('yyyyMMdd-HHmmss')

@description('Optional. Date in the format yyyy-MM-dd.')
param createdDate string = utcNow('yyyy-MM-dd')

@description('Optional. Application Insights object.')
param appInsights object


var customTags = {
  Location: location
  CreatedDate: createdDate
  Environment: environment
}

var defaultTags = union(json(loadTextContent('../../../../common/default-tags.json')), customTags)

var managedIdentityTags = {
  Name: managedIdentity.name
  Purpose: 'ADP Platform Managed Identity'
  Tier: 'Shared'
}

module managedIdentities 'br/SharedDefraRegistry:managed-identity.user-assigned-identity:0.4.3' = {
  name: 'managed-identity-${deploymentDate}'
  params: {
    name: managedIdentity.name
    tags: union(defaultTags, managedIdentityTags)
    lock: 'CanNotDelete'
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

module appKvSecretsUserRoleAssignment '../../.bicep/kv-role-secrets-user.bicep' = {
  name: '${appKeyVault.Name}-secrets-user-role-${deploymentDate}'
  scope: resourceGroup(appKeyVault.subscriptionId, appKeyVault.resourceGroup)
  dependsOn: [
    managedIdentities
  ]
  params: {
    principalId: managedIdentities.outputs.principalId 
    keyVaultName: '${appKeyVault.Name}'
  }
}

module appKvSecretsSecretsUserRoleAssignment '../../.bicep/kv-secrect-role-secrets-user.bicep' = [for (secret, index) in secrets: {
  name: '${platformKeyVault.Name}-secrect-user-role-${deploymentDate}-${index}'
  scope: resourceGroup(platformKeyVault.subscriptionId, platformKeyVault.resourceGroup)
  dependsOn: [
    managedIdentities
  ]
  params: {
    principalId: managedIdentities.outputs.principalId 
    keyVaultName: '${platformKeyVault.Name}'
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

