@description('Required. The object of the Container App Env.')
param containerAppEnv object

@description('Required. The object of the Container App.')
param containerApp object

@description('Required. The object of Log Analytics Workspace.')
param workspace object

@description('Required. The object of Subnet.')
param subnet object

@description('Optional. Location for all resources.')
param location string = resourceGroup().location

@description('Required. Environment name.')
param environment string

@description('Optional. Date in the format yyyy-MM-dd.')
param createdDate string = utcNow('yyyy-MM-dd')

@description('Required. The name of the key vault where the secrets will be stored.')
param keyvaultName string

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
  scope: resourceGroup(workspace.subscriptionId, workspace.resourceGroup)
}

resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' existing = {
  name: containerApp.managedIdentityName
}

var internal = false
var infrastructureSubnetId = resourceId(subnet.resourceGroup, 'Microsoft.Network/virtualNetworks/subnets', subnet.vnetName, subnet.Name)
var dockerBridgeCidr = '172.16.0.1/28'
var workloadProfiles = containerAppEnv.workloadProfiles
var zoneRedundant = false
var logsDestination = 'log-analytics'
var infrastructureResourceGroupName = take('${containerAppEnv.name}_ME', 63)

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
      infrastructureSubnetId: !empty(infrastructureSubnetId) ? infrastructureSubnetId : null
      dockerBridgeCidr: !empty(infrastructureSubnetId) ? dockerBridgeCidr : null
    }
    workloadProfiles: !empty(workloadProfiles) ? workloadProfiles : null
    zoneRedundant: zoneRedundant
    infrastructureResourceGroup: infrastructureResourceGroupName
  }
}

// module managedEnvironment 'br/SharedDefraRegistry:app.managed-environment:0.4.8' = {
//   name: '${containerAppEnv.name}'
//   params: { 
//     // Required parameters
//     enableDefaultTelemetry: false
//     logAnalyticsWorkspaceResourceId: logAnalyticsWorkspace.id
//     name: '${containerAppEnv.name}'
//     // Non-required parameters
//     dockerBridgeCidr: !empty(infrastructureSubnetId) && internal == true ? dockerBridgeCidr : null  
//     infrastructureSubnetId: !empty(infrastructureSubnetId) && internal == true ? infrastructureSubnetId : null
//     internal: false
//     location: location
//     lock: {
//       kind: 'CanNotDelete'
//       name: '${containerAppEnv.name}-CanNotDelete'
//     }
//     skuName: containerAppEnv.skuName
//     workloadProfiles :!empty(workloadProfiles) ? workloadProfiles : null
//     zoneRedundant: zoneRedundant
//     tags: union(defaultTags, additionalTags)
//   }
// }

resource initContainerApp 'Microsoft.App/containerApps@2023-05-01' = {
  name: '${containerApp.name}'
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${managedIdentity.id}': {}
    }
  }
  properties: {
    environmentId: managedEnvironment.id
    configuration: {
      ingress: {
        external: true
        targetPort: 80
      }
    }
    template: {
      containers: [
        {
          name: '${containerApp.name}'
          image: 'mcr.microsoft.com/azuredocs/containerapps-helloworld:latest'
        }
      ]
    }
  }
}

resource keyVault 'Microsoft.KeyVault/vaults@2023-02-01' existing = {
  name: keyvaultName
}

resource secretbaseurl 'Microsoft.KeyVault/vaults/secrets@2019-09-01' = {
  name: 'APP-DEFAULT-URL'
  parent: keyVault
  properties: {
    value: 'https://${containerApp.name}.${toLower(managedEnvironment.properties.defaultDomain)}'
  }
}