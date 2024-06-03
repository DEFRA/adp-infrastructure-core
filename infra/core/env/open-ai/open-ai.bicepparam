using './open-ai.bicep'

param openAi = {
  name: '#{{ infraResourceNamePrefix }}#{{ nc_resource_openai }}#{{ nc_instance_regionid }}01'
  skuName: '#{{ openAiSkuName }}'
  customSubDomainName: '#{{ infraResourceNamePrefix }}#{{ nc_resource_openai }}#{{ nc_instance_regionid }}01'
}
param location = '#{{ location }}'
param environment = '#{{ environment }}'
param managedIdentityName = '#{{ infraResourceNamePrefix }}#{{ nc_resource_managedidentity }}#{{ nc_instance_regionid }}01-open-ai'
param deployments = [
  {
    name: 'gpt-4'
    model: {
      format: 'OpenAI'
      name: 'gpt-4'
      version: '0125-Preview'
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
      version: '1106'
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
      name: 'embedding'
      version: '1'
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
      name: 'embedding'
      version: '2'
    }
    sku: {
      name: 'Standard'
      capacity: 10
    }
  }
]
