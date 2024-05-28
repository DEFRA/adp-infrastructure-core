targetScope = 'subscription'

@description('Name of the Custom Role Definition in Azure.')
param roleName string

@description('Array of scopes to assign the role to.')
param roleScopes array

@description('Detailed description of the role definition')
param roleDescription string = 'This custom role is designed to provide read access to data in Azure storage accounts, from blob, file, and table storage.'

resource asbCustomRoleResource 'Microsoft.Authorization/roleDefinitions@2022-04-01' = {
  name: guid(subscription().id, roleName)
  scope: subscription()
  properties: {
    assignableScopes: roleScopes
    description: roleDescription
    permissions: [
      {
        actions: [
          'Microsoft.Storage/storageAccounts/blobServices/containers/read'
          'Microsoft.Storage/storageAccounts/blobServices/generateUserDelegationKey/action'
          'Microsoft.Storage/storageAccounts/tableServices/tables/read'
        ]
        dataActions: [
          'Microsoft.Storage/storageAccounts/blobServices/containers/blobs/read'
          'Microsoft.Storage/storageAccounts/tableServices/tables/entities/read'
          'Microsoft.Storage/storageAccounts/fileServices/fileshares/files/read'
        ]
        notActions: []
        notDataActions: []
      }
    ]
    roleName: roleName
    type: 'customRole'
  }
}
