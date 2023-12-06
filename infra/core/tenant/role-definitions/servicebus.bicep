targetScope = 'subscription'

@description('Name of the Custom Role Definition in Azure.')
param roleName string

@description('Array of scopes to assign the role to.')
param roleScopes array

@description('Detailed description of the role definition')
param roleDescription string = 'Custom Role to create/update Azure Service Bus Queues and Topics. Also assign RBAC permissions to manage role assignments.'

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
          'Microsoft.ServiceBus/namespaces/topics/read'
          'Microsoft.ServiceBus/namespaces/topics/write'
          'Microsoft.ServiceBus/namespaces/topics/subscriptions/Delete'
          'Microsoft.ServiceBus/namespaces/topics/subscriptions/read'
          'Microsoft.ServiceBus/namespaces/topics/subscriptions/write'
          'Microsoft.ServiceBus/namespaces/topics/subscriptions/rules/write'
          'Microsoft.ServiceBus/namespaces/topics/subscriptions/rules/read'
          'Microsoft.ServiceBus/namespaces/topics/subscriptions/rules/Delete'
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
