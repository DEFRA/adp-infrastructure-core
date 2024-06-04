@description('Required. The name of the Search service.')
param searchServiceName string

@description('Required. The name of the Open AI service.')
param openAiName string

resource openAi 'Microsoft.CognitiveServices/accounts@2023-10-01-preview' existing = {
  name: openAiName
}

resource searchService 'Microsoft.Search/searchServices@2023-11-01' existing = {
  name: searchServiceName
}

resource sharedPrivateLinkResource 'Microsoft.Search/searchServices/sharedPrivateLinkResources@2024-03-01-preview' = {
  parent: searchService
  name: '${uniqueString(deployment().name)}-searchService-SharedPrivateLink'
  properties: {
    privateLinkResourceId: openAi.id
    groupId: 'account'
    requestMessage: 'Please approve this request'
  }
}
