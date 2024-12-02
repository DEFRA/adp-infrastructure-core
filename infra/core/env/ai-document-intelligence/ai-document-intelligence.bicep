@description('Required. The parameter object for the virtual network. The object must contain the name, resourceGroup and subnetPrivateEndpoints values.')
param vnet object

@description('Required. The parameter object for AI Document Intelligence. The object must contain the name and sku values.')
param aiDocumentIntelligence object

@description('Optional. Location for all resources.')
param location string = resourceGroup().location

@description('Optional. Restrict outbound network access.')
param restrictOutboundNetworkAccess bool = false

@description('Required. Environment name.')
param environment string

@description('Optional. Date in the format yyyyMMdd-HHmmss.')
param deploymentDate string = utcNow('yyyyMMdd-HHmmss')

@description('Optional. Date in the format yyyy-MM-dd.')
param createdDate string = utcNow('yyyy-MM-dd')

@description('Required. The parameter object for the private Dns zone. The object must contain the name and resourceGroup values')
param privateDnsZone object

@description('Required. Boolean value to enable or disable resource lock.')
param resourceLockEnabled bool

var customTags = {
  Location: location
  CreatedDate: createdDate
  Environment: environment
}

var tagsMi = {
  Name: aiDocumentIntelligence.miName
  Purpose: 'Document Intelligence Control Plane Managed Identity'
  Tier: 'Security'
}

var defaultTags = union(json(loadTextContent('../../../common/default-tags.json')), customTags)

var documentIntelligenceTags = {
  Name: aiDocumentIntelligence.name
  Purpose: 'AI Document Intelligence'
  Tier: 'Shared'
}

var dnsTags = {
  Name: privateDnsZone.name
  Purpose: 'AKS Private DNS Zone'
}

resource private_dns_zone 'Microsoft.Network/privateDnsZones@2020-06-01' existing = {
  name: privateDnsZone.name
  scope: resourceGroup(privateDnsZone.resourceGroup)
}


module documentIntelligenceResource 'br/avm:cognitive-services/account:0.8.0' = {
  name: 'ai-document-intelligence-${deploymentDate}'
  dependsOn: [
    managedIdentity
  ]
  params: {
    kind: 'FormRecognizer'
    name: aiDocumentIntelligence.name
    publicNetworkAccess: 'Disabled'
    location: location
    sku: aiDocumentIntelligence.sku
    customSubDomainName: aiDocumentIntelligence.customSubDomainName
    restrictOutboundNetworkAccess: restrictOutboundNetworkAccess
    lock: {
      kind: resourceLockEnabled ? 'CanNotDelete' : null
      name: 'diLock'
    }
    managedIdentities: {
      userAssignedResourceIds: [
        managedIdentity.outputs.resourceId
      ]
    }
    
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

module managedIdentity 'br/SharedDefraRegistry:managed-identity.user-assigned-identity:0.4.3' = {
  name: 'aks-cluster-mi-${deploymentDate}'
  params: {
    name: aiDocumentIntelligence.miName
    location: location
    lock: resourceLockEnabled ? 'CanNotDelete' : null
    tags: union(defaultTags, tagsMi)
  }
}

module privateDnsZoneModule 'br/SharedDefraRegistry:network.private-dns-zone:0.5.2' = {
  name: 'aks-private-dns-zone-${deploymentDate}'
  scope: resourceGroup(privateDnsZone.resourceGroup)
  params: {
   name: privateDnsZone.name
   tags: union(defaultTags, dnsTags)
   a: [
    {
      aRecords: [
        {
          ipv4Address: documentIntelligenceResource.outputs.privateEndpoints[0].customDnsConfig[0].ipAddresses[0]

        }
      ]
      name: '@'  
      ttl: 300
    }
  ]  

  }
}

