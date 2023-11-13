using './alert-rules.bicep'

param environment = '#{{ environment }}'

param targetResourceRegion = '#{{ location }}'

param alertNamePrefix = '#{{ infraResourceNamePrefix }}#{{ nc_resource_alertrules }}#{{ nc_instance_regionid }}'

param actionGroupNamePrefix = '#{{ infraResourceNamePrefix }}#{{ nc_resource_actiongroups }}#{{ nc_instance_regionid }}'

param activityLogAlertRules = [
  {
    name: '-SH01'
    alertDescription: 'Searvice Helth Alert'
    conditions: [
      {
        field: 'category'
        equals: 'ServiceHealth'
      }
      {
        field: 'properties.impactedServices[*].ServiceName'
        containsAny: [
          'Azure Database for PostgreSQL flexible servers'
          'Azure Frontdoor'
          'Azure Kubernetes Service (AKS)'
          'Container Registry'
          'Service Bus'
          'Key Vault'
          'Redis Cache'
          'Azure Container Registry'
          'Azure DNS'
          'Azure Managed Grafana'
          'Virtual Network'
          'Virtual Machine Scale Sets'
        ]
      }
      {
        field: 'properties.impactedServices[*].ImpactedRegions[*].RegionName'
        containsAny: [
          'UK South'
          'UK West'
          'Global'
        ]
      }
    ]
    actionGroupId: '01'
  }
]

param alertRules = [

  {
    name: '-RC01'
    criterias: [
      {
        name: 'Metric1'
        criterionType: 'StaticThresholdCriterion'
        threshold: 60
        metricNamespace: 'Microsoft.Cache/Redis'
        metricName: 'serverLoad'
        operator: 'GreaterThan'
        timeAggregation: 'Average'
        skipMetricValidation: false

      }
    ]
    actionGroupId: '02'
    alertDescription: 'Redis Cache serverLoad Above 60% for 15min'
    evaluationFrequency: 'PT5M'
    windowSize: 'PT15M'
    targetResourceType: 'Microsoft.Cache/redis'
    severity: 2
  }
  {
    name: '-RC02'
    criterias: [
      {
        name: 'Metric1'
        criterionType: 'StaticThresholdCriterion'
        threshold: 80
        metricNamespace: 'Microsoft.Cache/Redis'
        metricName: 'serverLoad'
        operator: 'GreaterThan'
        timeAggregation: 'Average'
        skipMetricValidation: false

      }
    ]
    actionGroupId: '01'
    alertDescription: 'Redis Cache serverLoad Above 80% for 15min'
    evaluationFrequency: 'PT5M'
    windowSize: 'PT15M'
    targetResourceType: 'Microsoft.Cache/redis'
    severity: 1
  }
  {
    name: '-RC03'
    criterias: [
      {
        name: 'Metric1'
        criterionType: 'StaticThresholdCriterion'
        threshold: 60
        metricNamespace: 'Microsoft.Cache/Redis'
        metricName: 'usedmemorypercentage'
        operator: 'GreaterThan'
        timeAggregation: 'Average'
        skipMetricValidation: false

      }
    ]
    actionGroupId: '02'
    alertDescription: 'Redis Cache usedmemorypercentage Above 60% for 15min'
    evaluationFrequency: 'PT5M'
    windowSize: 'PT15M'
    targetResourceType: 'Microsoft.Cache/redis'
    severity: 2
  }
  {
    name: '-RC04'
    criterias: [
      {
        name: 'Metric1'
        criterionType: 'StaticThresholdCriterion'
        threshold: 80
        metricNamespace: 'Microsoft.Cache/Redis'
        metricName: 'usedmemorypercentage'
        operator: 'GreaterThan'
        timeAggregation: 'Average'
        skipMetricValidation: false

      }
    ]
    actionGroupId: '01'
    alertDescription: 'Redis Cache usedmemorypercentage Above 80% for 15min'
    evaluationFrequency: 'PT5M'
    windowSize: 'PT15M'
    targetResourceType: 'Microsoft.Cache/redis'
    severity: 1
  }
{
    name: '-AC01'
    criterias: [
      {
        name: 'Metric1'
        criterionType: 'StaticThresholdCriterion'
        threshold: 60
        metricNamespace: 'Microsoft.AppConfiguration/configurationStores'
        metricName: 'DailyStorageUsage'
        operator: 'GreaterThan'
        timeAggregation: 'Maximum'
        skipMetricValidation: false

      }
    ]
    actionGroupId: '02'
    alertDescription: 'App Config DailyStorageUsage Above 60% for 15min'
    evaluationFrequency: 'PT5M'
    windowSize: 'PT15M'
    targetResourceType: 'Microsoft.AppConfiguration/configurationStores'
    scopes: [
      '/subscriptions/#{{ SubscriptionId }}/resourceGroups/#{{ servicesResourceGroup }}/providers/Microsoft.AppConfiguration/configurationStores/#{{ infraResourceNamePrefix }}#{{ nc_resource_appconfiguration }}#{{ nc_instance_regionid }}01'        
    ]
    severity: 2
  }
  {
    name: '-AC02'
    criterias: [
      {
        name: 'Metric1'
        criterionType: 'StaticThresholdCriterion'
        threshold: 80
        metricNamespace: 'Microsoft.AppConfiguration/configurationStores'
        metricName: 'DailyStorageUsage'
        operator: 'GreaterThan'
        timeAggregation: 'Maximum'
        skipMetricValidation: false

      }
    ]
    actionGroupId: '01'
    alertDescription: 'App Config DailyStorageUsage Above 80% for 15min'
    evaluationFrequency: 'PT5M'
    windowSize: 'PT15M'
    targetResourceType: 'Microsoft.AppConfiguration/configurationStores'
    scopes: [
      '/subscriptions/#{{ SubscriptionId }}/resourceGroups/#{{ servicesResourceGroup }}/providers/Microsoft.AppConfiguration/configurationStores/#{{ infraResourceNamePrefix }}#{{ nc_resource_appconfiguration }}#{{ nc_instance_regionid }}01'        
    ]
    severity: 1
  }
]


