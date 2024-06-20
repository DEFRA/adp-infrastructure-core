@description('Required. The email address to send alerts to.')
param alertsEmailAddress string = 'adp-cluster-alerts-aaaanikt2oqwk5twfbbncneou4@defra-digital-team.slack.com'

@description('Required. The environment to monitor.')
param environment string = 'SND'

@description('Required. The environment id.')
param environmentId string = '1'

@description('Required. The parameter object for the azure monitor workspace service. The object must contain name, resourceGroup and subscriptionId.')
param azureMonitorWorkspace object

@description('Required. The location of the Prometheus Rule Group.')
param location string

@description('Required. The alert rules to monitor.')
param alerts array

resource monitorWorkspace 'Microsoft.Monitor/accounts@2021-06-03-preview' existing = {
  scope: resourceGroup(azureMonitorWorkspace.resourceGroup)
  name: azureMonitorWorkspace.name
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

    // [
    //   {
    //     alert: 'KubePodCrashLooping'
    //     expression: 'max_over_time(kube_pod_container_status_waiting_reason{reason="CrashLoopBackOff", job="kube-state-metrics", namespace=~"${systemNamespaces}"}[5m]) >= 1'
    //     // expression: 'max_over_time(kube_pod_container_status_waiting_reason{reason="CrashLoopBackOff", job="kube-state-metrics"}[5m]) >= 1'
    //     for: 'PT1M'
    //     labels: {
    //       severity: 'warning'
    //     }
    //     severity: 4
    //     enabled: true
    //     resolveConfiguration: {
    //       autoResolved: true
    //       timeToResolve: 'PT15M'
    //     }
    //     actions: [
    //       {
    //         actionGroupId: actionGroup.id
    //       }
    //     ]
    //   }
    //   {
    //     alert: 'KubePodOutOfMemory'
    //     expression: 'kube_pod_container_status_last_terminated_reason{reason="oomkilled", namespace=~"${systemNamespaces}"} >= 1'      
    //     for: 'PT1M'
    //     labels: {
    //       severity: 'warning'
    //     }
    //     severity: 4
    //     enabled: true
    //     resolveConfiguration: {
    //       autoResolved: true
    //       timeToResolve: 'PT15M'
    //     }
    //     actions: [
    //       {
    //         actionGroupId: actionGroup.id
    //       }
    //     ]
    //   }
    //   {
    //     alert: 'KubePodContainerRestart'
    //     expression: 'sum by (namespace, controller, container, cluster)(increase(kube_pod_container_status_restarts_total{job="kube-state-metrics", namespace=~"${systemNamespaces}"}[1h])* on(namespace, pod, cluster) group_left(controller) label_replace(kube_pod_owner, "controller", "$1", "owner_name", "(.*)")) > 0'       
    //     for: 'PT1M'
    //     labels: {
    //       severity: 'warning'
    //     }
    //     severity: 4
    //     enabled: true
    //     annotations: {
    //       description: 'Pod container restarted in last 1 hour. For more information on this alert, please refer to this [link](https://aka.ms/aks-alerts/pod-level-recommended-alerts).'
    //     }
    //     resolveConfiguration: {
    //       autoResolved: true
    //       timeToResolve: 'PT10M'
    //     }
    //     actions: [
    //       {
    //         actionGroupId: actionGroup.id
    //       }
    //     ]
    //   }
    // ]
  }
}
