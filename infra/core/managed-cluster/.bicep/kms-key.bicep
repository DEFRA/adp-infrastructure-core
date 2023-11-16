@description('Required. KeyVault name')
param keyVaultName string
@description('Optional. Date to add as a suffix to the Key Name')
param keySuffix string = utcNow('yyyyMMdd-HHmmss')
@description('Optional. Date to be passed into the dateTimeToEpoch function')
param baseTime string = utcNow()

var convertToEpoch = dateTimeToEpoch(dateTimeAdd(baseTime, 'P1Y'))

resource keyVault 'Microsoft.KeyVault/vaults@2021-10-01' existing = {
  name: keyVaultName
}

resource kvKeyNew 'Microsoft.KeyVault/vaults/keys@2022-07-01' = {
  parent: keyVault
  name: 'aksKmsKey-${keySuffix}'
  properties: {
    attributes: {
      exp: convertToEpoch
    }
    kty: 'RSA'
    keySize: 2048
    keyOps: ['decrypt', 'encrypt']
  }
}

@description('The uri including version of the KMS Key.')
output keyUriWithVersion string = kvKeyNew.properties.keyUriWithVersion

@description('The uri including version of the KMS Key.')
output keyVaultResourceId string = keyVault.id
