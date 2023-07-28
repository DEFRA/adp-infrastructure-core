// Parameters
// param <parameter-name> <parameter-data-type> = <default-value>
@description('''
Targeted Environment, allowed values:
  - SND
  - SND2
  - DEV
  - PRE
  - PRD
''')
@allowed([
  'SND'
  'SND2'
  'DEV'
  'PRE'
  'PRD'
])
param envCode string

@description('Location to deploy resources into')
param location string = resourceGroup().location

@description('REQUIRED: Project eg imports = IMP, exports = EXP')
param serviceCode string

@description('The descriptive name of the Service that the ServiceCode tag denotes')
param serviceName string = 'CDO'

@description('UTC time to match tagging standard [YYYYMMDD] eg 20180215')
param lastDeployedDate string = utcNow('yyyyMMdd')

@description('REQUIRED: Subnet range for public Application Gateway')
param appGatewaySubnet string

@description('REQUIRED: Subnet range for private Application Gateway')
param privateAppGatewaySubnet string

@description('REQUIRED: Number for the subsciption')
param spokeSubNumber string

var networkSecurityGroupName = '${toUpper(envCode)}${serviceCode}NETNS${spokeSubNumber}401'
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
// Resources
module networkSecurityGroup 'br/SharedDefraRegistry:network.network-security-groups:0.4.6' = {
  name: uniqueString(networkSecurityGroupName)
  params: {
    name: networkSecurityGroupName
    location: location
    tags: {
      Name: networkSecurityGroupName
      ServiceCode: serviceCode
      ServiceName: serviceName
      CreatedDate: lastDeployedDate
      ServiceType: 'LOB'
      Environment: envCode
      Tier: 'networkSecurityGroup'
      Location: location
    }
    securityRules: securityRules
  }
}
