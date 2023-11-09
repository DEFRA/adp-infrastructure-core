using './alert-rules.bicep'

param alertRules = [
  {
    name: '#{{ infraResourceNamePrefix }}#{{ nc_resource_alertrules }}#{{ nc_instance_regionid }}01'
    actionGroupShortName: 'Redis Cache Server Load Warning'
    criterias: [
      {
        metricName: 'allserverLoad'
        metricNamespace: 'Microsoft.Cache/redis'
        operator: 'GreaterThan'
        threshold: 60
        timeAggregation: 'Maximum'
      }
    ]
    actionGroupId: '#{{ infraResourceNamePrefix }}#{{ nc_resource_actiongroups }}#{{ nc_instance_regionid }}01'    
    alertCriteriaType: 'Microsoft.Azure.Monitor.SingleResourceMultipleMetricCriteria'
    alertDescription: 'Redis Cache Server Load Above 60% for 15min'
    autoMitigate: true
    evaluationFrequency: 'PT5M'
    windowSize : 'PT15M'
    targetResourceType: 'Microsoft.Cache/redis'
    scopes: [
      '[subscription().id]'
    ]
    severity: 2
  }

]

param environment = '#{{ environment }}'
