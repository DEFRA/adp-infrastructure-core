@description('Required. The object of Open AI Resource. The object must contain name, SKU and customSubDomainName  properties.')
param openAi object

@description('Required. Deployment models of the Open AI resource.')
param deployments array

@description('Required. The parameter object for the virtual network. The object must contain the name,skuName,resourceGroup and subnetPrivateEndpoints values.')
param vnet object

@description('Required. The parameter object for private dns zone. The object must contain the prefix and resourceGroup values')
param privateDnsZone object

@allowed([
  'UKSouth'
])
@description('Required. The Azure region where the resources will be deployed.')
param location string
@description('Required. Environment name.')
param environment string
@description('Optional. Date in the format yyyy-MM-dd.')
param createdDate string = utcNow('yyyy-MM-dd')
@description('Optional. Date in the format yyyyMMdd-HHmmss.')
param deploymentDate string = utcNow('yyyyMMdd-HHmmss')

var customTags = {
  Name: openAi.name
  Location: location
  CreatedDate: createdDate
  Environment: environment
  Purpose: 'ADP OPEN AI'
}

var privateEndpointTags = {
  Name: openAi.name
  Purpose: 'Open AI private endpoint'
  Tier: 'Shared'
}

var defaultTags = union(json(loadTextContent('../../../common/default-tags.json')), customTags)

@description('Required. The name of the AAD admin managed identity.')
param managedIdentityName string

var managedIdentityTags = {
  Name: managedIdentityName
  Purpose: 'ADP OPEN AI Managed Identity'
  Tier: 'Shared'
}

var privateDnsZoneName = toLower('${privateDnsZone.prefix}.privatelink.openai.azure.com')

module openAiUserMi 'br/SharedDefraRegistry:managed-identity.user-assigned-identity:0.4.3' = {
  name: 'managed-identity-${deploymentDate}'
  params: {
    name: toLower(managedIdentityName)
    tags: union(defaultTags, managedIdentityTags)
    lock: 'CanNotDelete'
  }
}

resource privateDnsZoneResource 'Microsoft.Network/privateDnsZones@2020-06-01' existing = {
  name: privateDnsZoneName
  scope: resourceGroup(privateDnsZone.resourceGroup)
}

module openAIDeployment 'br/avm:cognitive-services/account:0.5.3' = {
  name: 'opan-ai-${deploymentDate}'
  params: {
    kind: 'OpenAI'
    name: openAi.name
    location: location
    lock: {
      kind: 'CanNotDelete'
      name: 'CanNotDelete'
    }
    sku: openAi.skuName
    customSubDomainName: openAi.customSubDomainName
    deployments: deployments
    managedIdentities: {      
      userAssignedResourceIds: [
        openAiUserMi.outputs.resourceId
      ]
    }
    privateEndpoints: [
      {
        name: openAi.privateEndpointName
        privateDnsZoneResourceIds: [privateDnsZoneResource.id]
        service: 'account'
        subnetResourceId: resourceId(vnet.resourceGroup, 'Microsoft.Network/virtualNetworks/subnets', vnet.name, vnet.subnetPrivateEndpoints)
        tags: union(defaultTags, privateEndpointTags)
      }
    ]
    tags: union(defaultTags, customTags)
  }  
}
