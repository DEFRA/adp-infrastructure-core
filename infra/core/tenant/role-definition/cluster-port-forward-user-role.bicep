targetScope = 'subscription'

@description('Name of the Custom Role Definition in Azure.')
param roleName string

@description('Array of scopes to assign the role to.')
param roleScopes array

@description('Detailed description of the role definition')
param roleDescription string = 'Custom Role to enable port forwarding.'

param deployClusterPortForwardRole string = 'false'

resource clusterPortForwardRoleResource 'Microsoft.Authorization/roleDefinitions@2022-04-01' = if (deployClusterPortForwardRole == 'true') {
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
          'Microsoft.ContainerService/managedClusters/pods/write'          
        ]
      }
    ]
    roleName: roleName
    type: 'customRole'
  }
}
