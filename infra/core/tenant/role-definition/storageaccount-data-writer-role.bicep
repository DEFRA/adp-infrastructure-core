targetScope = 'subscription'

@description('Name of the Custom Role Definition in Azure.')
param roleName string

@description('Array of scopes to assign the role to.')
param roleScopes array

@description('Detailed description of the role definition')
param roleDescription string = 'This custom role is designed to write data to Azure storage accounts, including blob, file, and table storage.'

resource asbCustomRoleResource 'Microsoft.Authorization/roleDefinitions@2022-04-01' = {
  name: guid(subscription().id, roleName)
  scope: subscription()
  properties: {
    assignableScopes: roleScopes
    description: roleDescription
    permissions: [
      {
        actions: [
          'Microsoft.Storage/storageAccounts/blobServices/containers/*'
          'Microsoft.Storage/storageAccounts/blobServices/generateUserDelegationKey/action'
          'Microsoft.Storage/storageAccounts/tableServices/tables/read'
          'Microsoft.Storage/storageAccounts/tableServices/tables/write'
          'Microsoft.Storage/storageAccounts/tableServices/tables/delete'
        ]
        dataActions: [
          'Microsoft.Storage/storageAccounts/blobServices/containers/blobs/*'
          'Microsoft.Storage/storageAccounts/tableServices/tables/entities/read'
          'Microsoft.Storage/storageAccounts/tableServices/tables/entities/write'
          'Microsoft.Storage/storageAccounts/tableServices/tables/entities/delete'
          'Microsoft.Storage/storageAccounts/tableServices/tables/entities/add/action'
          'Microsoft.Storage/storageAccounts/tableServices/tables/entities/update/action'
          'Microsoft.Storage/storageAccounts/fileServices/fileshares/files/read'
          'Microsoft.Storage/storageAccounts/fileServices/fileshares/files/write'
          'Microsoft.Storage/storageAccounts/fileServices/fileshares/files/delete'
          'Microsoft.Storage/storageAccounts/fileServices/fileshares/files/modifypermissions/action'
        ]
        notActions: []
        notDataActions: []
      }
    ]
    roleName: roleName
    type: 'customRole'
  }
}
