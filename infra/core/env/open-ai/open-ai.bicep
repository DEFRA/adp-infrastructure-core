@description('Required. The object of Open AI Resource. The object must contain name, SKU and customSubDomainName  properties.')
param openAi object

@allowed([
  'UKSouth'
])
@description('Required. The Azure region where the resources will be deployed.')
param location string
@description('Required. Environment name.')
param environment string
@description('Optional. Date in the format yyyy-MM-dd.')
param createdDate string = utcNow('yyyy-MM-dd')
@description('Optional. Date in the format yyyyMMdd-HHmmss.')
param deploymentDate string = utcNow('yyyyMMdd-HHmmss')

var customTags = {
  Name: openAi.name
  Location: location
  CreatedDate: createdDate
  Environment: environment
  Purpose: 'ADP OPEN AI'
}

var defaultTags = union(json(loadTextContent('../../../common/default-tags.json')), customTags)


module openAIDeployment 'br/avm:cognitive-services/account:0.5.3' = {
  name: 'opan-ai-${deploymentDate}'
  params: {
    kind: 'OpenAI'
    name: openAi.name
    location: location
    lock: {
      kind: 'CanNotDelete'
      name: 'CanNotDelete'
    }
    sku: openAi.skuName
    tags: union(defaultTags, customTags)
  }  
}
