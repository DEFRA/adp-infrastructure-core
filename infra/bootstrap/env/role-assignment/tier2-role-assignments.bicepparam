using './tier2-role-assignments.bicep'

param principalId = az.getSecret('#{{ ssvSubscriptionId }}', '#{{ ssvSharedResourceGroup }}', '#{{ ssvPlatformKeyVaultName }}', '#{{ tier2ApplicationSPObjectIdSecretName }}')

param subcriptionRoleAssignments_aa = [
    {
        roleAssignmentDescription: 'Contributor role assignment to environment specific subscription'
        roleDefinitionName: 'Contributor'
    }
    {
        roleAssignmentDescription: 'User Acess Administrator to environment specific subscription'
        roleDefinitionName: 'User Access Administrator'
    }
]

param sharedContainerRegistry = {
    name: '#{{ ssvSharedAcrName }}'
    resourceGroup: '#{{ ssvSharedResourceGroup }}'
    subscriptionId: '#{{ ssvSubscriptionId }}'
  }