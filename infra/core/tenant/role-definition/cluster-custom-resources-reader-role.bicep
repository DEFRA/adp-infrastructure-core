targetScope = 'subscription'

@description('Name of the Custom Role Definition in Azure.')
param roleName string

@description('Array of scopes to assign the role to.')
param roleScopes array

@description('Detailed description of the role definition')
param roleDescription string = 'Custom Role to read cluster data.'

resource asbCustomRoleResource 'Microsoft.Authorization/roleDefinitions@2022-04-01' = {
  name: guid(subscription().id, roleName)
  scope: subscription()
  properties: {
    assignableScopes: roleScopes
    description: roleDescription
    permissions: [
      {
        actions: [
          'Microsoft.Authorization/*/read'
          'Microsoft.Resources/subscriptions/operationresults/read'
          'Microsoft.Resources/subscriptions/read'
          'Microsoft.Resources/subscriptions/resourceGroups/read'
          'Microsoft.ContainerService/managedClusters/listClusterUserCredential/action'
          'Microsoft.ContainerService/managedClusters/read'
        ]
        dataActions: [
          'Microsoft.ContainerService/managedClusters/apps/controllerrevisions/read'
          'Microsoft.ContainerService/managedClusters/apps/daemonsets/read'
          'Microsoft.ContainerService/managedClusters/apps/deployments/read'
          'Microsoft.ContainerService/managedClusters/apps/replicasets/read'
          'Microsoft.ContainerService/managedClusters/apps/statefulsets/read'
          'Microsoft.ContainerService/managedClusters/autoscaling/horizontalpodautoscalers/read'
          'Microsoft.ContainerService/managedClusters/batch/cronjobs/read'
          'Microsoft.ContainerService/managedClusters/batch/jobs/read'
          'Microsoft.ContainerService/managedClusters/configmaps/read'
          'Microsoft.ContainerService/managedClusters/discovery.k8s.io/endpointslices/read'
          'Microsoft.ContainerService/managedClusters/endpoints/read'
          'Microsoft.ContainerService/managedClusters/events.k8s.io/events/read'
          'Microsoft.ContainerService/managedClusters/events/read'
          'Microsoft.ContainerService/managedClusters/extensions/daemonsets/read'
          'Microsoft.ContainerService/managedClusters/extensions/deployments/read'
          'Microsoft.ContainerService/managedClusters/extensions/ingresses/read'
          'Microsoft.ContainerService/managedClusters/extensions/networkpolicies/read'
          'Microsoft.ContainerService/managedClusters/extensions/replicasets/read'
          'Microsoft.ContainerService/managedClusters/limitranges/read'
          'Microsoft.ContainerService/managedClusters/metrics.k8s.io/pods/read'
          'Microsoft.ContainerService/managedClusters/metrics.k8s.io/nodes/read'
          'Microsoft.ContainerService/managedClusters/namespaces/read'
          'Microsoft.ContainerService/managedClusters/networking.k8s.io/ingresses/read'
          'Microsoft.ContainerService/managedClusters/networking.k8s.io/networkpolicies/read'
          'Microsoft.ContainerService/managedClusters/persistentvolumeclaims/read'
          'Microsoft.ContainerService/managedClusters/pods/read'
          'Microsoft.ContainerService/managedClusters/policy/poddisruptionbudgets/read'
          'Microsoft.ContainerService/managedClusters/replicationcontrollers/read'
          'Microsoft.ContainerService/managedClusters/resourcequotas/read'
          'Microsoft.ContainerService/managedClusters/serviceaccounts/read'
          'Microsoft.ContainerService/managedClusters/services/read'
          'Microsoft.ContainerService/managedClusters/apiextensions.k8s.io/customresourcedefinitions/read'
        ]
        notActions: []
        notDataActions: []
      }
    ]
    roleName: roleName
    type: 'customRole'
  }
}
