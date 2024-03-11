@description('Required. Name of Front Door Profile.')
param name string

@description('Required. The pricing tier of the FrontDoor profile.')
@allowed([
  'Premium_AzureFrontDoor'
])
param sku string

@description('Required. Environment name.')
param environment string

@description('Required. Array of objects containing the endpoint details.')
param endpoints array

@description('Optional. Array of rule set objects.')
param ruleSets array

@description('Optional. Date in the format yyyyMMdd-HHmmss.')
param deploymentDate string = utcNow('yyyyMMdd-HHmmss')

@description('Optional. Date in the format yyyy-MM-dd.')
param createdDate string = utcNow('yyyy-MM-dd')

@description('Optional. The Azure region where the resources will be deployed.')
param location string = resourceGroup().location

var customTags = {
  Location: location
  CreatedDate: createdDate
  Environment: environment
}
var tags = union(loadJsonContent('../../../common/default-tags.json'), customTags)

var frontDoorTags = {
  Name: name
  Purpose: 'ADP Application Gateway'
  Tier: 'Shared'
}

module frontDoor 'br/SharedDefraRegistry:cdn.profile:0.4.4-prerelease' = {
  name: 'front-door-${deploymentDate}'
  params: {
    enableDefaultTelemetry: true
    name: name
    location: location
    afdEndpoints: map(endpoints, endpoint => {
        name: endpoint
      })
    lock: 'CanNotDelete'
    tags: union(tags, frontDoorTags)
    sku: sku
    ruleSets: ruleSets
  }
}
