@description('Required. The Network Security Group Name.')
param name string

@description('Required. The Azure region where the resources will be deployed.')
param location string
@description('Required. Environment name.')
param environment string
@description('Optional. Date in the format yyyy-MM-dd.')
param createdDate string = utcNow('yyyy-MM-dd')
@description('Optional. Date in the format yyyyMMdd-HHmmss.')
param deploymentDate string = utcNow('yyyyMMdd-HHmmss')

@description('Required. Array of Security Rules to deploy to the Network Security Group. When not provided, an NSG including only the built-in roles will be deployed.')
param securityRules array = []

var commonTags = {
  Location: location
  CreatedDate: createdDate
  Environment: environment
  Purpose: 'ADP-NSG'
  Tier: 'Shared'
}
var tags = union(loadJsonContent('../default-tags.json'), commonTags)

module networksecuritygroup 'br/SharedDefraRegistry:network.network-security-groups:0.4.7' = {
  name: 'nsg-${deploymentDate}'
  params: {
    name: name
    lock: 'CanNotDelete'
    location: location
    tags: tags
    securityRules: securityRules 
  }
}
