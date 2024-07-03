using './storage-account.bicep'

param storageAccount = {
  name: '#{{ fluxNotificationStorageAccountName }}'
  privateEndpointName: '#{{ fluxNotificationSAPvtEndpointName }}'
  containerName: '#{{ fluxNotificationContainerAppId }}'
  skuName: 'Standard_ZRS'
}

param vnet = {
  name: '#{{ ssvVirtualNetworkName }}'
  resourceGroup: '#{{ ssvVirtualNetworkResourceGroup }}'
  subnetPrivateEndpoints: '#{{ ssvPrivateEndpointSubnet }}'
}

param environment = '#{{ environment }}'

param subEnvironment = '#{{ subEnvironment }}'

param location = '#{{ location }}'

param resourceLockEnabled = #{{ resourceLockEnabled }}
