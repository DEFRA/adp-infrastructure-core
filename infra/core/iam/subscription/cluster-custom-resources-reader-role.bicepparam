using './cluster-custom-resources-reader-role.bicep'

param roleName = '#{{ customRoleCustomResourcesReaderRoleId }}'

param principalId = '#{{ portalAppPrincipalId }}'

param groupObjectId = '#{{ customRoleCustomResourcesReaderGroupId }}'
