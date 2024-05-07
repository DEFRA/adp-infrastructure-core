using './../event-hub.bicep'

param eventHub = {
  namespaceName: '#{{ ssvInfraResourceNamePrefix }}#{{nc_resource_eventhub }}#{{nc_shared_instance_regionid }}01'
  name: 'flux-events-#{{ subEnvironment1 }}'
  consumerGroupName: '#{{ fluxNotificationContainerAppId }}'
}
