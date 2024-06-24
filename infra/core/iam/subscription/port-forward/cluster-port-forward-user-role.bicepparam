using './cluster-port-forward-user-role.bicep'

param roleName = '#{{ customRolePortForwardUserRoleId }}'

param groupObjectId = '#{{ customRolePortForwardUserGroupId }}'

param deployClusterPortForwardRole = #{{ deployClusterPortForwardRole }}
