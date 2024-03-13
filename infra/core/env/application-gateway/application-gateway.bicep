@description('Required. Name of the Application gateway.')
param name string

@description('Required. Environment name.')
param environment string

@description('Optional. The Azure region where the resources will be deployed.')
param location string = resourceGroup().location

@description('Required. The name of the SKU for the Application Gateway.')
@allowed([
  'WAF_v2'
])
param sku string = 'WAF_v2'

@description('Required. The parameter object for the virtual network. The object must contain the name,skuName,resourceGroup and subnetPrivateEndpoints values.')
param vnet object

@description('Required. Environment name.')
param publicIPName string

@description('Required. The name of the Front Door WAF Policy to create.')
param wafPolicyName string

@description('Optional. The list of managed rule sets to configure on the WAF (DRS).')
param managedRuleSets array = []

@description('Optional. The PolicySettings object (state,mode) for policy.')
param policySettings object = {
  state: 'Enabled'
  mode: 'Prevention'
}

@description('Required. The FrontDoor ID.')
param frontDoorId string

@description('Optional. Date in the format yyyyMMdd-HHmmss.')
param deploymentDate string = utcNow('yyyyMMdd-HHmmss')

@description('Optional. Date in the format yyyy-MM-dd.')
param createdDate string = utcNow('yyyy-MM-dd')

var customTags = {
  Location: location
  CreatedDate: createdDate
  Environment: environment
}
var tags = union(loadJsonContent('../../../common/default-tags.json'), customTags)

var applicationGatewayTags = {
  Name: name
  Purpose: 'ADP Application Gateway'
  Tier: 'Shared'
}

module appGWpublicIpAddress '.bicep/public-ip-address.bicep' = {
    name: 'appGWpublicIpAddress-${deploymentDate}'
    params: {
      name: publicIPName
      location: location
      tags: tags
    }
}

module applicationGatewayWAFPolicy '.bicep/application-gateway-waf-custom.bicep' = {
  name: 'appGWpublicIpAddress-${deploymentDate}'
  params: {
    wafPolicyName: wafPolicyName
    location: location
    frontDoorId: frontDoorId
    managedRuleSets: managedRuleSets
    policySettings: policySettings
    environment: environment
    purpose: 'ADP Application Gateway Custom WAF'
  }
}

module applicationGateway 'br/SharedDefraRegistry:network.application-gateway:0.5.15' = {
  name: 'application-gateway-${deploymentDate}'
  dependsOn: [
    appGWpublicIpAddress
    applicationGatewayWAFPolicy
  ]
  params: {
    name: name
    location: location
    sku: sku
    // enableDefaultTelemetry: '<enableDefaultTelemetry>'
    enableHttp2: true
    lock: {
      kind: 'CanNotDelete'
      name: 'myCustomLockName'
    }
    tags: union(tags, applicationGatewayTags)
    firewallPolicyId: applicationGatewayWAFPolicy.applicationGatewayWAFPolicyResourceId
    gatewayIPConfigurations: [
      {
        name: 'apw-ip-configuration'
        properties: {
          subnet: {
            id: resourceId(vnet.resourceGroup, 'Microsoft.Network/virtualNetworks/subnets', vnet.name, vnet.subnetApplicationGateway)
          }
        }
      }
    ]
    frontendIPConfigurations: [
      {
        name: 'public_frontend'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          // privateLinkConfiguration: {
          //   id: '<id>'
          // }
          publicIPAddress: {
            id: appGWpublicIpAddress.outputs.ipAddress
          }
        }
      }
    ]
    frontendPorts: [
      {
        name: 'http_80'
        properties: {
          port: 80
        }
      }
    ]
    // diagnosticSettings: [
    //   {
    //     eventHubAuthorizationRuleResourceId: '<eventHubAuthorizationRuleResourceId>'
    //     eventHubName: '<eventHubName>'
    //     metricCategories: [
    //       {
    //         category: 'AllMetrics'
    //       }
    //     ]
    //     name: 'customSetting'
    //     storageAccountResourceId: '<storageAccountResourceId>'
    //     workspaceResourceId: '<workspaceResourceId>'
    //   }
    // ]  
  }
}

