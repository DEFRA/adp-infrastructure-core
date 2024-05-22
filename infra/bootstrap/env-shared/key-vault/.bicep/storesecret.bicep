
@description('Required. app Insight Connection String.')
param appInsightConnectionString string

@description('Required. The name of the key vault where the secrets will be stored.')
param keyvaultName string

resource keyVault 'Microsoft.KeyVault/vaults@2023-02-01' existing = {
  name: keyvaultName
}

resource accountKey 'Microsoft.KeyVault/vaults/secrets@2019-09-01' = {
  name: 'SHARED-APPINSIGHTS-CONNECTIONSTRING'
  parent: keyVault
  properties: {
    value: appInsightConnectionString
  }
}


