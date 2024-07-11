using './open-ai-access.bicep'

param resourcesReaderGroupObjectId = '#{{ resourcesReaderGroupId }}'
param resourcesReadWriteGroupObjectId = '#{{ resourcesDataReadWriteGroupId }}'

param deployOpenAIContributorRole = '#{{ deployOpenAI.contributorRole }}'
param deployOpenAIReaderRole = '#{{ deployOpenAI.userRole }}'
