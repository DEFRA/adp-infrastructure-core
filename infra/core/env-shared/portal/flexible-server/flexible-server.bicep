@description('Required. The object of the PostgreSQL Flexible Server. The object must contain name,storageSizeGB and highAvailability properties.')
param server object

@description('Required. The parameter object for the virtual network. The object must contain the name,skuName,resourceGroup and subnetPostgreSql values.')
param vnet object

@description('Required. The parameter object for the private Dns zone. The object must contain the name and resourceGroup values')
param privateDnsZone object

@description('Required. The diagnostic object. The object must contain diagnosticLogCategoriesToEnable and diagnosticMetricsToEnable properties.')
param diagnostics object

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

@description('Required. The name of the key vault where the secrets will be stored.')
param keyvaultName string 

var customTags = {
  Name: server.name
  Location: location
  CreatedDate: createdDate
  Environment: environment
  Purpose: 'ADP POSTGRESQL FLEXIBLE SERVER'
}

var defaultTags = union(json(loadTextContent('../../../../common/default-tags.json')), customTags)

@description('Optional. The administrator login name of a server. Can only be specified when the PostgreSQL server is being created.')
param administratorLogin string = 'solemnapple5'

param guidValue string = guid(deploymentDate)
var administratorLoginPassword  = substring(replace(replace(guidValue, '.', '-'), '-', ''), 0, 20)

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

module flexibleServerDeployment 'br/SharedDefraRegistry:db-for-postgre-sql.flexible-server:0.4.4' = {
  name: 'postgre-sql-flexible-server-${deploymentDate}'
  params: {
    name: toLower(server.name)
    administratorLogin: administratorLogin
    administratorLoginPassword : administratorLoginPassword
    storageSizeGB: server.storageSizeGB
    highAvailability: server.highAvailability
    availabilityZone: server.availabilityZone
    version:'15'
    location: location
    tags: union(defaultTags, customTags)
    tier: server.tier
    skuName: server.skuName
    activeDirectoryAuth:'Enabled'
    passwordAuth: 'Enabled'
    enableDefaultTelemetry:false
    lock: 'CanNotDelete'
    backupRetentionDays:14
    createMode: 'Default' 
    diagnosticLogCategoriesToEnable: diagnostics.diagnosticLogCategoriesToEnable
    diagnosticMetricsToEnable: diagnostics.diagnosticMetricsToEnable
    diagnosticSettingsName:''
    administrators: []
    configurations:[]
    delegatedSubnetResourceId : virtual_network::subnet.id
    privateDnsZoneArmResourceId: private_dns_zone.id
    diagnosticWorkspaceId: ''
  }
}

resource keyVault 'Microsoft.KeyVault/vaults@2023-02-01' existing = {
  name: keyvaultName
}

resource secretdbhost 'Microsoft.KeyVault/vaults/secrets@2019-09-01' = {
  name: 'POSTGRES-HOST'
  parent: keyVault 
  properties: {
    value: '${flexibleServerDeployment.outputs.name}.postgres.database.azure.com'
  }
}

resource secretdbuser 'Microsoft.KeyVault/vaults/secrets@2019-09-01' = {
  name: 'POSTGRES-USER'
  parent: keyVault 
  properties: {
    value: administratorLogin
  }
}

resource secretdbpassword 'Microsoft.KeyVault/vaults/secrets@2019-09-01' = {
  name: 'POSTGRES-PASSWORD'
  parent: keyVault 
  properties: {
    value: administratorLoginPassword
  }
}
