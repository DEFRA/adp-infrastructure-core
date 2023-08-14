@description('Required. The object of the PostgreSQL Flexible Server. The object must contain name,storageSizeGB and highAvailability properties.')
param server object

@description('Required. The diagnostic object. The object must contain diagnosticLogCategoriesToEnable and diagnosticMetricsToEnable properties.')
param diagnostics object

@description('Required. The array of administrators. The array must contain objectId,principalName,principalType, and tenantId properties.')
param administratorsJson string

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
  Location: location
  CreatedDate: createdDate
  Environment: environment
  Purpose: 'ADP POSTGRESQL FLEXIBLE SERVER'
}

var administrators = json(administratorsJson)

var defaultTags = union(json(loadTextContent('../default-tags.json')), customTags)

module flexibleServerDeployment 'br/SharedDefraRegistry:db-for-postgre-sql.flexible-servers:0.4.2-prerelease' = {
  name: 'postgre-sql-flexible-server-${deploymentDate}'
  params: {
    name: server.name
    storageSizeGB: server.storageSizeGB
    highAvailability: server.highAvailability
    availabilityZone: server.availabilityZone
    version:'14'
    location: location
    tags: union(defaultTags, customTags)
    tier: 'GeneralPurpose'
    skuName: 'Standard_D4s_v5'
    activeDirectoryAuth:'Enabled'
    passwordAuth: 'Disabled'
    enableDefaultTelemetry:false
    lock: 'CanNotDelete'
    backupRetentionDays:14
    createMode: 'Default' 
    diagnosticLogCategoriesToEnable: diagnostics.diagnosticLogCategoriesToEnable
    diagnosticMetricsToEnable: diagnostics.diagnosticMetricsToEnable
    diagnosticSettingsName:''
    diagnosticLogsRetentionInDays: 90
    administrators: administrators
    //configurations:[]
    //delegatedSubnetResourceId : delegatedSubnetResourceId
    //privateDnsZoneArmResourceId: privateDnsZoneArmResourceId
    //diagnosticWorkspaceId: diagnosticWorkspaceId
  }
}
