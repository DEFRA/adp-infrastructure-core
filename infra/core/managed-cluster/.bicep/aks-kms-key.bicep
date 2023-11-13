@description('Required. Key Management Service encryption key name')
param aksKmsKeyName string
@description('Required. KeyVault name')
param keyVaultName string
@description('Required. Rotate KMS Key')
param rotateKmsKey string
param baseTime string = utcNow('u')

var convertToEpoch = dateTimeToEpoch(dateTimeAdd(baseTime, 'P1Y'))

resource keyVault 'Microsoft.KeyVault/vaults@2021-10-01' existing = {
  name: keyVaultName
}

resource kvKeyNew 'Microsoft.KeyVault/vaults/keys@2022-07-01' = if (rotateKmsKey == 'True') {
  parent: keyVault
  name: aksKmsKeyName
  properties: {
    attributes: {
      exp: convertToEpoch
    }
    kty: 'RSA'
    keySize: 2048
    keyOps: ['decrypt', 'encrypt', 'sign', 'unwrapKey', 'verify', 'wrapKey']
  }
}

resource kvKeyExisting 'Microsoft.KeyVault/vaults/keys@2022-07-01' existing = if (rotateKmsKey == 'False') {
  parent: keyVault
  name: aksKmsKeyName
}

@description('The uri including version of the KMS Key.')
output keyUriWithVersion string = ((rotateKmsKey == 'new') ? kvKeyNew.properties.keyUriWithVersion : kvKeyExisting.properties.keyUriWithVersion)

@description('The uri including version of the KMS Key.')
output keyVaultResourceId string = keyVault.id
