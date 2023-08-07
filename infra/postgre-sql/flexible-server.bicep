param serverName string
@allowed([
  'UKSouth'
])
@description('Required. The Azure region where the resources will be deployed.')
param location string
@description('Required. Environment name.')
param environment string
@description('Required. Date in the format yyyy-MM-dd.')
param createdDate string = utcNow('yyyy-MM-dd')
@description('Required. Date in the format yyyyMMdd-HHmmss.')
param deploymentDate string = utcNow('yyyyMMdd-HHmmss')

var customTags = {
  Location: location
  CreatedDate: createdDate
  Environment: environment
}
var defaultTags = union(json(loadTextContent('../default-tags.json')), customTags)

module flexibleServerDeployment 'br/SharedDefraRegistry:db-for-postgre-sql.flexible-servers:0.1.6' = {
  name: 'postgre-sql-flexible-server-${deploymentDate}'
  params: {
    name: serverName
    location: location
    administratorLogin : ''
    administratorLoginPassword : ''
    diagnosticLogsRetentionInDays: 14
  }
}
