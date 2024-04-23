@description('Required. The parameter object for eventHub. The object must contain the namespaceName, consumerGroupName and name values.')
param eventHub object

var authorizationRules = [
  {
    name: 'FluxSendAccess'
    rights: [
      'Send'
    ]
  }
]

resource namespace 'Microsoft.EventHub/namespaces@2022-10-01-preview' existing = {
  name: eventHub.namespaceName
}

resource eventHubResource 'Microsoft.EventHub/namespaces/eventhubs@2022-10-01-preview' = {
  name: eventHub.name
  parent: namespace  
}

resource consumerGroup 'Microsoft.EventHub/namespaces/eventhubs/consumergroups@2023-01-01-preview' = {
  name: eventHub.consumerGroupName
  parent: eventHubResource
}

resource authorizationRuleResource 'Microsoft.EventHub/namespaces/eventhubs/authorizationRules@2022-10-01-preview' = [for (authorizationRule, index) in authorizationRules: {
  name: authorizationRule.name
  parent: eventHubResource
  properties: {
    rights: authorizationRule.rights
  }
}]
