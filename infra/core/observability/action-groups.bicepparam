using './action-groups.bicep'

param actionGroups = [
  {
    actionGroupName: '#{{ infraResourceNamePrefix }}#{{ nc_resource_actiongroups }}#{{ nc_instance_regionid }}01'
    actionGroupShortName: 'Infra-Warning'
    emailReceivers: [
      {
        name: 'Infrastructure Team'
        emailAddress: ''
        useCommonAlertSchema: true
      }
    ]
  }
  {
    actionGroupName: '#{{ infraResourceNamePrefix }}#{{ nc_resource_actiongroups }}#{{ nc_instance_regionid }}02'
    actionGroupShortName: 'Infra-Critical'
    emailReceivers: [
      {
        name: 'Infrastructure Team'
        emailAddress: ''
        useCommonAlertSchema: true
      }
    ]
  }
]

param environment = '#{{ environment }}'
