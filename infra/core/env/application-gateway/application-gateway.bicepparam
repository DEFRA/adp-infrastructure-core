using './application-gateway.bicep'

param name = '#{{ secApplicationGatewayName }}'

param environment = '#{{ environment }}'

param location = '#{{ location }}'

param vnet = {
  name: '#{{ ssvVirtualNetworkName }}'
  resourceGroup: '#{{ ssvVirtualNetworkResourceGroup }}'
  // subnetApplicationGateway: '#{{ networkResourceNamePrefix }}#{{ nc_resource_subnet }}#{{ nc_instance_regionid }}98'
  subnetApplicationGateway: 'gateway-subnet' //temp
}

param publicIPName = '#{{ SEC$(projectName)$(environment)$(nc_resource_publicip)$(nc_instance_regionid)01 }}'

param backendAddressPools = [
  {
    name: 'portal-web'
    fqdn: 'ssvadpinfca3403-portal-web.thankfulcliff-27c655b9.uksouth.azurecontainerapps.io' //temp
  }
]

param backendHttpSettingsCollections = [
  {
    name: 'portal-web'
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
]

param httpListeners = [
  {
    name: 'portal-web'
    protocol: 'Http'
    hostNames: []
    requireServerNameIndication: false
  }
]

param requestRoutingRules = [
  {
    name: 'portal-web'
    backendAddressPool: 'portal-web' 
    listenerName: 'portal-web'
    backendName: 'portal-web'
    ruleType: 'Basic'
    priority: 1
  }
]
