
param name string

param location string

param tags object

var publicIpTags = {
  Name: name
  Purpose: 'Public IP for ADP Application Gateway'
  Tier: 'Shared'
}


resource publicIpAddress 'Microsoft.Network/publicIPAddresses@2023-09-01' = {
  name: name
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

@description('The public IP address of the public IP address resource.')
output ipAddress string = contains(publicIpAddress.properties, 'ipAddress') ? publicIpAddress.properties.ipAddress : ''

