@description('Required. The Name of the Azure Monitor Workspace.')
param azureMonitorWorkspaceName string

@description('Required. The Azure region where the resources will be deployed.')
param location string

@description('Required. Environment name.')
param environment string

@description('Optional. Date in the format yyyy-MM-dd.')
param createdDate string = utcNow('yyyy-MM-dd')

var commonTags = {
  Name: azureMonitorWorkspaceName
  Location: location
  CreatedDate: createdDate
  Environment: environment
  Purpose: 'Shared Azure Monitor Workspace for Platform'
}
var tags = union(loadJsonContent('../../common/default-tags.json'), commonTags)

resource azureMonitorWorkSpaceResource 'Microsoft.Monitor/accounts@2023-04-03' = {
  location: location
  name: azureMonitorWorkspaceName
  tags: tags
}
