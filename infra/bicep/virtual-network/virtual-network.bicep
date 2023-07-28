param projectName string
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
param dnsServers string

param subnet1AddressPrefix string
param subnet2AddressPrefix string
param subnet3AddressPrefix string
param subnet5AddressPrefix string
param subnet6AddressPrefix string
param subnet7AddressPrefix string
param subnet8AddressPrefix string

param aks1RouteTableName string
param aks2RouteTableName string
param aks1RouteTableResourceGroupName string
param aks2RouteTableResourceGroupName string

// Variables
var subnetPrefix = '${envCode}${projectName}NETSU${subSpokeNumber}40'
var subnets = [ {
    name: '${subnetPrefix}1'
    addressPrefix: subnet1AddressPrefix
    routeTable: aks1RouteTableName == '' ? '' : aks1RouteTable.id
    networkSecurityGroup: nsg.id
    privateEndpointNetworkPolicies: 'Disabled'
    privateLinkServiceNetworkPolicies: 'Enabled'
    delegation: []
    serviceEndpoints: [
      'Microsoft.Storage'
      'Microsoft.Sql'
      'Microsoft.ContainerRegistry'
      'Microsoft.ServiceBus'
      'Microsoft.EventHub'
      'Microsoft.KeyVault'
    ]
  }
  {
    name: '${subnetPrefix}2'
    addressPrefix: subnet2AddressPrefix
    routeTable: ''
    networkSecurityGroup: '' //nsg1002.id
    privateEndpointNetworkPolicies: 'Disabled'
    privateLinkServiceNetworkPolicies: 'Enabled'
    delegation: []
    serviceEndpoints: [
      'Microsoft.Storage'
      'Microsoft.Sql'
      'Microsoft.ContainerRegistry'
      'Microsoft.ServiceBus'
      'Microsoft.EventHub'
      'Microsoft.KeyVault'
    ]
  }
  {
    name: '${subnetPrefix}3'
    addressPrefix: subnet3AddressPrefix
    routeTable: aks1RouteTableName == '' ? '' : aks1RouteTable.id
    networkSecurityGroup: '' //nsg1002.id
    privateEndpointNetworkPolicies: 'Enabled'
    privateLinkServiceNetworkPolicies: 'Enabled'
    delegation: []
    serviceEndpoints: []
  }
  {
    name: '${subnetPrefix}5'
    addressPrefix: subnet5AddressPrefix
    routeTable: ''
    networkSecurityGroup: ''
    privateEndpointNetworkPolicies: 'Disabled'
    privateLinkServiceNetworkPolicies: 'Enabled'
    delegation: []
    serviceEndpoints: []
  }
  {
    name: '${subnetPrefix}6'
    addressPrefix: subnet6AddressPrefix
    routeTable: ''
    networkSecurityGroup: ''
    privateEndpointNetworkPolicies: 'Disabled'
    privateLinkServiceNetworkPolicies: 'Enabled'
    delegation: [
      {
        name: 'Microsoft.Web.serverFarms'
        serviceName: 'Microsoft.Web/serverFarms'
      }
    ]
    serviceEndpoints: [
      'Microsoft.Storage'
      'Microsoft.Web'
    ]
  }
  {
    name: '${subnetPrefix}7'
    addressPrefix: subnet7AddressPrefix
    routeTable: aks2RouteTableName == '' ? '' : aks2RouteTable.id
    networkSecurityGroup: nsg.id
    privateEndpointNetworkPolicies: 'Disabled'
    privateLinkServiceNetworkPolicies: 'Enabled'
    delegation: []
    serviceEndpoints: [
      'Microsoft.Storage'
      'Microsoft.Sql'
      'Microsoft.ContainerRegistry'
      'Microsoft.ServiceBus'
      'Microsoft.EventHub'
      'Microsoft.KeyVault'
    ]
  }
  {
    name: '${subnetPrefix}8'
    addressPrefix: subnet8AddressPrefix
    routeTable: ''
    networkSecurityGroup: nsg.id
    privateEndpointNetworkPolicies: 'Disabled'
    privateLinkServiceNetworkPolicies: 'Enabled'
    delegation: []
    serviceEndpoints: [
      'Microsoft.AzureActiveDirectory'
      'Microsoft.AzureCosmosDB'
      'Microsoft.CognitiveServices'
      'Microsoft.ContainerRegistry'
      'Microsoft.EventHub'
      'Microsoft.KeyVault'
      'Microsoft.ServiceBus'
      'Microsoft.Sql'
      'Microsoft.Storage'
      'Microsoft.Web'
    ]
  } ]

// Existing Resources
resource nsg 'Microsoft.Network/networkSecurityGroups@2022-07-01' existing = {
  name: '${envCode}CDONETNS2401'
  //scope: resourceGroup('${envCode}CDONETRG${spokeNumber}401')
}

resource aks1RouteTable 'Microsoft.Network/routeTables@2022-07-01' existing = if (aks1RouteTableName != '') {
  name: aks1RouteTableName
  scope: resourceGroup(aks1RouteTableResourceGroupName)
}

resource aks2RouteTable 'Microsoft.Network/routeTables@2022-07-01' existing = if (aks2RouteTableName != '') {
  name: aks2RouteTableName
  scope: resourceGroup(aks2RouteTableResourceGroupName)
}

module vnet 'br/SharedDefraRegistry:network.virtual-networks:0.4.6' = {
  name: '${uniqueString(deployment().name, location)}-vnet'
  params: {
    name: '${envCode}CDONETVN${subSpokeNumber}401'
    location: location
    tags: tags
    addressPrefixes: addressPrefixes
    dnsServers: split(dnsServers, ';')
    subnets: subnets
  }
}
