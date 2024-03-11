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

param backendAddressPools array

param backendHttpSettingsCollections array

param httpListeners array

param requestRoutingRules array

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

module applicationGateway 'br/SharedDefraRegistry:network.application-gateway:0.5.15' = {
  name: 'application-gateway-${deploymentDate}'
  dependsOn: [
    appGWpublicIpAddress
  ]
  params: {
    // Required parameters
    name: name
    // Non-required parameters
    location: location
    sku: sku
    enableDefaultTelemetry: '<enableDefaultTelemetry>'
    enableHttp2: true
    lock: {
      kind: 'CanNotDelete'
      name: 'myCustomLockName'
    }
    tags: union(tags, applicationGatewayTags)
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
    backendAddressPools: [for backendAddressPool in backendAddressPools: {
      name: '${backendAddressPool.name}-Pool'
      properties: {
        backendAddresses: [
          {
            fqdn: backendAddressPool.fqdn
          }
        ]
      }
    }]
    probes: [for backendHttpSettingsCollection in backendHttpSettingsCollections: {
        name: '${backendHttpSettingsCollection.name}-health-probe'
        properties: {
          protocol: backendHttpSettingsCollection.protocol
          path: backendHttpSettingsCollection.probe.path
          interval: 30
          timeout: 15
          match: {
            statusCodes: [ backendHttpSettingsCollection.probe.healthProbeStatusCode ]
          }
          minServers: 0          
          pickHostNameFromBackendHttpSettings: backendHttpSettingsCollection.pickHostNameFromBackendAddress          
          unhealthyThreshold: 3
        }
    }]  
    backendHttpSettingsCollection: [for backendHttpSettingsCollection in backendHttpSettingsCollections: {
        name: '${backendHttpSettingsCollection.name}-backend-setting'
        properties: {
          cookieBasedAffinity: backendHttpSettingsCollection.cookieBasedAffinity
          pickHostNameFromBackendAddress: backendHttpSettingsCollection.pickHostNameFromBackendAddress
          port: backendHttpSettingsCollection.port
          protocol: backendHttpSettingsCollection.protocol
          probe: {
            id: resourceId('Microsoft.Network/applicationGateways', name , '/probes', '${backendHttpSettingsCollection.name}-health-probe')
          }
          requestTimeout: backendHttpSettingsCollection.requestTimeout
        }
    }]
    httpListeners: [for httpListener in httpListeners: {
        name: '${httpListener.name}-listener'
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/applicationGateways', name , '/frontendIPConfigurations/public_frontends')
          }
          frontendPort: {
            id: resourceId('Microsoft.Network/applicationGateways', name , '/frontendPorts/http_80')
          }
          hostNames: httpListener.hostNames
          protocol: httpListener.protocol
          requireServerNameIndication: httpListener.requireServerNameIndication
        }
    }]
    requestRoutingRules: [for requestRoutingRule in requestRoutingRules: {
        name: '${requestRoutingRule.name}-rule'
        properties: {
          backendAddressPool: {
            id: resourceId('Microsoft.Network/applicationGateways', name , '/backendAddressPools/${requestRoutingRule.backendAddressPool}-Pool')
          }
          backendHttpSettings: {
            id: resourceId('Microsoft.Network/applicationGateways', name , '/backendHttpSettingsCollection/${requestRoutingRule.backendName}-backend-setting')
          }
          httpListener: {
            id: resourceId('Microsoft.Network/applicationGateways', name , '/httpListeners/${requestRoutingRule.listenerName}-listener')
          }
          priority: 200
          ruleType: requestRoutingRule.ruleType
        }
    }]
    
    // privateLinkConfigurations: [
    //   {
    //     id: '<id>'
    //     name: 'pvtlink01'
    //     properties: {
    //       ipConfigurations: [
    //         {
    //           id: '<id>'
    //           name: 'privateLinkIpConfig1'
    //           properties: {
    //             primary: false
    //             privateIPAllocationMethod: 'Dynamic'
    //             subnet: {
    //               id: '<id>'
    //             }
    //           }
    //         }
    //       ]
    //     }
    //   }
    // ]

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
    // managedIdentities: {
    //   userAssignedResourceIds: [
    //     '<managedIdentityResourceId>'
    //   ]
    // }
    // privateEndpoints: [
    //   {
    //     privateDnsZoneResourceIds: [
    //       '<privateDNSZoneResourceId>'
    //     ]
    //     service: 'public'
    //     subnetResourceId: '<subnetResourceId>'
    //     tags: {
    //       Environment: 'Non-Prod'
    //       Role: 'DeploymentValidation'
    //     }
    //   }
    // ]    
    // redirectConfigurations: [
    //   {
    //     name: 'httpRedirect80'
    //     properties: {
    //       includePath: true
    //       includeQueryString: true
    //       redirectType: 'Permanent'
    //       requestRoutingRules: [
    //         {
    //           id: '<id>'
    //         }
    //       ]
    //       targetListener: {
    //         id: '<id>'
    //       }
    //     }
    //   }
    //   {
    //     name: 'httpRedirect8080'
    //     properties: {
    //       includePath: true
    //       includeQueryString: true
    //       redirectType: 'Permanent'
    //       requestRoutingRules: [
    //         {
    //           id: '<id>'
    //         }
    //       ]
    //       targetListener: {
    //         id: '<id>'
    //       }
    //     }
    //   }
    // ]    
    // rewriteRuleSets: [
    //   {
    //     id: '<id>'
    //     name: 'customRewrite'
    //     properties: {
    //       rewriteRules: [
    //         {
    //           actionSet: {
    //             requestHeaderConfigurations: [
    //               {
    //                 headerName: 'Content-Type'
    //                 headerValue: 'JSON'
    //               }
    //               {
    //                 headerName: 'someheader'
    //               }
    //             ]
    //             responseHeaderConfigurations: []
    //           }
    //           conditions: []
    //           name: 'NewRewrite'
    //           ruleSequence: 100
    //         }
    //       ]
    //     }
    //   }
    // ]
    // roleAssignments: [
    //   {
    //     principalId: '<principalId>'
    //     principalType: 'ServicePrincipal'
    //     roleDefinitionIdOrName: 'Owner'
    //   }
    //   {
    //     principalId: '<principalId>'
    //     principalType: 'ServicePrincipal'
    //     roleDefinitionIdOrName: 'b24988ac-6180-42a0-ab88-20f7382dd24c'
    //   }
    //   {
    //     principalId: '<principalId>'
    //     principalType: 'ServicePrincipal'
    //     roleDefinitionIdOrName: '<roleDefinitionIdOrName>'
    //   }
    // ]
  
    // sslCertificates: [
    //   {
    //     name: 'az-apgw-x-001-ssl-certificate'
    //     properties: {
    //       keyVaultSecretId: '<keyVaultSecretId>'
    //     }
    //   }
    // ]

    // webApplicationFirewallConfiguration: {
    //   disabledRuleGroups: [
    //     {
    //       ruleGroupName: 'Known-CVEs'
    //     }
    //     {
    //       ruleGroupName: 'REQUEST-943-APPLICATION-ATTACK-SESSION-FIXATION'
    //     }
    //     {
    //       ruleGroupName: 'REQUEST-941-APPLICATION-ATTACK-XSS'
    //     }
    //   ]
    //   enabled: true
    //   exclusions: [
    //     {
    //       matchVariable: 'RequestHeaderNames'
    //       selector: 'hola'
    //       selectorMatchOperator: 'StartsWith'
    //     }
    //   ]
    //   fileUploadLimitInMb: 100
    //   firewallMode: 'Detection'
    //   maxRequestBodySizeInKb: 128
    //   requestBodyCheck: true
    //   ruleSetType: 'OWASP'
    //   ruleSetVersion: '3.0'
    // }
  }
}
