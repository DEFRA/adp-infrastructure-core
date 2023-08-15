@description('Required. The parameter object for build agent vmss. The object must contain the name, userName, osDisk, osType, sku and imageId values.')
param buildAgent object

@description('Required. The parameter object for nic details. The object must contain nicSuffix and ipConfigurations values.')
param nicConfigurations array

@secure()
@description('Required. The password to access build agent vmss.')
param adminPassword string

@description('Optional. The Azure region where the resources will be deployed.')
param location string = resourceGroup().location

@description('Required. Environment name.')
param environment string

@description('Optional. Date in the format yyyyMMdd-HHmmss.')
param deploymentDate string = utcNow('yyyyMMdd-HHmmss')

@description('Optional. Date in the format yyyy-MM-dd.')
param createdDate string = utcNow('yyyy-MM-dd')

var tags = union(loadJsonContent('../default-tags.json'), {
  Location: location
  CreatedDate: createdDate
  Environment: environment
})

var buildAgentTags = {
  Name: buildAgent.name
  Purpose: 'ADO Build Agent'
  Tier: 'Shared'
}

module privateBuildAgent 'br/SharedDefraRegistry:compute.virtual-machine-scale-sets:0.6.7' = {
  name: 'build-agent-${deploymentDate}'  
  params: {
    name: buildAgent.name
    adminUsername: buildAgent.userName
    adminPassword: adminPassword
    imageReference: {
      id: buildAgent.imageId
    }
    nicConfigurations: nicConfigurations
    skuCapacity: 2
    osDisk: buildAgent.osDisk
    osType: buildAgent.osType
    skuName: buildAgent.sku
    tags: union(tags, buildAgentTags)
  }
}
