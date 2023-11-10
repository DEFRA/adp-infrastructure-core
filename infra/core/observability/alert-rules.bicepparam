using './alert-rules.bicep'

param activityLogAlertRules = [
  {
    name: '#{{ infraResourceNamePrefix }}#{{ nc_resource_alertrules }}#{{ nc_instance_regionid }}01'
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
    actionGroupId: '#{{ infraResourceNamePrefix }}#{{ nc_resource_actiongroups }}#{{ nc_instance_regionid }}01'
  }
]

param alertRules = [

  {
    name: '#{{ infraResourceNamePrefix }}#{{ nc_resource_alertrules }}#{{ nc_instance_regionid }}02'
    criterias: [
      {
        threshold: 80
        name: 'Metric1'
        metricNamespace: 'Microsoft.Cache/Redis'
        metricName: 'usedmemorypercentage'
        operator: 'GreaterThan'
        timeAggregation: 'Average'
        skipMetricValidation: false
        criterionType: 'StaticThresholdCriterion'
      }
    ]
    actionGroupId: '#{{ infraResourceNamePrefix }}#{{ nc_resource_actiongroups }}#{{ nc_instance_regionid }}01'
    alertDescription: 'Redis Cache usedmemorypercentage Above 80% for 15min'
    evaluationFrequency: 'PT5M'
    windowSize: 'PT15M'
    targetResourceType: 'Microsoft.Cache/redis'
    severity: 2
  }

]

param environment = '#{{ environment }}'

param targetResourceRegion = '#{{ location }}'
