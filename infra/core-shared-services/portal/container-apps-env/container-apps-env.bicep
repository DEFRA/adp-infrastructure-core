@description('Required. The object of the PostgreSQL Flexible Server. The object must contain name,storageSizeGB and highAvailability properties.')
param containerAppEnv object

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
  Name: containerAppEnv.name
  Purpose: 'Container App Env'
  Tier: 'Shared'
}

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2021-06-01' existing = if (!empty(containerAppEnv.logAnalyticsWorkspaceResourceId)) {
  name: last(split(containerAppEnv.logAnalyticsWorkspaceResourceId, '/'))!
  scope: resourceGroup(split(containerAppEnv.logAnalyticsWorkspaceResourceId, '/')[2], split(containerAppEnv.logAnalyticsWorkspaceResourceId, '/')[4])
}

var internal= true
var infrastructureSubnetId = containerAppEnv.SubnetId
var dockerBridgeCidr = '172.16.0.1/28'
var workloadProfiles = containerAppEnv.workloadProfiles
var zoneRedundant = false
var logsDestination = 'log-analytics'
var infrastructureResourceGroupName = ''

resource managedEnvironment 'Microsoft.App/managedEnvironments@2023-05-01' = {
  name: containerAppEnv.name
  location: location
  tags: union(defaultTags, additionalTags)
  properties: {
    appLogsConfiguration: {
      destination: logsDestination
      logAnalyticsConfiguration: {
        customerId: logAnalyticsWorkspace.properties.customerId
        sharedKey: logAnalyticsWorkspace.listKeys().primarySharedKey
      }
    }
    vnetConfiguration: {
      internal: internal
      infrastructureSubnetId: !empty(infrastructureSubnetId) && internal == true ? infrastructureSubnetId : null
      dockerBridgeCidr: !empty(infrastructureSubnetId) && internal == true ? dockerBridgeCidr : null      
    }
    workloadProfiles: !empty(workloadProfiles) ? workloadProfiles : null
    zoneRedundant: zoneRedundant
    infrastructureResourceGroup: empty(infrastructureResourceGroupName) ? take('ME_${resourceGroup().name}_${containerAppEnv.name}', 63) : infrastructureResourceGroupName
  }
}

// module managedEnvironment 'br/SharedDefraRegistry:app.managed-environment:0.4.8' = {
//   name: '${containerAppEnv.name}-${deploymentDate}'
//   params: { 
//     // Required parameters
//     enableDefaultTelemetry: false
//     logAnalyticsWorkspaceResourceId: containerAppEnv.logAnalyticsWorkspaceResourceId
//     name: '${containerAppEnv.name}'
//     // Non-required parameters
//     dockerBridgeCidr: '172.16.0.1/28'
//     infrastructureSubnetId: containerAppEnv.SubnetId
//     internal: true
//     location: location
//     lock: {
//       kind: 'CanNotDelete'
//       name: '${containerAppEnv.name}-CanNotDelete'
//     }
//     platformReservedCidr: '172.17.17.0/24'
//     platformReservedDnsIP: '172.17.17.17'
//     //skuName: containerAppEnv.skuName
//     workloadProfiles : containerAppEnv.workloadProfiles
//     tags: union(defaultTags, additionalTags)
//   }
// }
