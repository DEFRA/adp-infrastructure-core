@description('Optional. Name of the User Assigned Identity.')
param managedIdentity object

@description('Optional. Location for all resources.')
param location string = resourceGroup().location

@description('Required. Environment name.')
param environment string

@description('The principal ID of the created Managed Identity.')
output managedIdentityPrincipalId string = managedIdentity.properties.principalId

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
  Purpose: 'ADP Platform Managed Identity'
  Tier: 'Shared'
}

module managedIdentities 'br/SharedDefraRegistry:managed-identity.user-assigned-identities:0.4.6' = {
  name: 'managed-identity-${deploymentDate}'
  params: {
    name: managedIdentity.name
    tags: union(defaultTags, managedIdentityTags)
    lock: 'CanNotDelete'
  }
}

module mi_roleAssignments 'br/SharedDefraRegistry:authorization.role-assignments:0.4.6' = [for (roleAssignment, index) in roleAssignments: {
  name: '{mi-role-assignment-${deploymentDate}'
  params: {
    principalIds: [
      nestedDependencies.outputs.managedIdentityPrincipalId
    ]
    principalType: 'ServicePrincipal' 
    roleDefinitionIdOrName: roleDefinitionResourceId
  }
}]

