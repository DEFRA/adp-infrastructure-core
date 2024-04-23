using './container-apps-component.bicep'

param containerAppEnvironmentName = '#{{ containerAppEnv }}'

param containerAppId = '#{{ fluxNotificationContainerAppId}}'

param eventHubNamespaceName = '#{{ ssvInfraResourceNamePrefix }}#{{nc_resource_eventhub }}#{{nc_shared_instance_regionid }}01'

param storageAccountName = '#{{ fluxNotificationStorageAccountName }}'

param managedIdentityName = '#{{ fluxNotificationApiManagedIdentity }}'
