using './servicebus-customrole.bicep'

param roleName = '#{{ serviceBusAsoOwnerCustomRole }}'

param roleScopes = #{{ noescape(serviceBusAsoOwnerCustomRoleScopes) }}

