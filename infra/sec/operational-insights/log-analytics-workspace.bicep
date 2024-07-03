@description('Required. The parameter object for servicebus. The object must contain the name and skuName values.')
param logAnalytics object

@description('Optional. The Azure region where the resources will be deployed.')
param location string = resourceGroup().location

@description('Required. Environment name.')
param environment string

@description('Required. Boolean value to enable resource lock.')
param resourceLockEnabled bool

@description('Optional. Date in the format yyyyMMdd-HHmmss.')
param deploymentDate string = utcNow('yyyyMMdd-HHmmss')

@description('Optional. Date in the format yyyy-MM-dd.')
param createdDate string = utcNow('yyyy-MM-dd')

var customTags = {
  Location: location
  CreatedDate: createdDate
  Environment: environment
  Name: logAnalytics.name
  Purpose: 'Log Analytics Workspace'
  Tier: 'Shared'
}

var tags = union(loadJsonContent('../../common/default-tags.json'), customTags)

module logAnalyticsWorkspaceResource 'br/SharedDefraRegistry:operational-insights.workspace:0.4.3' = {
  name: 'log-analytics-${deploymentDate}'
  params: {
    name: logAnalytics.name
    location: location
    skuName: logAnalytics.skuName
    lock: resourceLockEnabled ? 'CanNotDelete' : null
    tags: tags
  }
}
