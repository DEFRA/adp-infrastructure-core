using './event-hub.bicep'

param eventHub = {
  namespaceName: '#{{ infraResourceNamePrefix }}#{{nc_resource_eventhub }}#{{nc_shared_instance_regionid }}01'
  eventHubName: 'flux-events-#{{ eventHubNameSuffix }}'
}
