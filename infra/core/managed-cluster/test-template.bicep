param miName string
param location string
param deploymentDate string = utcNow('yyyyMMdd-HHmmss')
param createdDate string = utcNow('yyyy-MM-dd')
param environment string

var commonTags = {
  Location: location
  CreatedDate: createdDate
  Environment: environment
}
var tags = union(loadJsonContent('../../common/default-tags.json'), commonTags)
var tagsMi = {
  Name: miName
  Purpose: 'AKS Control Plane Managed Identity'
  Tier: 'Security'
}

module managedIdentity 'br/SharedDefraRegistry:managed-identity.user-assigned-identity:0.4.3' = {
  name: 'aks-cluster-mi-${deploymentDate}'
  params: {
    name: miName
    location: location
    lock: 'CanNotDelete'
    tags: union(tags, tagsMi)
  }
}

output configuration array = [
  {
    name: 'CLUSTER_OIDC'
    value: 'https://uksouth.oic.prod-aks.azure.com/6f504113-6b64-43f2-ade9-242e05780007/e2c9927a-ec91-484c-b387-09f9fbbf956d/' //deployAKS.outputs.oidcIssuerUrl
    label: 'Platform'
  }
]
