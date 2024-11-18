@description('Required. The parameter object for the virtual network. The object must contain the name, resourceGroup and subnetPrivateEndpoints values.')
param vnet object

@description('Required. The parameter object for AI Document Intelligence. The object must contain the name and sku values.')
param aiDocumentIntelligence object

@description('Optional. Location for all resources.')
param location string = resourceGroup().location

@description('Required. Environment name.')
param environment string

@description('Optional. Date in the format yyyyMMdd-HHmmss.')
param deploymentDate string = utcNow('yyyyMMdd-HHmmss')

@description('Optional. Date in the format yyyy-MM-dd.')
param createdDate string = utcNow('yyyy-MM-dd')

@description('Required. The parameter object for the private Dns zone. The object must contain the name and resourceGroup values')
param privateDnsZone object

var customTags = {
  Location: location
  CreatedDate: createdDate
  Environment: environment
}

var defaultTags = union(json(loadTextContent('../../../common/default-tags.json')), customTags)

var documentIntelligenceTags = {
  Name: aiDocumentIntelligence.name
  Purpose: 'AI Document Intelligence'
  Tier: 'Shared'
}

resource private_dns_zone 'Microsoft.Network/privateDnsZones@2020-06-01' existing = {
  name: privateDnsZone.name
  scope: resourceGroup(privateDnsZone.resourceGroup)
}


module documentIntelligenceResource 'br/avm:cognitive-services/account:0.8.0' = {
  name: 'ai-document-intelligence-${deploymentDate}'
  params: {
    kind: 'FormRecognizer'
    name: aiDocumentIntelligence.name
    publicNetworkAccess: 'Disabled'
    location: location
    sku: aiDocumentIntelligence.sku
    customSubDomainName: aiDocumentIntelligence.customSubDomainName
    privateEndpoints: [
      {
         privateDnsZoneGroup: {
          privateDnsZoneGroupConfigs: [
            {
              privateDnsZoneResourceId: private_dns_zone.id
            }
          ]
        }
        subnetResourceId: resourceId(vnet.resourceGroup, 'Microsoft.Network/virtualNetworks/subnets', vnet.name, vnet.subnetPrivateEndpoints)
      }
    ]

    tags: union(defaultTags, documentIntelligenceTags)

  }
}

output objectOutput object = documentIntelligenceResource.outputs


module privateDnsZoneModule 'br/SharedDefraRegistry:network.private-dns-zone:0.5.2' = {
  name: 'aks-private-dns-zone-${deploymentDate}'
  scope: resourceGroup(privateDnsZone.resourceGroup)
  params: {
   name: privateDnsZone.name
   a: [
    {
      aRecords: [
        {
          ipv4Address: documentIntelligenceResource.outputs.privateEndpoints[0].customDnsConfig[0].ipAddresses[0]

        }
      ]
      name: '@'
     
      ttl: 3600
    }
  ]  

  }
}

