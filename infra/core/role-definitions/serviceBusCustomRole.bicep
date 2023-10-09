targetScope = 'subscription'

@description('Array of actions for the Custom Role. Should be an array of roles following principal of least priviledge.')
param actions array = []

@description('Array of dataActions for the Custom Role. Should be an array of roles following principal of least priviledge.')
param dataActions array = []

@description('Array of notActions for the Custom Role. Should be an array of roles following principal of least priviledge.')
param notActions array = []

@description('Array of notDataActions for the Custom Role. Should be an array of roles following principal of least priviledge.')
param notDataActions array = []

@description('Name of the Custom Role Definition in Azure.')
param roleName string

@description('Detailed description of the role definition')
param roleDescription string = 'Custom Role to provide RBAC on Azure Service Bus Queues, Topics and Subscriptions. Also provides Authorization/write on ASB to allow for MIs to be given RBAC access for a service.'

resource asbCustomRoleResource 'Microsoft.Authorization/roleDefinitions@2022-04-01' = {
  name: guid(subscription().id, roleName)
  scope: subscription()
  properties: {
    assignableScopes: [
      subscription().id
    ]
    description: roleDescription
    permissions: [
      {
        actions: actions
        dataActions: dataActions
        notActions: notActions
        notDataActions: notDataActions
      }
    ]
    roleName: roleName
    type: 'customRole'
  }
}
