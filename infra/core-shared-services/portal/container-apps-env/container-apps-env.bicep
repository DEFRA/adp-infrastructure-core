@description('Required. The object of the PostgreSQL Flexible Server. The object must contain name,storageSizeGB and highAvailability properties.')
param containerApp object

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

var additionalTags = {
  Name: containerApp.name
  Purpose: 'Container App Env'
  Tier: 'Shared'
}


module managedEnvironment 'br/SharedDefraRegistry:app.managed-environment:0.4.8' = {
  name: '${containerApp.name}-${deploymentDate}'
  params: {
    // Required parameters
    enableDefaultTelemetry: false
    logAnalyticsWorkspaceResourceId: containerApp.logAnalyticsWorkspaceResourceId
    name: '${containerApp.name}'
    // Non-required parameters
    dockerBridgeCidr: '172.16.0.1/28'
    //infrastructureSubnetId: containerApp.SubnetId
    internal: true
    location: location
    lock: {
      kind: 'CanNotDelete'
      name: '${containerApp.name}-CanNotDelete'
    }
    platformReservedCidr: '172.17.17.0/24'
    platformReservedDnsIP: '172.17.17.17'
    skuName: containerApp.skuName
    workloadProfiles : containerApp.workloadProfiles
    tags: union(defaultTags, additionalTags)
  }
}
