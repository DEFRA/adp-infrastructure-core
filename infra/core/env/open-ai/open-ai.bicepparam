using './open-ai.bicep'

param openAi = {
  name: '#{{ infraResourceNamePrefix }}#{{ nc_resource_openai }}#{{ nc_instance_regionid }}01'
  skuName: '#{{ openAiSkuName }}'
  customSubDomainName: '#{{ infraResourceNamePrefix }}#{{ nc_resource_openai }}#{{ nc_instance_regionid }}01'
  privateEndpointName: '#{{ infraResourceNamePrefix }}#{{ nc_resource_privateendpoint }}#{{ nc_instance_regionid }}10'  
}

param location = '#{{ location }}'
param environment = '#{{ environment }}'
param managedIdentityName = '#{{ infraResourceNamePrefix }}#{{ nc_resource_managedidentity }}#{{ nc_instance_regionid }}01-open-ai'

param openAiUserGroupId = '#{{ openAiUserGroupId }}'

param vnet = {
  name: '#{{ virtualNetworkName }}'
  resourceGroup: '#{{ virtualNetworkResourceGroup }}'
  subnetPrivateEndpoints: '#{{ networkResourceNamePrefix }}#{{ nc_resource_subnet }}#{{ nc_instance_regionid }}98'
}

param monitoringWorkspace = {
  name: '#{{ logAnalyticsWorkspace }}'
  resourceGroup: '#{{ servicesResourceGroup }}'
}

param deployments = [
  {
    name: 'gpt-4'
    model: {
      format: 'OpenAI'
      name: 'gpt-4'
      version: '#{{ openAiGpt4Version }}'
    }
    sku: {
      name: 'Standard'
      capacity: 10
    }
  }
  {
    name: 'gpt-35-turbo'
    model: {
      format: 'OpenAI'
      name: 'gpt-35-turbo'
      version: '#{{ openAiGpt35TurboVersion }}'
    }
    sku: {
      name: 'Standard'
      capacity: 10
    }
  }
  {
    name: 'text-embedding-3-large'
    model: {
      format: 'OpenAI'
      name: 'text-embedding-3-large'
      version: '#{{ openAiTextEmbedding3LargeVersion }}'
    }
    sku: {
      name: 'Standard'
      capacity: 10
    }
  }
  {
    name: 'text-embedding-ada-002'
    model: {
      format: 'OpenAI'
      name: 'text-embedding-ada-002'
      version: '#{{ openAiTextEmbeddingAda002Version }}'
    }
    sku: {
      name: 'Standard'
      capacity: 10
    }
  }
]
