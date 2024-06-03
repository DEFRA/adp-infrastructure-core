using './open-ai.bicep'

param openAi = {
  name: '#{{ dbsResourceNamePrefix }}#{{ nc_resource_openai }}#{{ nc_instance_regionid }}01'
  skuName: '#{{ openAiSkuName }}'
}
param location = '#{{ location }}'
param environment = '#{{ environment }}'
