using './configuration-store.bicep'

param appConfig = {
  name: '#{{ infraResourceNamePrefix }}#{{ nc_resource_appconfiguration }}#{{ nc_instance_regionid }}01'
  privateEndpointName: '#{{ infraResourceNamePrefix }}#{{ nc_resource_privateendpoint }}#{{ nc_instance_regionid }}02'
  softDeleteRetentionInDays: '#{{ appConfigurationSoftDeleteRetentionInDays }}'
  enablePurgeProtection: '#{{ appConfigurationEnablePurgeProtection }}'
}

param sku = '#{{ appConfigurationSku }}'

param vnet = {
  name: '#{{ virtualNetworkName }}'
  resourceGroup: '#{{ virtualNetworkResourceGroup }}'
  subnetPrivateEndpoints: '#{{ networkResourceNamePrefix }}#{{ nc_resource_subnet }}#{{ nc_instance_regionid }}02'
}

param location = '#{{ location }}'

param environment = '#{{ environment }}'

param principalId = az.getSecret('#{{ ssv3subscriptionId }}', '#{{ ssvSharedResourceGroup }}', '#{{ ssvPlatformKeyVaultName }}', '#{{ tier2ApplicationSPObjectIdSecretName }}')

param keyValues = [
  {
    name: 'ENVIRONMENT$Platform'
    value: '#{{ lower(environment) }}'
  }
  {
    name: 'ACR_NAME$Platform'
    value: '#{{ infraResourceNamePrefix }}#{{ nc_resource_containerregistry }}#{{ nc_instance_regionid }}01'
  }
  {
    name: 'NAMESPACE$Platform'
    value: 'flux-config'
  }
  {
    name: 'SERVICEBUS_RG$Platform'
    value: 'flux-config'
  }
  {
    name: 'SERVICEBUS_RG'
    value: '#{{ servicesResourceGroup }}'
  }
  {
    name: 'SERVICEBUS_NS'
    value: '#{{ infraResourceNamePrefix }}#{{ nc_resource_servicebus }}#{{ nc_instance_regionid }}01'
  }
  {
    name: 'POSTGRES_SERVER_RG'
    value: '#{{ dbsResourceGroup }}'
  }
  {
    name: 'POSTGRES_SERVER'
    value: '#{{ dbsResourceNamePrefix }}#{{ nc_resource_postgresql }}#{{ nc_instance_regionid }}01'
  }
  {
    name: 'INFRA_RG'
    value: '#{{ servicesResourceGroup }}'
  }
  {
    name: 'TEAM_MI_PREFIX'
    value: '#{{ infraResourceNamePrefix }}#{{ nc_resource_managedidentity }}#{{ nc_instance_regionid }}01'
  }
  {
    name: 'TENANT_ID'
    value: '#{{ tenantId }}'
  }
  {
    name: 'SUBSCRIPTION_ID'
    value: '#{{ subscriptionId }}'
  }
  {
    name: 'SUBSCRIPTION_NAME'
    value: '#{{ subscriptionName }}'
  }
  {
    name: 'CLUSTER'
    value: '0#{{ environmentId }}'
  }
]
