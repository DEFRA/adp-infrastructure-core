using './cluster-custom-resources-reader-role.bicep'

param roleName = '#{{ customRoleCustomResourcesReader }}'

param principalId = '#{{ portalAppPrincipalId }}'
