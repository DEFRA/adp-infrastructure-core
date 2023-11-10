@description('Required. The name of the activity Log Alert Rules to create.')
param activityLogAlertRules array

@description('Required. The name of the alert rules to create.')
param alertRules array

@description('Required. Environment name.')
param environment string

@description('Required. Alert target region.')
param targetResourceRegion string

@description('Optional. Date in the format yyyy-MM-dd.')
param createdDate string = utcNow('yyyy-MM-dd')

var subscriptionScope = '/subscriptions/${subscription().subscriptionId}'
var alertCriteriaType = 'Microsoft.Azure.Monitor.MultipleResourceMultipleMetricCriteria'
var commonTags = {
  Location: 'global'
  CreatedDate: createdDate
  Environment: environment
  Purpose: 'ADP Platform Action Group'
  Tier: 'Shared'
}
var tags = union(loadJsonContent('../../common/default-tags.json'), commonTags)

module mActivityLogAlertRules 'br/SharedDefraRegistry:insights.activity-log-alert:0.4.2' = [for activityLogAlertRule in activityLogAlertRules: {
  name: activityLogAlertRule.name
  params: {
    name: activityLogAlertRule.name
    alertDescription: activityLogAlertRule.alertDescription
    conditions: activityLogAlertRule.conditions
    actions: [ {
        actionGroupId: resourceId('Microsoft.Insights/actionGroups', activityLogAlertRule.actionGroupId)
      } ]
    scopes: [
      subscriptionScope
    ]
    tags: union(tags, { Name: activityLogAlertRule.name })
  }
}]

module mAlertRules 'br/SharedDefraRegistry:insights.metric-alert:0.4.2' = [for alertRule in alertRules: {
  name: alertRule.name
  params: {
    name: alertRule.name
    alertDescription: alertRule.alertDescription
    criterias: alertRule.criterias
    actions: [ {
        actionGroupId: resourceId('Microsoft.Insights/actionGroups', alertRule.actionGroupId)
      } ]
    tags: union(tags, { Name: alertRule.name })
    alertCriteriaType: alertCriteriaType
    autoMitigate:  (contains(alertRule, 'autoMitigate')  ? alertRule.autoMitigate : true)
    evaluationFrequency: alertRule.evaluationFrequency
    targetResourceType: alertRule.targetResourceType
    targetResourceRegion: (contains(alertRule, 'targetResourceRegion')  ? alertRule.targetResourceRegion : targetResourceRegion)
    severity: alertRule.severity
    windowSize: alertRule.windowSize
    scopes: (contains(alertRule, 'scopes')  ? alertRule.scopes : [ subscriptionScope ])
  }
}]
