using './../event-hub.bicep'

param eventHub = {
  namespaceName: '#{{ ssvInfraResourceNamePrefix }}#{{nc_resource_eventhub }}#{{nc_shared_instance_regionid }}01'
  eventHubName: 'flux-events-#{{ subEnvironment1 }}'
  eventHubConsumerGroup: '#{{ fluxNotificationContainerAppId }}'
}
