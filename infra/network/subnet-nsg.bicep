@description('Required. Object of the format The Network Security Group Name, Rules[Name,securityrules obj].')
param nsgList array = []

@description('Required. The Azure region where the resources will be deployed.')
param location string
@description('Required. Environment name.')
param environment string
@description('Optional. Date in the format yyyy-MM-dd.')
param createdDate string = utcNow('yyyy-MM-dd')
@description('Optional. Date in the format yyyyMMdd-HHmmss.')
param deploymentDate string = utcNow('yyyyMMdd-HHmmss')

var commonTags = {
  Location: location
  CreatedDate: createdDate
  Environment: environment
  Purpose: 'ADP-NSG'
  Tier: 'Shared'
}
var tags = union(loadJsonContent('../default-tags.json'), commonTags)

module networksecuritygroup 'br/SharedDefraRegistry:network.network-security-groups:0.4.7' = [for nsg in nsgList:  {
  name: '${nsg.name}-${deploymentDate}'
  params: {
    name: nsg.name
    lock: 'CanNotDelete'
    location: location
    tags: tags
    securityRules: nsg.securityRules 
  }
}]
