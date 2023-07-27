param location string = resourceGroup().location
param environment string
param serviceCode string = 'CDO'
param tags object = {
  ServiceCode: serviceCode
  Environment: environment
}
param envCode string
param subSpokeNumber string

param addressPrefixes array
param dnsServers array

@description('REQUIRED: Subnet range for public Application Gateway')
param appGatewaySubnet string

@description('REQUIRED: Subnet range for private Application Gateway')
param privateAppGatewaySubnet string

var securityRules = [
  {
    name: 'Allow_Internal_Traffic'
    properties: {
      description: 'Allow vnet traffic'
      protocol: '*'
      sourcePortRange: '*'
      destinationPortRange: '*'
      sourceAddressPrefix: 'VirtualNetwork'
      destinationAddressPrefix: 'VirtualNetwork'
      access: 'Allow'
      priority: 100
      direction: 'Inbound'
    }
  }
  {
    name: 'Allow_OpenVPN'
    properties: {
      description: 'Allow inbound from OPS subnet where APS and OPS VPNs live'
      protocol: '*'
      sourcePortRange: '*'
      destinationPortRange: '*'
      sourceAddressPrefix: '10.204.0.0/26'
      destinationAddressPrefix: 'VirtualNetwork'
      access: 'Allow'
      priority: 110
      direction: 'Inbound'
    }
  }
  {
    name: 'Allow_AGW_Subnet_Inbound'
    properties: {
      description: 'Allow inbound connectivity from the application gateway via HTTPS'
      protocol: 'Tcp'
      sourcePortRange: '*'
      destinationPortRanges: [
        '80'
        '443'
      ]
      sourceAddressPrefix: appGatewaySubnet
      destinationAddressPrefix: 'VirtualNetwork'
      access: 'Allow'
      priority: 300
      direction: 'Inbound'
    }
  }
  {
    name: 'Allow_private_AGW_Subnet_Inbound'
    properties: {
      description: 'Allow inbound connectivity from the private application gateway via HTTPS'
      protocol: 'Tcp'
      sourcePortRange: '*'
      destinationPortRanges: [
        '80'
        '443'
      ]
      sourceAddressPrefix: privateAppGatewaySubnet
      destinationAddressPrefix: 'VirtualNetwork'
      access: 'Allow'
      priority: 302
      direction: 'Inbound'
    }
  }
  {
    name: 'AllowGWM'
    properties: {
      description: 'Allow all inbound Gateway Management ports'
      protocol: '*'
      sourcePortRange: '*'
      destinationPortRange: '65200-65535'
      sourceAddressPrefix: '*'
      destinationAddressPrefix: '*'
      access: 'Allow'
      priority: 400
      direction: 'Inbound'
    }
  }
  {
    name: 'AllowAKSInternal'
    properties: {
      description: 'Allow the AKS address ranges for cluster comms'
      protocol: '*'
      sourcePortRange: '*'
      destinationPortRange: '*'
      sourceAddressPrefix: '172.0.0.0/8'
      destinationAddressPrefix: '*'
      access: 'Allow'
      priority: 410
      direction: 'Inbound'
    }
  }
  {
    name: 'AllowVnetToAKSInternal'
    properties: {
      description: 'Allow the AKS address ranges for cluster comms'
      protocol: '*'
      sourcePortRange: '*'
      destinationPortRanges: [
        '80'
        '443'
      ]
      sourceAddressPrefix: 'VirtualNetwork'
      destinationAddressPrefix: '172.0.0.0/8'
      access: 'Allow'
      priority: 411
      direction: 'Inbound'
    }
  }
  {
    name: 'Allow_Azure_Load_Balancer_Inbound'
    properties: {
      description: 'Allow Azure LB above Deny All'
      protocol: '*'
      sourcePortRange: '*'
      destinationPortRange: '*'
      sourceAddressPrefix: 'AzureLoadBalancer'
      destinationAddressPrefix: '*'
      access: 'Allow'
      priority: 1000
      direction: 'Inbound'
    }
  }
  {
    name: 'denyAll'
    properties: {
      description: 'Deny all other traffic'
      protocol: '*'
      sourcePortRange: '*'
      destinationPortRange: '*'
      sourceAddressPrefix: '*'
      destinationAddressPrefix: '*'
      access: 'Deny'
      priority: 4096
      direction: 'Inbound'
    }
  }
  {
    name: 'Allow_Internal_Traffic_Outbound'
    properties: {
      description: 'Allow internal vnet outbound'
      protocol: '*'
      sourcePortRange: '*'
      destinationPortRange: '*'
      sourceAddressPrefix: 'VirtualNetwork'
      destinationAddressPrefix: 'VirtualNetwork'
      access: 'Allow'
      priority: 100
      direction: 'Outbound'
    }
  }
  {
    name: 'Allow_NTP_Outbound_To_Azure'
    properties: {
      description: 'Allow outbound NTP to AzureCloud'
      protocol: 'Udp'
      sourcePortRange: '*'
      destinationPortRange: '123'
      sourceAddressPrefix: '*'
      destinationAddressPrefix: 'AzureCloud'
      access: 'Allow'
      priority: 200
      direction: 'Outbound'
    }
  }
]

module vnet 'br/SharedDefraRegistry:network.virtual-networks:0.4.6' = {
  name: '${uniqueString(deployment().name, location)}-vnet'
  params: {
    name: concat(envCode, 'CDONETVN', subSpokeNumber, '401')
    location: location
    tags: tags
    addressPrefixes: addressPrefixes
    dnsServers: dnsServers
  }
}

// New Resources
@batchSize(1)
module subnet 'br/SharedDefraRegistry:network.virtual-networks:0.4.6' = [for (sn, index) in subnetLoop: {
  name: uniqueString(sn.name)
  params: {
    name: sn.name
    location: location
    virtualNetworkName: virtualNetworkName
    addressPrefix: sn.addressPrefix
    delegation: sn.delegation
    routeTable: sn.routeTable
    serviceEndpoints: sn.serviceEndpoints
    networkSecurityGroup: sn.networkSecurityGroup
    privateEndpointNetworkPolicies: sn.privateEndpointNetworkPolicies
    privateLinkServiceNetworkPolicies: sn.privateLinkServiceNetworkPolicies
  }
}]
