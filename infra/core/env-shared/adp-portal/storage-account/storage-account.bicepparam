using './storage-account.bicep'

// param storageAccount = {
//   name: '#{{ portalStorageAccountName }}'
//   privateEndpointName: '#{{ portalAppSAPvtEndpointName }}'
//   skuName: 'Standard_ZRS'
//   containerName: 'adp-wiki-techdocs'
// }

param storageAccount = {
  name: 'testtestopr654839630mdjde'
  privateEndpointName: '#{{ portalAppSAPvtEndpointName }}'
  skuName: 'Standard_ZRS'
  containerName: 'adp-wiki-techdocs'
}

param vnet = {
  name: '#{{ ssvVirtualNetworkName }}'
  resourceGroup: '#{{ ssvVirtualNetworkResourceGroup }}'
  subnetPrivateEndpoints: '#{{ ssvPrivateEndpointSubnet }}'
}

param keyvaultName = '#{{ ssvInfraKeyVault }}'

param environment = '#{{ environment }}'

param location = '#{{ location }}'
