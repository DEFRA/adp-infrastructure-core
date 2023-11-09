using './action-groups.bicep'

param actionGroups = [
  {
    actionGroupName: '#{{ infraResourceNamePrefix }}#{{ nc_resource_actiongroups }}#{{ nc_instance_regionid }}01'
    actionGroupShortName: 'INF-Warning'
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
    actionGroupShortName: 'INF-Critical'
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
