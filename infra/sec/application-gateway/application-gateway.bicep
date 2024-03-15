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

@description('Required. backends Object(backendAddressPool, backendHttpSetting, httpListener, requestRoutingRule)')
param backends array

@description('Optional. Date in the format yyyyMMdd-HHmmss.')
param deploymentDate string = utcNow('yyyyMMdd-HHmmss')

@description('Optional. Date in the format yyyy-MM-dd.')
param createdDate string = utcNow('yyyy-MM-dd')

var customTags = {
  Location: location
  CreatedDate: createdDate
  Environment: environment
}
var tags = union(loadJsonContent('../../common/default-tags.json'), customTags)

var applicationGatewayTags = {
  Name: name
  Purpose: 'ADP Application Gateway'
  Tier: 'Shared'
}

var applicationGatewayID = '/subscriptions/${subscription().id}/resourceGroups/${resourceGroup().name}/providers/Microsoft.Network/applicationGateways/${name}'

module appGWpublicIpAddress '.bicep/public-ip-address.bicep' = {
  name: 'appGWpublicIpAddress-${deploymentDate}'
  params: {
    name: publicIPName
    location: location
    tags: tags
  }
}

module applicationGatewayWAFPolicy '.bicep/application-gateway-waf-custom.bicep' = {
name: 'applicationGatewayWAFPolicy-${deploymentDate}'
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
    firewallPolicyId: applicationGatewayWAFPolicy.outputs.applicationGatewayWAFPolicyResourceId
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
            id: resourceId('Microsoft.Network/publicIPAddresses', publicIPName)
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
    backendAddressPools: [for backend in backends: {
      name: '${backend.name}-Pool'
      properties: {
        backendAddresses: [
          {
            fqdn: backend.backendAddressPool.fqdn
          }
        ]
      }
    }]
    requestRoutingRules: [for backend in backends: {
        name: '${backend.name}-rule'
        properties: {
          backendAddressPool: {
            id: '${applicationGatewayID}/backendAddressPools/${backend.requestRoutingRule.backendAddressPool}-Pool'
          }
          backendHttpSettings: {
            id: '${applicationGatewayID}/backendHttpSettingsCollection/${backend.requestRoutingRule.backendName}-backend-setting'
          }
          httpListener: {
            id: '${applicationGatewayID}/httpListeners/${backend.requestRoutingRule.listenerName}-listener'
          }
          priority: 200
          ruleType: backend.requestRoutingRule.ruleType
        }
    }]
    probes: [for backend in backends: {
        name: '${backend.name}-health-probe'
        properties: {
          protocol: backend.backendHttpSetting.protocol
          path: backend.backendHttpSetting.probe.path
          interval: 30
          timeout: 15
          match: {
            statusCodes: [ backend.backendHttpSetting.probe.healthProbeStatusCode ]
          }
          minServers: 0          
          pickHostNameFromBackendHttpSettings: backend.backendHttpSetting.pickHostNameFromBackendAddress          
          unhealthyThreshold: 3
        }
    }]  
    httpListeners: [for backend in backends: {
        name: '${backend.name}-listener'
        properties: {
          frontendIPConfiguration: {
            id: '${applicationGatewayID}/frontendIPConfigurations/public_frontends'
          }
          frontendPort: {
            id: '${applicationGatewayID}/frontendPorts/http_80'
          }
          hostNames: backend.httpListener.hostNames
          protocol: backend.httpListener.protocol
          requireServerNameIndication: backend.httpListener.requireServerNameIndication
        }
    }]
    backendHttpSettingsCollection: [for backend in backends: {
        name: '${backend.name}-backend-setting'
        properties: {
          cookieBasedAffinity: backend.backendHttpSetting.cookieBasedAffinity
          pickHostNameFromBackendAddress: backend.backendHttpSetting.pickHostNameFromBackendAddress
          port: backend.backendHttpSetting.port
          protocol: backend.backendHttpSetting.protocol
          probe: {
            id: '${applicationGatewayID}/probes/${backend.name}-health-probe'
          }
          requestTimeout: backend.backendHttpSetting.requestTimeout
        }
    }]
    
    
  }
}

