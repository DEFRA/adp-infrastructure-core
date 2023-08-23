@description('Required. Name of Front Door Profile.')
param name string

@description('Required. The pricing tier of the FrontDoor profile.')
@allowed([
  'Standard_AzureFrontDoor'
  'Premium_AzureFrontDoor'
])
param sku string

@description('Required. Environment name.')
param environment string

// @description('Optional. Date in the format yyyyMMdd-HHmmss.')
// param deploymentDate string = utcNow('yyyyMMdd-HHmmss')

@description('Optional. Date in the format yyyy-MM-dd.')
param createdDate string = utcNow('yyyy-MM-dd')

@description('Optional. The Azure region where the resources will be deployed.')
param location string = resourceGroup().location
var lock = 'CanNotDelete'
var customTags = {
  Location: location
  CreatedDate: createdDate
  Environment: environment
}
var tags = union(loadJsonContent('../default-tags.json'), customTags)

var frontDoorTags = {
  Name: name
  Purpose: 'ADP Core Front Door'
  Tier: 'Shared'
}

// module frontDoor 'br/SharedDefraRegistry:cdn.profiles:0.4.0' = {
//   name: 'front-door-${deploymentDate}'
//   params: {
//     name: name
//     location: location
//     lock: 'CanNotDelete'
//     tags: union(tags, frontDoorTags)
//     sku: sku
//   }

resource frontDoor 'Microsoft.Cdn/profiles@2021-06-01' = {
  name: name
  location: location
  sku: {
    name: sku
  }
  tags: union(tags, frontDoorTags)
}

resource profile_lock 'Microsoft.Authorization/locks@2020-05-01' = if (!empty(lock)) {
  name: '${frontDoor.name}-${lock}-lock'
  properties: {
    level: any(lock)
    notes: lock == 'CanNotDelete' ? 'Cannot delete resource or child resources.' : 'Cannot modify the resource or child resources.'
  }
  scope: frontDoor
}

