@description('Required. The object of Open AI Resource. The object must contain name, SKU and customSubDomainName  properties.')
param searchService object

@description('Required. The parameter object for the virtual network. The object must contain the name,skuName,resourceGroup and subnetPrivateEndpoints values.')
param vnet object

@description('Required. The parameter object for private dns zone. The object must contain the prefix and resourceGroup values')
param privateDnsZone object

@description('Required. The parameter object for the monitoringWorkspace. The object must contain name of the name and resourceGroup.')
param monitoringWorkspace object

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
  Name: toLower(searchService.name)
  Location: location
  CreatedDate: createdDate
  Environment: environment
  Purpose: 'ADP Search Service'
}

var privateEndpointTags = {
  Name: toLower(searchService.name)
  Purpose: 'Search Service private endpoint'
  Tier: 'Shared'
}

var defaultTags = union(json(loadTextContent('../../../common/default-tags.json')), customTags)

var privateDnsZoneName = toLower('${privateDnsZone.prefix}.privatelink.search.windows.net')

@description('Required. Search Service UserGroup id.')
param searchServiceUserGroupId string

resource privateDnsZoneResource 'Microsoft.Network/privateDnsZones@2020-06-01' existing = {
  name: privateDnsZoneName
  scope: resourceGroup(privateDnsZone.resourceGroup)
}

module searchServiceDeployment 'br/avm:search/search-service:0.4.2' = {
  name: 'search-service-${deploymentDate}'
  params: {
    name: toLower(searchService.name)
    location: location
    lock: {
      kind: 'CanNotDelete'
      name: 'CanNotDelete'
    }
    publicNetworkAccess: 'disabled'
    roleAssignments: [
      {
        roleDefinitionIdOrName: '8ebe5a00-799e-43f5-93ac-243d3dce84a7'
        principalId: searchServiceUserGroupId
        principalType: 'Group'
      }
    ]
    sku: searchService.skuName
    replicaCount: searchService.replicaCount
    diagnosticSettings: [
      {
        name: 'OMS'
        logCategoriesAndGroups: [
          {
            category: 'Audit'
          }
        ]
        workspaceResourceId: resourceId(
          monitoringWorkspace.resourceGroup,
          'Microsoft.OperationalInsights/workspaces',
          monitoringWorkspace.name
        )
      }
    ]    
    managedIdentities: {
      systemAssigned: true
    }
    privateEndpoints: [
      {
        name: searchService.privateEndpointName
        privateDnsZoneResourceIds: [privateDnsZoneResource.id]
        subnetResourceId: resourceId(
          vnet.resourceGroup,
          'Microsoft.Network/virtualNetworks/subnets',
          vnet.name,
          vnet.subnetPrivateEndpoints
        )
        tags: union(defaultTags, privateEndpointTags)
      }
    ]
    sharedPrivateLinkResources: [
      {
        privateLinkResourceId: resourceId('Microsoft.CognitiveServices/accounts', searchService.openAiName)
        groupId: 'account'
        requestMessage: 'Please approve this request'
      }
    ]
    tags: union(defaultTags, customTags)
  }
}


module openAiRbac '.bicep/open-ai-rbac.bicep' = {
  name: 'open-ai-rbac-${deploymentDate}'
  params: {
    principalId: searchServiceDeployment.outputs.systemAssignedMIPrincipalId
    openAiName: searchService.openAiName
  }
}

