using './servicebus-customrole.bicep'

param roleName = ''

param actions = [
  'Microsoft.ServiceBus/namespaces/read'
  'Microsoft.ServiceBus/namespaces/queues/read'
  'Microsoft.ServiceBus/namespaces/queues/write'
  'Microsoft.ServiceBus/namespaces/queues/Delete'
  'Microsoft.ServiceBus/namespaces/queues/authorizationRules/write'
  'Microsoft.ServiceBus/namespaces/queues/authorizationRules/read'
  'Microsoft.ServiceBus/namespaces/queues/authorizationRules/delete'
  'Microsoft.ServiceBus/namespaces/topics/write'
  'Microsoft.ServiceBus/namespaces/topics/read'
  'Microsoft.ServiceBus/namespaces/topics/authorizationRules/write'
  'Microsoft.ServiceBus/namespaces/topics/authorizationRules/read'
  'Microsoft.ServiceBus/namespaces/topics/authorizationRules/delete'
  'Microsoft.ServiceBus/namespaces/topics/Delete'
  'Microsoft.ServiceBus/namespaces/topics/subscriptions/write'
  'Microsoft.ServiceBus/namespaces/topics/subscriptions/read'
  'Microsoft.ServiceBus/namespaces/topics/subscriptions/Delete'
  'Microsoft.ServiceBus/namespaces/topics/subscriptions/rules/write'
  'Microsoft.ServiceBus/namespaces/topics/subscriptions/rules/read'
  'Microsoft.ServiceBus/namespaces/topics/subscriptions/rules/Delete'
]

param notActions =[]
param dataActions = []
param notDataActions = []
