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

param wafPolicyName = '#{{ secApplicationGatewayWAFPolicyName }}'

param policySettings = {
  state: 'Enabled'
  mode: 'Prevention'
}

param managedRuleSets = [
  {
    ruleSetType: 'OWASP'
    ruleSetVersion: '3.0'
    ruleGroupOverrides: []
  }
]

param frontDoorId = '#{{ azureFrontDoorProfileFrontDoorId }}'
