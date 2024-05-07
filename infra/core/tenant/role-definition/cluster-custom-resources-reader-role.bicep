targetScope = 'subscription'

@description('Name of the Custom Role Definition in Azure.')
param roleName string

@description('Array of scopes to assign the role to.')
param roleScopes array

@description('Detailed description of the role definition')
param roleDescription string = 'Custom Role to read cluster data.'

resource clusterCustomRoleResource 'Microsoft.Authorization/roleDefinitions@2022-04-01' = {
  name: guid(subscription().id, roleName)
  scope: subscription()
  properties: {
    assignableScopes: roleScopes
    description: roleDescription
    permissions: [
      {
        actions: [
          'Microsoft.ContainerService/managedClusters/listClusterUserCredential/action'
          'Microsoft.ContainerService/managedClusters/read'
        ]
        dataActions: [
          'Microsoft.ContainerService/managedClusters/*/read'          
        ]
        notActions: []
        notDataActions: [
          'Microsoft.ContainerService/managedClusters/secrets/read'
        ]
      }
    ]
    roleName: roleName
    type: 'customRole'
  }
}
