@description('Required. The object of the PostgreSQL Flexible Server. The object must contain name,storageSizeGB and highAvailability properties.')
param server object

@description('Required. The parameter object for the virtual network. The object must contain the name,skuName,resourceGroup and subnetPostgreSql values.')
param vnet object

@description('Required. The parameter object for the private Dns zone. The object must contain the name and resourceGroup values')
param privateDnsZone object

@description('Required. The name of the AAD admin managed identity.')
param managedIdentityName string

@description('Required. The name of the Key vault.')
param platformKeyVault object

@description('Required. List of secrects to be Rbac to the managed identity.')
param secrets array = []

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
  Name: server.name
  Location: location
  CreatedDate: createdDate
  Environment: environment
  Purpose: 'ADP POSTGRESQL FLEXIBLE SERVER'
}

var defaultTags = union(json(loadTextContent('../../../common/default-tags.json')), customTags)

resource virtual_network 'Microsoft.Network/virtualNetworks@2023-05-01' existing = {
  name: vnet.name
  scope: resourceGroup(vnet.resourceGroup)
  resource subnet 'subnets@2023-05-01' existing = {
    name: vnet.subnetPostgreSql
  }
}

resource private_dns_zone 'Microsoft.Network/privateDnsZones@2020-06-01' existing = {
  name: privateDnsZone.name
  scope: resourceGroup(privateDnsZone.resourceGroup)
}

var managedIdentityTags = {
  Name: managedIdentityName
  Purpose: 'ADP Platform Database AAD Admin Managed Identity'
  Tier: 'Shared'
}

module aadAdminUserMi 'br/SharedDefraRegistry:managed-identity.user-assigned-identity:0.4.3' = {
  name: 'managed-identity-${deploymentDate}'
  params: {
    name: toLower(managedIdentityName)
    tags: union(defaultTags, managedIdentityTags)
    lock: 'CanNotDelete'
  }
}

module keyvaultSecretsUserRoleAssignment '.bicep/kv-secret-role-secrets-user.bicep' = [for (secret, index) in secrets: {
  name: '${platformKeyVault.Name}-secrect-user-role-${deploymentDate}-${index}'
  scope: resourceGroup(platformKeyVault.subscriptionId, platformKeyVault.resourceGroup)
  dependsOn: [
    aadAdminUserMi
  ]
  params: {
    principalId: aadAdminUserMi.outputs.principalId 
    keyVaultName: '${platformKeyVault.Name}'
    secretName: secret
  }
}]

module flexibleServerDeployment 'br/avm:db-for-postgre-sql/flexible-server:0.1.1' = {
  name: 'postgre-sql-flexible-server-${deploymentDate}'
  params: {
    name: toLower(server.name)
    storageSizeGB: server.storageSizeGB
    highAvailability: server.highAvailability
    availabilityZone: server.availabilityZone
    version:'15'
    location: location
    tags: union(defaultTags, customTags)
    tier: server.tier
    skuName: server.skuName
    activeDirectoryAuth:'Enabled'
    passwordAuth: 'Disabled'
    lock: {
      kind: 'CanNotDelete'
    }
    backupRetentionDays:14
    createMode: 'Default' 
    administrators: [
      {
        objectId: aadAdminUserMi.outputs.clientId
        principalName: aadAdminUserMi.outputs.name
        principalType: 'ServicePrincipal'
      }
    ]
    configurations:[]
    delegatedSubnetResourceId : virtual_network::subnet.id
    privateDnsZoneArmResourceId: private_dns_zone.id
  }
}

var roleDefinitionId = 'acdd72a7-3385-48ef-bd42-f606fba81ae7' // Reader role

resource dbRsgGrpRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, 'Reader', resourceGroup().name)
  scope: resourceGroup()
  dependsOn:[
    aadAdminUserMi
  ]
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', roleDefinitionId) 
    principalId: aadAdminUserMi.outputs.principalId
    principalType: 'ServicePrincipal'
  }
}

module ssvSharedRsgRoleAssignment '.bicep/resource-group-rbac.bicep' = {
  name: '${platformKeyVault.resourceGroup}-reader-role-${deploymentDate}'
  scope: resourceGroup(platformKeyVault.subscriptionId, platformKeyVault.resourceGroup)
  params: {
    principalId: aadAdminUserMi.outputs.principalId 
    roleDefinitionId:roleDefinitionId
  }
}

@description('The Client Id of the AAD admin user managed identity.')
output aadAdminUserMiClientId string = aadAdminUserMi.outputs.clientId

@description('The Principal Id of the AAD admin user managed identity.')
output aadAdminUserMiPrincipalId string = aadAdminUserMi.outputs.principalId
