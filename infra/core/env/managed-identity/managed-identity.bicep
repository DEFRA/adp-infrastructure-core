@description('Required. The Object of the Managed Identities to create. Must contain the following properties: name, tags, roleAssignments.')
param managedIdentities array

@description('Optional. Location for all resources.')
param location string = resourceGroup().location

@description('Required. Environment name.')
param environment string

@description('Optional. Date in the format yyyyMMdd-HHmmss.')
param deploymentDate string = utcNow('yyyyMMdd-HHmmss')

@description('Optional. Date in the format yyyy-MM-dd.')
param createdDate string = utcNow('yyyy-MM-dd')

var customTags = {
  Location: location
  CreatedDate: createdDate
  Environment: environment
}

var defaultTags = union(json(loadTextContent('../../../common/default-tags.json')), customTags)

module moduleManagedIdentity 'br/SharedDefraRegistry:managed-identity.user-assigned-identity:0.4.3' = [for (managedIdentity,index) in managedIdentities: {
  name: 'managed-identity-${index}-${deploymentDate}'
  params: {
    name: managedIdentity.name
    tags: union(defaultTags, { Name: managedIdentity.name} , managedIdentity.tags)
    lock: 'CanNotDelete'
    roleAssignments: managedIdentity.roleAssignments
  }
}]
