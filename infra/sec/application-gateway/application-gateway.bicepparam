using './application-gateway.bicep'

param name = '#{{ secApplicationGatewayName }}'

param environment = '#{{ environment }}'

param location = '#{{ location }}'

param vnet = {
  name: '#{{ secVirtualNetworkName }}'
  resourceGroup: '#{{ secVirtualNetworkResourceGroup }}'
  subnetApplicationGateway: '#{{ secAppGatewaySubnetName }}'
}

param publicIPName = '#{{ secAppGWpublicIPName }}'

param wafPolicyName = '#{{ secApplicationGatewayWAFPolicyName }}'

param policySettings = {
  state: 'Enabled'
  mode: 'Prevention'
}

param diagnosticSettings = {
  workspacename: '#{{ logAnalyticsWorkspace }}'
  resourceGroup: '#{{ servicesResourceGroup }}'
}


param frontDoorId = '#{{ azureFrontDoorProfileFrontDoorId }}'

param backends = [
  {
    name: 'portal-web'
    backendAddressPool: {
      fqdn: '#{{ containerAppIngressFqdn }}'
    }
    backendHttpSetting: {
      port: 443
      protocol: 'Https'
      cookieBasedAffinity: 'Disabled'
      pickHostNameFromBackendAddress: true
      requestTimeout: 20
      probe: {
        path: '/'
        healthProbeStatusCode: '200-404'
      }
    }
    httpListener: {
      protocol: 'Http'
      hostNames: []
      requireServerNameIndication: false
    }
    requestRoutingRule: {
      backendAddressPool: 'portal-web'
      listenerName: 'portal-web'
      backendName: 'portal-web'
      ruleType: 'Basic'
      priority: 1
    }
  }
]
