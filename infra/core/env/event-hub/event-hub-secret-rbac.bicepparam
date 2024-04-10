using './event-hub-secret-rbac.bicep'

param eventHubNamespace = {
  name: '#{{ infraResourceNamePrefix }}#{{nc_resource_eventhub }}#{{nc_shared_instance_regionid }}01'
  eventHubName: 'flux-events-#{{ eventHubEnvironment }}'
  eventHubConnectionSecretName: '#{{ environment }}#{{ nc_instance_regionid }}0#{{ environmentId }}-ADP-EVENTHUB-CONNECTION'
  resourceGroup: '#{{ ssvSharedResourceGroup}}'
}

param keyVaultName = '#{{ ssvInfraKeyVault }}'

param appConfigMiObjectId = '#{{ appConfigMiObjectId }}'
