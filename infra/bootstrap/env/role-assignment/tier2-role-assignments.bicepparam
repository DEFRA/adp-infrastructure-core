using './tier2-role-assignments.bicep'

param subscriptionId = '#{{ subscriptionId }}'

param principalId = az.getSecret('#{{ ssvSubscriptionId }}', '#{{ ssvSharedResourceGroup }}', '#{{ ssvPlatformKeyVaultName }}', '#{{ tier2ApplicationSPObjectIdSecretName }}')

param subcriptionRoleAssignments = [
    {
        roleAssignmentDescription: 'Contributor role assignment to environment specific subscription'
        roleDefinitionName: 'Contributor'
    }
    {
        roleAssignmentDescription: 'User Acess Administrator to environment specific subscription'
        roleDefinitionName: 'UserAccessAdministrator'
    }
]

param sharedContainerRegistry = {
    name: '#{{ ssvSharedAcrName }}'
    resourceGroup: '#{{ ssvSharedResourceGroup }}'
    subscriptionId: '#{{ ssvSubscriptionId }}'
  }