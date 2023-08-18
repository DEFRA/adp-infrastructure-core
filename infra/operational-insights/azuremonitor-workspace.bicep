@description('Required. The Name of the Azure Monitor Workspace.')
param azureMonitorWorkspaceName string

@allowed([
  'UKSouth'
])
@description('Required. The Azure region where the resources will be deployed.')
param location string

@description('Required. Environment name.')
param environment string

@description('Optional. Date in the format yyyy-MM-dd.')
param createdDate string = utcNow('yyyy-MM-dd')

var customTags = {
  Location: location
  CreatedDate: createdDate
  Environment: environment
  Name: azureMonitorWorkspaceName
  Purpose: 'Azure Monitor Workspace'
  Tier: 'Shared'
}
var tags = union(loadJsonContent('../default-tags.json'), customTags)

resource monitor 'Microsoft.Monitor/accounts@2023-04-03' = {
  location: location
  name: azureMonitorWorkspaceName
  tags: tags
}
