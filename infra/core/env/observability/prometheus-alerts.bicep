@description('Required. The email address to send alerts to.')
param alertsEmailAddress string = 'adp-cluster-alerts-aaaanikt2oqwk5twfbbncneou4@defra-digital-team.slack.com'

@description('Required. The environment to monitor.')
param environment string = 'SND'

@description('Required. The environment id.')
param environmentId string = '1'

@description('Required. The Azure Monitor workspace name.')
param azureMonitorWorkspace string

@description('Required. The location of the Prometheus Rule Group.')
param location string

@description('Required. The alert rules to monitor.')
param alerts array

resource monitorWorkspace 'Microsoft.Monitor/accounts@2021-06-03-preview' existing = {
  name: azureMonitorWorkspace
}

resource actionGroup 'Microsoft.Insights/actionGroups@2023-01-01' = {
  name: 'SystemAlerts${environment}0${environmentId}'
  location: 'Global'
  tags: {
    ServiceCode: 'ADP'
  }
  properties: {
    groupShortName: 'Alerts${environment}0${environmentId}'
    enabled: true
    emailReceivers: [
      {
        emailAddress: alertsEmailAddress
        name: 'Adp Cluster Alerts Email Notification'
        useCommonAlertSchema: true
      }
    ]
  }
}

resource systemAlertsRuleGroup 'Microsoft.AlertsManagement/prometheusRuleGroups@2021-07-22-preview' = {
  name: 'SystemAlerts-${environment}0${environmentId}'
  location: location
  properties: {
    description: 'Kubernetes  System Alerts'
    scopes: [
      monitorWorkspace.id
    ]
    enabled: true
    interval: 'PT1M'
    rules: [
      for alert in alerts: {
        alert: alert.name
        expression: alert.expression
        for: alert.timePeriod
        labels: {
          severity: 'warning'
        }
        severity: 4
        enabled: true
        annotations: {
          description: alert.description
        }
        resolveConfiguration: {
          autoResolved: true
          timeToResolve: alert.timeToResolve
        }
        actions: [
          {
            actionGroupId: actionGroup.id
          }
        ]
      }
    ]
  }
}
