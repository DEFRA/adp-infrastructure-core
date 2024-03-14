using './event-hub-secret-rbac.bicep'

param eventHubNamespace = {
  name: '#{{ ssvResourceNamePrefix }}#{{nc_resource_eventhub }}#{{nc_shared_instance_regionid }}01'
  eventHubNameEnvironment: 'flux-events-#{{ eventHubNameEnvironment }}'
  resourceGroup: '#{{ ssvSharedResourceGroup}}'
}

param keyVaultName = '#{{ ssvInfraKeyVault }}'

param appConfigMiObjectId = '#{{ appConfigMiObjectId }}'
