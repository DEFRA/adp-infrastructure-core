using './managed-identity.bicep'

param managedIdentity = {
  name: '#{{ infraResourceNamePrefix }}#{{ nc_resource_managedidentity }}#{{ nc_instance_regionid }}03-adp-portal'
}

param environment = '#{{ environment }}'

param location = '#{{ location }}'

param containerRegistry = {
  name: '#{{ infraResourceNamePrefix }}#{{ nc_resource_containerregistry }}#{{ nc_instance_regionid }}01'
  subscriptionId: '#{{ subscriptionId }}'
  resourceGroup: '#{{ ssvSharedResourceGroup }}'
}

param keyVault = {
  name: '#{{ ssvResourceNamePrefix }}#{{ nc_resource_keyvault }}#{{ nc_shared_instance_regionid }}03'
  subscriptionId: '#{{ subscriptionId }}'
  resourceGroup: '#{{ portalResourceGroup }}'
}
