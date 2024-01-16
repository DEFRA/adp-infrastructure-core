targetScope = 'resourceGroup'

@description('Required. The name of the shared key vault where the app URL will be stored to be used by Front Door deployment')
param ssvPlatformKeyVaultName string

@description('Required. The name of the shared key vault Resource Group')
param ssvPlatformKeyVaultRG string

@description('Required. secret name')
param secretName string

@description('Required. secret name')
@secure()
param secretValue string

resource sharedKeyVault 'Microsoft.KeyVault/vaults@2023-02-01' existing = {
  name: ssvPlatformKeyVaultName
  scope: resourceGroup(ssvPlatformKeyVaultRG)
}

resource secret 'Microsoft.KeyVault/vaults/secrets@2019-09-01' = {
  name: '${sharedKeyVault.name}/${secretName}'
  properties: {
    value: secretValue
  }
}
