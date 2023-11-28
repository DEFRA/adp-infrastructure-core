targetScope = 'subscription'

@description('Name of the Custom Role Definition in Azure.')
param roleName string

@description('Array of scopes to assign the role to.')
param roleScopes array

@description('Detailed description of the role definition')
param roleDescription string = 'Custom Role to provide RBAC on Azure Service Bus Queues and Topics. Also provides Authorization/write on ASB to allow for MIs to be given RBAC access for a service.'

resource asbCustomRoleResource 'Microsoft.Authorization/roleDefinitions@2022-04-01' = {
  name: guid(subscription().id, roleName)
  scope: subscription()
  properties: {
    assignableScopes: roleScopes
    description: roleDescription
    permissions: [
      {
        actions: [
          'Microsoft.ServiceBus/namespaces/queues/write'
          'Microsoft.ServiceBus/namespaces/queues/read'
          'Microsoft.ServiceBus/namespaces/queues/Delete'
          'Microsoft.ServiceBus/namespaces/topics/Delete'
          'Microsoft.ServiceBus/namespaces/topics/read'
          'Microsoft.ServiceBus/namespaces/topics/write'
          'Microsoft.Authorization/roleAssignments/read'
          'Microsoft.Authorization/roleAssignments/write'
          'Microsoft.Authorization/roleAssignments/delete'
        ]
        dataActions: []
        notActions: []
        notDataActions: []
      }
    ]
    roleName: roleName
    type: 'customRole'
  }
}
