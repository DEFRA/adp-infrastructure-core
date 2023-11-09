@description('Required. The name of the action groups to create.')
param alertRules array 

@description('Required. Environment name.')
param environment string

@description('Optional. Date in the format yyyy-MM-dd.')
param createdDate string = utcNow('yyyy-MM-dd')

@description('Optional. Date in the format yyyyMMdd-HHmmss.')
param deploymentDate string = utcNow('yyyyMMdd-HHmmss')

var commonTags = {  
  Location: 'global'
  CreatedDate: createdDate
  Environment: environment
  Purpose: 'ADP Platform Action Group'
  Tier: 'Shared'
}
var tags = union(loadJsonContent('../../common/default-tags.json'), commonTags)

module mAlertRules 'br/SharedDefraRegistry:insights.metric-alert:0.4.2' = [for alertRule in alertRules: {
  name: 'alertRule-${deploymentDate}'
  params: {
      name: alertRule.name
      criterias: alertRule.criterias
      actions: [{
        actionGroupId: resourceId('Microsoft.Insights/actionGroups', alertRule.actionGroupId)
      }]
      tags: union(tags,{Name: alertRule.name})
      alertCriteriaType: alertRule.alertCriteriaType
      alertDescription: alertRule.alertDescription
      autoMitigate : alertRule.autoMitigate
      evaluationFrequency: alertRule.evaluationFrequency
      scopes : alertRule.scopes
      severity: alertRule.severity
      windowSize : alertRule.windowSize
  }
}]
