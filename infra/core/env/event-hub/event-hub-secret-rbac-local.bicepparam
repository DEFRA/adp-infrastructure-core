using './event-hub-secret-rbac.bicep'

param eventHubNamespace = {
  name: 'SSVADPINFEN3401'
  resourceGroup: 'SSVADPINFRG3401'
  connectionSecretName: 'SND1401-ADP-EVENTHUB-CONNECTION'
}

param eventHub = {
  name: 'flux-events-DEV'
  keyVaultName: 'SSVADPDEVVT3401'
}

param appConfigMiObjectId = '2eb6fd3a-8dec-4634-8b48-512d268277ae'

param secondEventHub = {
  sendFluxNotificationsToSecondEventHub: true
  name: 'flux-events-TST'
  keyVaultName: 'SSVADPTSTVT3401'
  resourceGroup: 'SSVADPTSTRG3401'
}
