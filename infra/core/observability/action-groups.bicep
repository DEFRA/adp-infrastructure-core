@description('Required. The name of the action groups to create.')
param actionGroups array 

@description('Required. Environment name.')
param environment string

@description('Optional. Date in the format yyyy-MM-dd.')
param createdDate string = utcNow('yyyy-MM-dd')

var commonTags = {  
  Location: 'global'
  CreatedDate: createdDate
  Environment: environment
  Purpose: 'ADP Platform Action Group'
  Tier: 'Shared'
}
var tags = union(loadJsonContent('../../common/default-tags.json'), commonTags)

module mActionGroups 'br/SharedDefraRegistry:insights.action-group:0.4.2' = [for actionGroup in actionGroups: {
  name: actionGroup.actionGroupName
  params: {
    name: actionGroup.actionGroupName
    groupShortName: actionGroup.actionGroupShortName
    tags: union(tags,{Name: actionGroup.actionGroupName})
    emailReceivers: actionGroup.emailReceivers
    armRoleReceivers: [
      {
        name: 'Monitoring Contributor'
        roleId: '749f88d5-cbae-40b8-bcfc-e573ddc772fa'
        useCommonAlertSchema: true
      }
      {
        name: 'Monitoring Reader'
        roleId: '43d0d8ad-25c7-4714-9337-8ba259a9fe05'
        useCommonAlertSchema: true
      }
    ]
  }
}]
