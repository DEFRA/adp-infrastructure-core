@description('Required. The object of the Container App Env.')
param containerAppEnv object

@description('Required. The object of Log Analytics Workspace.')
param workspace object

@description('Required. The object of Subnet.')
param subnet object

// @description('Required. The object of privateLink.')
// param privateLink object

// @description('Required. The prefix for the private DNS zone.')
// param privateDnsZonePrefix string

@description('Optional. Location for all resources.')
param location string = resourceGroup().location

@description('Required. Environment name.')
param environment string

@description('Optional. Date in the format yyyy-MM-dd.')
param createdDate string = utcNow('yyyy-MM-dd')

// @description('Optional. Date in the format yyyyMMdd-HHmmss.')
// param deploymentDate string = utcNow('yyyyMMdd-HHmmss')


var customTags = {
  Location: location
  CreatedDate: createdDate
  Environment: environment
}

var defaultTags = union(json(loadTextContent('../../../../common/default-tags.json')), customTags)

var additionalTags = {
  Name: containerAppEnv.name
  Purpose: 'Container App Env'
  Tier: 'Shared'
}

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2021-06-01' existing = {
  name: workspace.name
  scope: resourceGroup(workspace.subscriptionId,workspace.resourceGroup)
}

var internal= true
var infrastructureSubnetId = resourceId(subnet.resourceGroup, 'Microsoft.Network/virtualNetworks/subnets', subnet.vnetName, subnet.Name)
var dockerBridgeCidr = '172.16.0.1/28'
var workloadProfiles = containerAppEnv.workloadProfiles
var zoneRedundant = false
//var logsDestination = 'log-analytics'
//var infrastructureResourceGroupName = take('${containerAppEnv.name}_ME', 63)

//var privateDnsZoneName = toLower('${privateDnsZonePrefix}.${location}.azurecontainerapps.io')

// resource managedEnvironment 'Microsoft.App/managedEnvironments@2023-05-01' = {
//   name: containerAppEnv.name
//   location: location
//   tags: union(defaultTags, additionalTags)
//   properties: {
//     appLogsConfiguration: {
//       destination: logsDestination
//       logAnalyticsConfiguration: {
//         customerId: logAnalyticsWorkspace.properties.customerId
//         sharedKey: logAnalyticsWorkspace.listKeys().primarySharedKey
//       }
//     }
//     vnetConfiguration: {
//       internal: internal
//       infrastructureSubnetId: !empty(infrastructureSubnetId) && internal == true ? infrastructureSubnetId : null
//       dockerBridgeCidr: !empty(infrastructureSubnetId) && internal == true ? dockerBridgeCidr : null      
//     }
//     workloadProfiles: !empty(workloadProfiles) ? workloadProfiles : null
//     zoneRedundant: zoneRedundant
//     infrastructureResourceGroup: infrastructureResourceGroupName
//   }
// }

module managedEnvironment 'br/SharedDefraRegistry:app.managed-environment:0.4.8' = {
  name: '${containerAppEnv.name}'
  params: { 
    // Required parameters
    enableDefaultTelemetry: false
    logAnalyticsWorkspaceResourceId: logAnalyticsWorkspace.id
    name: '${containerAppEnv.name}'
    // Non-required parameters
    dockerBridgeCidr: !empty(infrastructureSubnetId) && internal == true ? dockerBridgeCidr : null  
    infrastructureSubnetId: !empty(infrastructureSubnetId) && internal == true ? infrastructureSubnetId : null
    internal: true
    location: location
    lock: {
      kind: 'CanNotDelete'
      name: '${containerAppEnv.name}-CanNotDelete'
    }
    skuName: containerAppEnv.skuName
    workloadProfiles :!empty(workloadProfiles) ? workloadProfiles : null
    zoneRedundant: zoneRedundant
    tags: union(defaultTags, additionalTags)
  }
}

// resource loadBalancer 'Microsoft.Network/loadBalancers@2021-05-01' existing = {
//   name: 'capp-svc-lb'
//   scope: resourceGroup(infrastructureResourceGroupName)  
// }

// module flexibleServerDeployment 'br/SharedDefraRegistry:network.private-link-service:0.4.8' = {
//   name: 'private-link-service-${deploymentDate}'
//   params: {
//     // Required parameters
//     name: containerAppEnv.name
//     // Non-required parameters    
//     fqdns: [
//       '${containerAppEnv.name}.uksouth.azure.privatelinkservice'
//     ]
//     ipConfigurations: [
//       {
//         name: 'snet-provider-default-1'
//         properties: {
//           privateIPAllocationMethod: 'Dynamic'
//           subnet: {
//             id: infrastructureSubnetId
//           }
//           primary: true
//           privateIPAddressVersion: 'IPv4'
//         }
//       }
//     ]
//     loadBalancerFrontendIpConfigurations: [
//       {
//         id: loadBalancer.properties.frontendIPConfigurations[0].id
//       }
//     ]
//     lock: {
//       kind: 'CanNotDelete'
//       name: '${privateLink.name}-CanNotDelete'
//     }
//     tags: union(defaultTags, customTags)
//     visibility: privateLink.visibility
//   }
//   dependsOn: [
//     managedEnvironment
//   ]
// }


// var dnsTags = {
//   Name: privateDnsZoneName
//   Purpose: 'Private DNS Zone'
// }
// var dnsVnetLinksTags = {
//   Name: subnet.vnetName 
//   Purpose: 'Private DNS Zone VNet Link'
// }

// module privateDnsZoneModule 'br/SharedDefraRegistry:network.private-dns-zone:0.5.2' = {
//   name: 'private-dns-zone-${deploymentDate}'
//   params: {
//    name: privateDnsZoneName  
//    lock: 'CanNotDelete'
//    tags:union(defaultTags, additionalTags,dnsTags)
//    virtualNetworkLinks: [
//     {
//       name: subnet.vnetName 
//       virtualNetworkResourceId: resourceId(subnet.resourceGroup , 'Microsoft.Network/virtualNetworks', subnet.vnetName )
//       registrationEnabled: false
//       tags: union(defaultTags, additionalTags,dnsVnetLinksTags)
//     }
//    ]
//   }
// }


