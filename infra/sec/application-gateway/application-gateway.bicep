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

@description('Required. Name of the log analytics workspace.')
param logAnalyticsWorkspaceName string

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

@description('Required. Boolean value to enable resource lock.')
param resourceLockEnabled bool

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

var publicIpTags = {
  Name: name
  Purpose: 'Public IP for ADP Application Gateway'
  Tier: 'Shared'
}

var appGatewayWafTags = {
  Name: wafPolicyName
  Purpose: 'ADP Application Gateway Custom WAF'
  Tier: 'Shared'
}

var applicationGatewayID = '${resourceGroup().id}/providers/Microsoft.Network/applicationGateways/${name}'

resource publicIpAddress 'Microsoft.Network/publicIPAddresses@2023-09-01' = {
  name: publicIPName
  location: location
  tags: union(tags, publicIpTags)
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }
  zones: ['1','2','3']
  properties: {
    publicIPAddressVersion: 'IPv4'
    publicIPAllocationMethod: 'Static'
    idleTimeoutInMinutes: 4
  }
}

module applicationGatewayWebApplicationFirewallPolicy 'br/SharedDefraRegistry:network.application-gateway-web-application-firewall-policy:0.5.6' = {
  name: 'agwaf-${deploymentDate}'
  params: {
    name: wafPolicyName
    location: location
    tags: union(tags, appGatewayWafTags)
    managedRules: {
      managedRuleSets: managedRuleSets
    }
    customRules: [
      {
          name: 'blockNonAFDTraffic'
          priority: 2
          ruleType: 'MatchRule'
          action: 'Block'
          matchConditions: [
              {
                  matchVariables: [
                      {
                          variableName: 'RequestHeaders'
                          selector: 'X-Azure-FDID'
                      }
                  ]
                  operator: 'Equal'
                  negationConditon: true
                  matchValues: [
                    frontDoorId
                  ]
                  transforms: [
                      'Lowercase'
                  ]
              }
          ]
          state: 'Enabled'
      }
  ]
    policySettings: {
      fileUploadLimitInMb: 10
      mode: policySettings.mode
      state: policySettings.state
    }
  }
}

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' existing = {
  name: toLower(logAnalyticsWorkspaceName)
}


module applicationGateway 'br/SharedDefraRegistry:network.application-gateway:0.5.15' = {
  name: 'application-gateway-${deploymentDate}'
  dependsOn: [
    publicIpAddress
  ]
  params: {
    name: name
    location: location
    sku: sku
    enableHttp2: true
    lock: resourceLockEnabled ? {
      kind: 'CanNotDelete'
      name: 'CanNotDelete'
    } : null
    tags: union(tags, applicationGatewayTags)
    diagnosticSettings : [
      {
        name: 'customSetting'
        workspaceResourceId: logAnalyticsWorkspace.id
      }
    ]
    firewallPolicyId: applicationGatewayWebApplicationFirewallPolicy.outputs.resourceId
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
    httpListeners: [for backend in backends: {
        name: '${backend.name}-listener'
        properties: {
          frontendIPConfiguration: {
            id: '${applicationGatewayID}/frontendIPConfigurations/public_frontend'
          }
          frontendPort: {
            id: '${applicationGatewayID}/frontendPorts/http_80'
          }
          hostNames: backend.httpListener.hostNames
          protocol: backend.httpListener.protocol
          requireServerNameIndication: backend.httpListener.requireServerNameIndication
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
  }
}

