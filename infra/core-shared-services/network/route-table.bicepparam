using './route-table.bicep'

param routeTable = {
  name: 'UDR-Spoke-Route-From-#{{ ssvVirtualNetworkName }}'
  virtualApplicanceIp: '#{{ virtualApplianceIp }}'
}

param location = '#{{ location }}'

param environment = '#{{ environment }}'
