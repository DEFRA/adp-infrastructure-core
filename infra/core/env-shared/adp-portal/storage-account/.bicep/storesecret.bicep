
@description('Required. Storage name.')
param storageAccountname string

@description('Required. The name of the key vault where the secrets will be stored.')
param keyvaultName string

resource storageAccountResource 'Microsoft.Storage/storageAccounts@2021-09-01' existing = {
  name: toLower(storageAccountname)
}

resource keyVault 'Microsoft.KeyVault/vaults@2023-02-01' existing = {
  name: keyvaultName
}

resource accountKey 'Microsoft.KeyVault/vaults/secrets@2019-09-01' = {
  name: 'TECHDOCS-AZURE-BLOB-STORAGE-ACCOUNT-KEY'
  parent: keyVault
  properties: {
    value: storageAccountResource.listKeys().keys[0].value
  }
}

resource accountName 'Microsoft.KeyVault/vaults/secrets@2019-09-01' = {
  name: 'TECHDOCS-AZURE-BLOB-STORAGE-ACCOUNT-NAME'
  parent: keyVault
  properties: {
    value: toLower(storageAccountname)
  }
}
