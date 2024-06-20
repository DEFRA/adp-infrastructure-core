using './cluster-port-forward-role.bicep'

param roleName = '#{{ customRolePortForwardUserRoleId }}'

param groupObjectId = '#{{ customRolePortForwardUserGroupId }}'

param environment = '#{{ environment }}'
