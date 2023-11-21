using './container-apps-env.bicep'

param containerAppEnv = {
  name: 'SSVADPINFCA3402'
  logAnalyticsWorkspaceResourceId: '/subscriptions/7dc5bbdf-72d7-42ca-ac23-eb5eea3764b4/resourceGroups/SSVADPINFRG3402/providers/Microsoft.OperationalInsights/workspaces/workspace-3402SIn9'
  SubnetId: '/subscriptions/7dc5bbdf-72d7-42ca-ac23-eb5eea3764b4/resourceGroups/SSVADPINFRG3402/providers/Microsoft.Network/virtualNetworks/SSVADPNETVN1401/subnets/SSVADPNETSU1401'
  skuName: 'Premium'
  workloadProfiles: [
    {
      workloadProfileType: 'D4'
      name: 'CAW3401'
      minimumCount: 0
      maximumCount: 3
    }
  ]
}

param environment = '#{{ environment }}'

param location = '#{{ location }}'
