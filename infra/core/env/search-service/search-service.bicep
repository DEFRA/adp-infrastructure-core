@description('Required. The object of Open AI Resource. The object must contain name, SKU and customSubDomainName  properties.')
param searchService object

@description('Required. The parameter object for the virtual network. The object must contain the name,skuName,resourceGroup and subnetPrivateEndpoints values.')
param vnet object

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

var searchServiceName = toLower(searchService.name)
@description('Required. The name of the AAD admin managed identity.')
param managedIdentityName string

var managedIdentityTags = {
  Name: managedIdentityName
  Purpose: 'ADP OPEN AI Managed Identity'
  Tier: 'Shared'
}
var customTags = {
  Name: searchServiceName
  Location: location
  CreatedDate: createdDate
  Environment: environment
  Purpose: 'ADP Search Service'
}

var privateEndpointTags = {
  Name: searchServiceName
  Purpose: 'Search Service private endpoint'
  Tier: 'Shared'
}

var defaultTags = union(json(loadTextContent('../../../common/default-tags.json')), customTags)

@description('Required. Search Service UserGroup id.')
param searchServiceUserGroupId string


module openAiUserMi 'br/SharedDefraRegistry:managed-identity.user-assigned-identity:0.4.3' = {
  name: 'managed-identity-${deploymentDate}'
  params: {
    name: toLower(managedIdentityName)
    tags: union(defaultTags, managedIdentityTags)
    lock: 'CanNotDelete'
  }
}

module searchServiceDeployment './module/main.bicep' = {
  name: 'search-service-${deploymentDate}'
  params: {
    name: searchServiceName
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
        workspaceResourceId: resourceId(
          monitoringWorkspace.resourceGroup,
          'Microsoft.OperationalInsights/workspaces',
          monitoringWorkspace.name
        )
      }
    ]    
    managedIdentities: {
      userAssignedResourceIds: [
        openAiUserMi.outputs.resourceId
      ]
    }
    privateEndpoints: [
      {
        name: searchService.privateEndpointName
        subnetResourceId: resourceId(
          vnet.resourceGroup,
          'Microsoft.Network/virtualNetworks/subnets',
          vnet.name,
          vnet.subnetPrivateEndpoints
        )
        tags: union(defaultTags, privateEndpointTags)
      }
    ]
    tags: union(defaultTags, customTags)
  }
}

module sharedPrivateLink '.bicep/shared-private-link.bicep' = {
  name: 'shared-private-link-${deploymentDate}'
  params: {
    searchServiceName: searchServiceName
    openAiName: searchService.openAiName
  }
}

module openAiRbac '.bicep/open-ai-rbac.bicep' = {
  name: 'open-ai-rbac-${deploymentDate}'
  params: {
    principalId: openAiUserMi.outputs.principalId
    openAiName: searchService.openAiName
  }
}

