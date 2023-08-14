@description('Required. The object of the PostgreSQL Flexible Server. The object must contain name,storageSizeGB and highAvailability properties.')
param server object

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

var customTags = {
  Name: server.name
  Location: location
  CreatedDate: createdDate
  Environment: environment
  Purpose: 'ADP POSTGRESQL FLEXIBLE SERVER'
}

var defaultTags = union(json(loadTextContent('../default-tags.json')), customTags)

module flexibleServerDeployment 'br/SharedDefraRegistry:db-for-postgre-sql.flexible-servers:0.4.3-prerelease' = {
  name: 'postgre-sql-flexible-server-${deploymentDate}'
  params: {
    name: toLower(server.name)
    storageSizeGB: int(server.storageSizeGB)
    highAvailability: server.highAvailability
    availabilityZone: server.availabilityZone
    version:'15'
    location: location
    tags: union(defaultTags, customTags)
    tier: server.tier
    skuName: server.skuName
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
    administrators: []
    configurations:[]
    delegatedSubnetResourceId : ''
    privateDnsZoneArmResourceId: ''
    diagnosticWorkspaceId: ''
  }
}
