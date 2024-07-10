targetScope = 'subscription'

@description('Name of the Custom Role Definition in Azure.')
param roleName string

@description('Array of scopes to assign the role to.')
param roleScopes array

@description('Detailed description of the role definition')
param roleDescription string = 'Custom Role to Send/Receive access to Azure Service Bus Queues and Topics.'

resource asbCustomRoleResource 'Microsoft.Authorization/roleDefinitions@2022-04-01' = {
  name: guid(subscription().id, roleName)
  scope: subscription()
  properties: {
    assignableScopes: roleScopes
    description: roleDescription
    permissions: [
      {
        actions: [
          'Microsoft.ServiceBus/*/queues/read'
          'Microsoft.ServiceBus/*/topics/read'
          'Microsoft.ServiceBus/*/topics/subscriptions/read'
        ]
        dataActions: [
          'Microsoft.ServiceBus/*/receive/action'
          'Microsoft.ServiceBus/*/send/action'
        ]
        notActions: []
        notDataActions: []
      }
    ]
    roleName: roleName
    type: 'customRole'
  }
}
