@description('The name of the Key Vault')
param keyVaultName string
@description('The name of the flexible server.')
param flexibleServerName string
@description('The administrator login for the flexible server.')
param administratorLogin string
@secure()
@description('The administrator login password for the flexible server.')
param administratorLoginPassword string

resource keyVault 'Microsoft.KeyVault/vaults@2023-02-01' existing = {
  name: keyVaultName
}

resource secretdbhost 'Microsoft.KeyVault/vaults/secrets@2019-09-01' = {
  name: 'POSTGRES-HOST'
  parent: keyVault 
  properties: {
    value: '${flexibleServerName}.postgres.database.azure.com'
  }
}

resource secretdbuser 'Microsoft.KeyVault/vaults/secrets@2019-09-01' = {
  name: 'POSTGRES-USER'
  parent: keyVault 
  properties: {
    value: administratorLogin
  }
}

resource secretdbpassword 'Microsoft.KeyVault/vaults/secrets@2019-09-01' = {
  name: 'POSTGRES-PASSWORD'
  parent: keyVault 
  properties: {
    value: administratorLoginPassword
  }
}
