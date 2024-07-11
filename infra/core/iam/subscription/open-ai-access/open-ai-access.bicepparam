using './open-ai-access.bicep'

param resourcesReaderGroupObjectId = '#{{ resourcesReaderGroupId }}'
param resourcesReadWriteGroupObjectId = '#{{ resourcesDataReadWriteGroupId }}'

param deployOpenAIContributorRole = '#{{ deployOpenAIContributorRole }}'
param deployOpenAIReaderRole = '#{{ deployOpenAIUserRole }}'

