@description('Required. The parameter object for the virtual network. The object must contain the name,skuName,resourceGroup and subnetPrivateEndpoints values.')
param vnet object

@description('Optional. Name of the User Assigned Identity.')
param name object

@description('Optional. Location for all resources.')
param location string = resourceGroup().location

@description('Required. Environment name.')
param environment string

@description('Optional. Array of role assignment objects that contain the \'roleDefinitionIdOrName\' and \'principalId\' to define RBAC role assignments on this resource. In the roleDefinitionIdOrName attribute, you can provide either the display name of the role definition, or its fully qualified ID in the following format: \'/providers/Microsoft.Authorization/roleDefinitions/c2f4ef07-c644-48eb-af81-4b1b4947fb11\'.')
param roleAssignments array = []

@description('Optional. Enable telemetry via a Globally Unique Identifier (GUID).')
param enableDefaultTelemetry bool = true

@description('Optional. Date in the format yyyyMMdd-HHmmss.')
param deploymentDate string = utcNow('yyyyMMdd-HHmmss')

@description('Optional. Date in the format yyyy-MM-dd.')
param createdDate string = utcNow('yyyy-MM-dd')

var customTags = {
  Location: location
  CreatedDate: createdDate
  Environment: environment
}

var defaultTags = union(json(loadTextContent('../default-tags.json')), customTags)

var managedIdentityTags = {
  Name: managedIdentity.name
  Purpose: 'Managed Identity'
  Tier: 'Shared'
}

module managedIdentities 'br/SharedDefraRegistry:storage.storage-accounts:0.5.8' = {
  name: 'managed-identityunt-${deploymentDate}'
  params: {
    enableDefaultTelemetry: enableDefaultTelemetry
    name: manageIndentity.name
    tags: union(defaultTags, managedIdentityTags)
    lock: 'CanNotDelete'
    roleAssignments: [
      {
        roleDefinitionIdOrName: 'Reader'
        principalIds: [
          nestedDependencies.outputs.managedIdentityPrincipalId
        ]
        principalType: 'ServicePrincipal'
      }
    ]
  }
}
