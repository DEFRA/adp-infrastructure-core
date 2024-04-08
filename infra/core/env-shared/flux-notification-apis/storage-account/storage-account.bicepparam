using './storage-account.bicep'

param storageAccount = {
  name: '#{{ fluxNotificationStorageAccountName }}'
  privateEndpointName: '#{{ fluxNotificationSAPvtEndpointName }}'
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
