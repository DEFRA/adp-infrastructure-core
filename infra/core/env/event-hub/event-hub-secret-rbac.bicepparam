using './event-hub-secret-rbac.bicep'

param eventHubNamespace = {
  name: '#{{ ssvInfraResourceNamePrefix }}#{{nc_resource_eventhub }}#{{nc_shared_instance_regionid }}01'
  resourceGroup: '#{{ ssvSharedResourceGroup}}'
  connectionSecretName: '#{{ environment }}#{{ nc_instance_regionid }}0#{{ environmentId }}-ADP-EVENTHUB-CONNECTION'
}

// param appConfigMiObjectId = '#{{ appConfigMiObjectId }}'
param appConfigMiObjectId = '2eb6fd3a-8dec-4634-8b48-512d268277ae'

param eventHub = {
  name: 'flux-events-#{{ eventHubEnvironment }}'
  keyVaultName: '#{{ ssvEventHubConnectionStringKeyVault }}'
}

param secondEventHub = {
  sendFluxNotificationsToSecondEventHub: #{{ sendFluxNotificationsToSecondEventHub }}
  name: 'flux-events-#{{ secondEventHubEnvironment }}'
  keyVaultName: '#{{ ssvSecondEventHubConnectionStringKeyVault }}'
  resourceGroup: '#{{ ssvSecondEventHubConnectionStringKeyVaultRg }}'
}

// param secondEventHub = {
//   sendFluxNotificationsToSecondEventHub: true
//   name: 'flux-events-TST'
//   keyVaultName: 'SSVADPTSTVT3401'
//   resourceGroup: 'SSVADPTSTRG3401'
// }
