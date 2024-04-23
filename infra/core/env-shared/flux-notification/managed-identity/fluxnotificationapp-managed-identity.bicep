@description('Optional. Name of the User Assigned Identity.')
param managedIdentity object

@description('Required. The name of the container registry.')
param containerRegistry object

@description('Optional. Location for all resources.')
param location string = resourceGroup().location

@description('Required. Environment name.')
param environment string

@description('Required. Sub Environment name.')
param subEnvironment string

@description('Required. Event Hub object. The object must contain the namespaceName and eventHubName')
param eventHub object

@description('Required. Storage Account object. The object must contain the name of the storage account and container name.')
param storageAccount object

@description('Optional. Array of role assignment objects that contain the \'roleDefinitionIdOrName\' and \'principalId\' to define RBAC role assignments on this resource. In the roleDefinitionIdOrName attribute, you can provide either the display name of the role definition, or its fully qualified ID in the following format: \'/providers/Microsoft.Authorization/roleDefinitions/c2f4ef07-c644-48eb-af81-4b1b4947fb11\'.')
param roleAssignments array = []

@description('Optional. Date in the format yyyyMMdd-HHmmss.')
param deploymentDate string = utcNow('yyyyMMdd-HHmmss')

@description('Optional. Date in the format yyyy-MM-dd.')
param createdDate string = utcNow('yyyy-MM-dd')

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

module storageContainerBlobDataContributorRoleAssignment '../../.bicep/storage-container-role-blob-data-contributor.bicep' = {
  name: '${storageAccount.Name}-storage-container-role-${deploymentDate}'
  scope: resourceGroup(storageAccount.subscriptionId, storageAccount.resourceGroup)
  dependsOn: [
    managedIdentities
  ]
  params: {
    principalId: managedIdentities.outputs.principalId
    storageAccount: storageAccount
  }
}

module eventHubNamespaceDataReceiverRoleAssignment '../../.bicep/event-hub-role-data-receiver.bicep' = {
  name: '${eventHub.namespaceName}-event-hub-namespace-role-${deploymentDate}'
  scope: resourceGroup(eventHub.subscriptionId, eventHub.resourceGroup)
  dependsOn: [
    managedIdentities
  ]
  params: {
    principalId: managedIdentities.outputs.principalId
    eventHub: eventHub
  }
}
