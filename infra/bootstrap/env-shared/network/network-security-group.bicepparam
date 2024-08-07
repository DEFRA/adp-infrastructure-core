using './network-security-group.bicep'

param location = '#{{ location }}'

param environment = '#{{ environment }}'

param nsgList = [
  {
    name: '#{{ resourceNamePrefix }}#{{ subEnvironment1 }}#{{ nc_resource_nsg }}#{{ nc_instance_regionid }}01'
    purpose: 'ADP Container Apps NSG'
    securityRules: [
      
      {
        name: 'Allow_Internal_Traffic'
        properties: {
          description: 'Allow vnet traffic'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 100
          direction: 'Inbound'
        }
      }
      {
        name: 'Allow_OpenVPN'
        properties: {
          description: 'Allow inbound from OPS subnet where APS and OPS VPNs live'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: '10.204.0.0/26'
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 110
          direction: 'Inbound'
        }
      }
      {
        name: 'Allow_AGW_Subnet_Inbound'
        properties: {
          description: 'Allow inbound connectivity from the application gateway via HTTPS'
          protocol: 'Tcp'
          sourcePortRange: '*'
          sourceAddressPrefix: '127.0.0.1/32'
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 300
          direction: 'Inbound'
          destinationPortRanges: [
            '80'
            '443'
          ]
        }
      }
      {
        name: 'AllowGWM'
        properties: {
          description: 'Allow all inbound Gateway Management ports'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '65200-65535'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 400
          direction: 'Inbound'
        }
      }
      {
        name: 'AllowAnyInboundFromAzLB'
        properties: {
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: 'AzureLoadBalancer'
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 3600
          direction: 'Inbound'
          sourcePortRanges: []
          destinationPortRanges: []
          sourceAddressPrefixes: []
          destinationAddressPrefixes: []
          description: 'Allow Any Inbound From AzLB'
        }
      }
      {
        name: 'CCoE-SOC-Deny-IOC-Inbound'
        properties: {
          description: 'Deny-IOCs-Inbound-27-04-2023'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          destinationAddressPrefix: '*'
          access: 'Deny'
          priority: 3990
          direction: 'Inbound'
          sourceAddressPrefixes: [
            '31.220.3.140'
            '43.131.66.209'
            '45.43.62.24'
            '45.43.62.46'
            '45.132.227.237'
            '45.132.227.240'
            '45.132.227.242'
            '45.132.227.243'
            '45.132.227.244'
            '64.62.197.125'
            '64.62.197.126'
            '64.62.197.128'
            '64.62.197.129'
            '64.62.197.131'
            '64.62.197.137'
            '64.62.197.139'
            '64.62.197.140'
            '64.62.197.145'
            '64.62.197.148'
            '64.62.197.150'
            '64.227.97.195'
            '65.49.20.69'
            '66.240.192.82'
            '66.240.236.116'
            '80.78.22.106'
            '89.248.165.120'
            '94.102.61.10'
            '104.156.155.13'
            '107.150.105.239'
            '118.123.105.85'
            '128.14.134.170'
            '128.14.209.154'
            '128.14.232.148'
            '134.209.236.238'
            '136.144.42.206'
            '136.144.42.216'
            '146.88.240.4'
            '152.32.145.137'
            '152.32.150.226'
            '152.32.201.23'
            '152.32.228.20'
            '154.89.5.69'
            '161.35.230.183'
            '161.35.236.158'
            '161.35.238.241'
            '162.62.191.220'
            '162.62.191.231'
            '167.71.102.181'
            '167.94.138.44'
            '167.94.138.60'
            '167.94.145.58'
            '167.94.145.59'
            '167.94.145.60'
            '167.94.146.59'
            '170.106.115.253'
            '172.104.4.17'
            '183.136.225.9'
            '184.105.139.83'
            '184.105.139.99'
            '184.105.139.103'
            '184.105.139.115'
            '184.105.139.119'
            '185.81.68.180'
            '185.142.236.41'
            '185.165.190.34'
            '185.180.143.7'
            '185.180.143.81'
            '185.180.143.141'
            '185.191.171.13'
            '185.191.171.20'
            '185.251.19.161'
            '192.241.192.25'
            '192.241.192.251'
            '192.241.195.124'
            '192.241.195.156'
            '192.241.196.120'
            '192.241.197.31'
            '192.241.199.246'
            '192.241.201.46'
            '192.241.202.246'
            '192.241.204.36'
            '192.241.204.169'
            '192.241.204.193'
            '192.241.205.118'
            '192.241.206.177'
            '192.241.207.208'
            '192.241.208.41'
            '192.241.208.53'
            '192.241.208.58'
            '192.241.208.69'
            '192.241.208.75'
            '192.241.208.82'
            '192.241.208.127'
            '192.241.208.203'
            '192.241.208.238'
            '192.241.209.34'
            '192.241.209.145'
            '192.241.212.15'
            '192.241.212.122'
            '192.241.212.192'
            '192.241.212.193'
            '192.241.212.203'
            '192.241.212.218'
            '193.37.255.114'
            '198.199.95.19'
            '198.199.96.229'
            '198.199.103.139'
            '198.199.117.15'
            '198.235.24.2'
            '198.235.24.3'
            '198.235.24.5'
            '198.235.24.6'
            '198.235.24.8'
            '198.235.24.9'
            '198.235.24.10'
            '198.235.24.12'
            '198.235.24.13'
            '198.235.24.14'
            '198.235.24.15'
            '198.235.24.17'
            '198.235.24.18'
            '198.235.24.19'
            '198.235.24.21'
            '198.235.24.22'
            '198.235.24.23'
            '198.235.24.24'
            '198.235.24.25'
            '198.235.24.26'
            '198.235.24.27'
            '198.235.24.29'
            '198.235.24.30'
            '198.235.24.32'
            '198.235.24.33'
            '198.235.24.34'
            '198.235.24.128'
            '198.235.24.129'
            '198.235.24.130'
            '198.235.24.131'
            '198.235.24.132'
            '198.235.24.133'
            '198.235.24.134'
            '198.235.24.135'
            '198.235.24.136'
            '198.235.24.137'
            '198.235.24.138'
            '198.235.24.139'
            '198.235.24.140'
            '198.235.24.141'
            '198.235.24.143'
            '198.235.24.144'
            '198.235.24.145'
            '198.235.24.146'
            '198.235.24.147'
            '198.235.24.148'
            '198.235.24.149'
            '198.235.24.150'
            '198.235.24.151'
            '198.235.24.152'
            '198.235.24.153'
            '198.235.24.154'
            '198.235.24.155'
            '198.235.24.158'
            '198.235.24.159'
            '198.235.24.161'
            '205.185.121.155'
            '205.210.31.2'
            '205.210.31.3'
            '205.210.31.5'
            '205.210.31.6'
            '205.210.31.8'
            '205.210.31.9'
            '205.210.31.10'
            '205.210.31.11'
            '205.210.31.12'
            '205.210.31.13'
            '205.210.31.14'
            '205.210.31.15'
            '205.210.31.16'
            '205.210.31.17'
            '205.210.31.18'
            '205.210.31.19'
            '205.210.31.20'
            '205.210.31.21'
            '205.210.31.22'
            '205.210.31.23'
            '205.210.31.24'
            '205.210.31.25'
            '205.210.31.26'
            '205.210.31.27'
            '205.210.31.28'
            '205.210.31.29'
            '205.210.31.30'
            '205.210.31.31'
            '205.210.31.33'
            '205.210.31.34'
            '205.210.31.35'
            '205.210.31.128'
            '205.210.31.129'
            '205.210.31.130'
            '205.210.31.131'
            '205.210.31.132'
            '205.210.31.133'
            '205.210.31.134'
            '205.210.31.135'
            '205.210.31.136'
            '205.210.31.137'
            '205.210.31.138'
            '205.210.31.139'
            '205.210.31.140'
            '205.210.31.141'
            '205.210.31.142'
            '205.210.31.143'
            '205.210.31.144'
            '205.210.31.148'
            '205.210.31.149'
            '205.210.31.151'
            '205.210.31.152'
            '205.210.31.154'
            '205.210.31.155'
            '205.210.31.156'
            '205.210.31.158'
            '205.210.31.159'
            '205.210.31.161'
            '213.32.122.82'
            '223.177.200.142'
            '223.229.132.51'
            '223.229.135.250'
          ]
        }
      }
      {
        name: 'DenyAnyOtherInbound'
        properties: {
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Deny'
          priority: 4000
          direction: 'Inbound'
          sourcePortRanges: []
          destinationPortRanges: []
          sourceAddressPrefixes: []
          destinationAddressPrefixes: []
          description: 'Deny All Other Inbound'
        }
      }
      {
        name: 'Allow_NTP_Outbound_To_Azure'
        properties: {
          description: 'Allow outbound NTP to AzureCloud'
          protocol: 'Udp'
          sourcePortRange: '*'
          destinationPortRange: '123'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: 'AzureCloud'
          access: 'Allow'
          priority: 100
          direction: 'Outbound'
        }
      }
      {
        name: 'Allow_HTTPs_Outbound_To_Any'
        properties: {
          description: 'Allow outbound HTTPS to Any'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 110
          direction: 'Outbound'
        }
      }
      {
        name: 'AllowVNetAnyOutbound'
        properties: {
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 200
          direction: 'Outbound'
          sourcePortRanges: []
          destinationPortRanges: []
          sourceAddressPrefixes: []
          destinationAddressPrefixes: []
          description: 'Allow Any Outbound from VNet to VNet.'
        }
      }
      {
        name: 'AllowAADAuthOutbound'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: 'AzureActiveDirectory'
          access: 'Allow'
          priority: 220
          direction: 'Outbound'
          sourcePortRanges: []
          destinationPortRanges: []
          sourceAddressPrefixes: []
          destinationAddressPrefixes: []
          description: 'Allow AAD Auth Outbound port(443) from VirtualNetwork to AzureActiveDirectory'
        }
      }
      {
        name: 'AllowDevOpsSSHOutbound'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '22'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: 'AzureDevOps'
          access: 'Allow'
          priority: 230
          direction: 'Outbound'
          sourcePortRanges: []
          destinationPortRanges: []
          sourceAddressPrefixes: []
          destinationAddressPrefixes: []
          description: 'Allow SSH Outbound port(22) from VirtualNetwork to AzureDevOps'
        }
      }
      {
        name: 'AllowAzMonitorOutbound'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: 'AzureMonitor'
          access: 'Allow'
          priority: 240
          direction: 'Outbound'
          sourcePortRanges: []
          destinationPortRanges: [
            '443'
            '1886'
          ]
          sourceAddressPrefixes: []
          destinationAddressPrefixes: []
          description: 'Allow AzMonitor Outbound ports(443,1886) from VirtualNetwork to AzureMonitor'
        }
      }
      {
        name: 'AllowAzAcrUksOutbound'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: 'AzureContainerRegistry.UKSouth'
          access: 'Allow'
          priority: 260
          direction: 'Outbound'
          sourcePortRanges: []
          destinationPortRanges: []
          sourceAddressPrefixes: []
          destinationAddressPrefixes: []
          description: 'Allow AzAcr Outbound port(443) from VirtualNetwork to AzureContainerRegistry.UKSouth'
        }
      }
      {
        name: 'AllowAzAcrUkwOutbound'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: 'AzureContainerRegistry.UKWest'
          access: 'Allow'
          priority: 265
          direction: 'Outbound'
          sourcePortRanges: []
          destinationPortRanges: []
          sourceAddressPrefixes: []
          destinationAddressPrefixes: []
          description: 'Allow AzAcr Outbound port(443) from VirtualNetwork to AzureContainerRegistry.UKWest'
        }
      }
      {
        name: 'AllowAzKvltUksOutbound'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: 'AzureKeyVault.UKSouth'
          access: 'Allow'
          priority: 280
          direction: 'Outbound'
          sourcePortRanges: []
          destinationPortRanges: []
          sourceAddressPrefixes: []
          destinationAddressPrefixes: []
          description: 'Allow Az Key vault Outbound port(443) from VirtualNetwork to AzureKeyVault.UKSouth'
        }
      }
      {
        name: 'AllowAzKvltUkwOutbound'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: 'AzureKeyVault.UKWest'
          access: 'Allow'
          priority: 285
          direction: 'Outbound'
          sourcePortRanges: []
          destinationPortRanges: []
          sourceAddressPrefixes: []
          destinationAddressPrefixes: []
          description: 'Allow Az Key vault Outbound port(443) from VirtualNetwork to AzureKeyVault.UKWest'
        }
      }
      {
        name: 'DenyAllOtherOutbound'
        properties: {
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Deny'
          priority: 4000
          direction: 'Outbound'
          sourcePortRanges: []
          destinationPortRanges: []
          sourceAddressPrefixes: []
          destinationAddressPrefixes: []
          description: 'Deny All Other Outbound'
        }
      }
    ]
  }
  {
    name: '#{{ resourceNamePrefix }}#{{ subEnvironment2 }}#{{ nc_resource_nsg }}#{{ nc_instance_regionid }}01'
    purpose: 'ADP Container Apps NSG'
    securityRules: [
      
      {
        name: 'Allow_Internal_Traffic'
        properties: {
          description: 'Allow vnet traffic'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 100
          direction: 'Inbound'
        }
      }
      {
        name: 'Allow_OpenVPN'
        properties: {
          description: 'Allow inbound from OPS subnet where APS and OPS VPNs live'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: '10.204.0.0/26'
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 110
          direction: 'Inbound'
        }
      }
      {
        name: 'Allow_AGW_Subnet_Inbound'
        properties: {
          description: 'Allow inbound connectivity from the application gateway via HTTPS'
          protocol: 'Tcp'
          sourcePortRange: '*'
          sourceAddressPrefix: '127.0.0.1/32'
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 300
          direction: 'Inbound'
          destinationPortRanges: [
            '80'
            '443'
          ]
        }
      }
      {
        name: 'AllowGWM'
        properties: {
          description: 'Allow all inbound Gateway Management ports'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '65200-65535'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 400
          direction: 'Inbound'
        }
      }
      {
        name: 'AllowAnyInboundFromAzLB'
        properties: {
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: 'AzureLoadBalancer'
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 3600
          direction: 'Inbound'
          sourcePortRanges: []
          destinationPortRanges: []
          sourceAddressPrefixes: []
          destinationAddressPrefixes: []
          description: 'Allow Any Inbound From AzLB'
        }
      }
      {
        name: 'CCoE-SOC-Deny-IOC-Inbound'
        properties: {
          description: 'Deny-IOCs-Inbound-27-04-2023'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          destinationAddressPrefix: '*'
          access: 'Deny'
          priority: 3990
          direction: 'Inbound'
          sourceAddressPrefixes: [
            '31.220.3.140'
            '43.131.66.209'
            '45.43.62.24'
            '45.43.62.46'
            '45.132.227.237'
            '45.132.227.240'
            '45.132.227.242'
            '45.132.227.243'
            '45.132.227.244'
            '64.62.197.125'
            '64.62.197.126'
            '64.62.197.128'
            '64.62.197.129'
            '64.62.197.131'
            '64.62.197.137'
            '64.62.197.139'
            '64.62.197.140'
            '64.62.197.145'
            '64.62.197.148'
            '64.62.197.150'
            '64.227.97.195'
            '65.49.20.69'
            '66.240.192.82'
            '66.240.236.116'
            '80.78.22.106'
            '89.248.165.120'
            '94.102.61.10'
            '104.156.155.13'
            '107.150.105.239'
            '118.123.105.85'
            '128.14.134.170'
            '128.14.209.154'
            '128.14.232.148'
            '134.209.236.238'
            '136.144.42.206'
            '136.144.42.216'
            '146.88.240.4'
            '152.32.145.137'
            '152.32.150.226'
            '152.32.201.23'
            '152.32.228.20'
            '154.89.5.69'
            '161.35.230.183'
            '161.35.236.158'
            '161.35.238.241'
            '162.62.191.220'
            '162.62.191.231'
            '167.71.102.181'
            '167.94.138.44'
            '167.94.138.60'
            '167.94.145.58'
            '167.94.145.59'
            '167.94.145.60'
            '167.94.146.59'
            '170.106.115.253'
            '172.104.4.17'
            '183.136.225.9'
            '184.105.139.83'
            '184.105.139.99'
            '184.105.139.103'
            '184.105.139.115'
            '184.105.139.119'
            '185.81.68.180'
            '185.142.236.41'
            '185.165.190.34'
            '185.180.143.7'
            '185.180.143.81'
            '185.180.143.141'
            '185.191.171.13'
            '185.191.171.20'
            '185.251.19.161'
            '192.241.192.25'
            '192.241.192.251'
            '192.241.195.124'
            '192.241.195.156'
            '192.241.196.120'
            '192.241.197.31'
            '192.241.199.246'
            '192.241.201.46'
            '192.241.202.246'
            '192.241.204.36'
            '192.241.204.169'
            '192.241.204.193'
            '192.241.205.118'
            '192.241.206.177'
            '192.241.207.208'
            '192.241.208.41'
            '192.241.208.53'
            '192.241.208.58'
            '192.241.208.69'
            '192.241.208.75'
            '192.241.208.82'
            '192.241.208.127'
            '192.241.208.203'
            '192.241.208.238'
            '192.241.209.34'
            '192.241.209.145'
            '192.241.212.15'
            '192.241.212.122'
            '192.241.212.192'
            '192.241.212.193'
            '192.241.212.203'
            '192.241.212.218'
            '193.37.255.114'
            '198.199.95.19'
            '198.199.96.229'
            '198.199.103.139'
            '198.199.117.15'
            '198.235.24.2'
            '198.235.24.3'
            '198.235.24.5'
            '198.235.24.6'
            '198.235.24.8'
            '198.235.24.9'
            '198.235.24.10'
            '198.235.24.12'
            '198.235.24.13'
            '198.235.24.14'
            '198.235.24.15'
            '198.235.24.17'
            '198.235.24.18'
            '198.235.24.19'
            '198.235.24.21'
            '198.235.24.22'
            '198.235.24.23'
            '198.235.24.24'
            '198.235.24.25'
            '198.235.24.26'
            '198.235.24.27'
            '198.235.24.29'
            '198.235.24.30'
            '198.235.24.32'
            '198.235.24.33'
            '198.235.24.34'
            '198.235.24.128'
            '198.235.24.129'
            '198.235.24.130'
            '198.235.24.131'
            '198.235.24.132'
            '198.235.24.133'
            '198.235.24.134'
            '198.235.24.135'
            '198.235.24.136'
            '198.235.24.137'
            '198.235.24.138'
            '198.235.24.139'
            '198.235.24.140'
            '198.235.24.141'
            '198.235.24.143'
            '198.235.24.144'
            '198.235.24.145'
            '198.235.24.146'
            '198.235.24.147'
            '198.235.24.148'
            '198.235.24.149'
            '198.235.24.150'
            '198.235.24.151'
            '198.235.24.152'
            '198.235.24.153'
            '198.235.24.154'
            '198.235.24.155'
            '198.235.24.158'
            '198.235.24.159'
            '198.235.24.161'
            '205.185.121.155'
            '205.210.31.2'
            '205.210.31.3'
            '205.210.31.5'
            '205.210.31.6'
            '205.210.31.8'
            '205.210.31.9'
            '205.210.31.10'
            '205.210.31.11'
            '205.210.31.12'
            '205.210.31.13'
            '205.210.31.14'
            '205.210.31.15'
            '205.210.31.16'
            '205.210.31.17'
            '205.210.31.18'
            '205.210.31.19'
            '205.210.31.20'
            '205.210.31.21'
            '205.210.31.22'
            '205.210.31.23'
            '205.210.31.24'
            '205.210.31.25'
            '205.210.31.26'
            '205.210.31.27'
            '205.210.31.28'
            '205.210.31.29'
            '205.210.31.30'
            '205.210.31.31'
            '205.210.31.33'
            '205.210.31.34'
            '205.210.31.35'
            '205.210.31.128'
            '205.210.31.129'
            '205.210.31.130'
            '205.210.31.131'
            '205.210.31.132'
            '205.210.31.133'
            '205.210.31.134'
            '205.210.31.135'
            '205.210.31.136'
            '205.210.31.137'
            '205.210.31.138'
            '205.210.31.139'
            '205.210.31.140'
            '205.210.31.141'
            '205.210.31.142'
            '205.210.31.143'
            '205.210.31.144'
            '205.210.31.148'
            '205.210.31.149'
            '205.210.31.151'
            '205.210.31.152'
            '205.210.31.154'
            '205.210.31.155'
            '205.210.31.156'
            '205.210.31.158'
            '205.210.31.159'
            '205.210.31.161'
            '213.32.122.82'
            '223.177.200.142'
            '223.229.132.51'
            '223.229.135.250'
          ]
        }
      }
      {
        name: 'DenyAnyOtherInbound'
        properties: {
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Deny'
          priority: 4000
          direction: 'Inbound'
          sourcePortRanges: []
          destinationPortRanges: []
          sourceAddressPrefixes: []
          destinationAddressPrefixes: []
          description: 'Deny All Other Inbound'
        }
      }
      {
        name: 'Allow_NTP_Outbound_To_Azure'
        properties: {
          description: 'Allow outbound NTP to AzureCloud'
          protocol: 'Udp'
          sourcePortRange: '*'
          destinationPortRange: '123'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: 'AzureCloud'
          access: 'Allow'
          priority: 100
          direction: 'Outbound'
        }
      }
      {
        name: 'Allow_HTTPs_Outbound_To_Any'
        properties: {
          description: 'Allow outbound HTTPS to Any'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 110
          direction: 'Outbound'
        }
      }
      {
        name: 'AllowVNetAnyOutbound'
        properties: {
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 200
          direction: 'Outbound'
          sourcePortRanges: []
          destinationPortRanges: []
          sourceAddressPrefixes: []
          destinationAddressPrefixes: []
          description: 'Allow Any Outbound from VNet to VNet.'
        }
      }
      {
        name: 'AllowAADAuthOutbound'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: 'AzureActiveDirectory'
          access: 'Allow'
          priority: 220
          direction: 'Outbound'
          sourcePortRanges: []
          destinationPortRanges: []
          sourceAddressPrefixes: []
          destinationAddressPrefixes: []
          description: 'Allow AAD Auth Outbound port(443) from VirtualNetwork to AzureActiveDirectory'
        }
      }
      {
        name: 'AllowDevOpsSSHOutbound'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '22'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: 'AzureDevOps'
          access: 'Allow'
          priority: 230
          direction: 'Outbound'
          sourcePortRanges: []
          destinationPortRanges: []
          sourceAddressPrefixes: []
          destinationAddressPrefixes: []
          description: 'Allow SSH Outbound port(22) from VirtualNetwork to AzureDevOps'
        }
      }
      {
        name: 'AllowAzMonitorOutbound'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: 'AzureMonitor'
          access: 'Allow'
          priority: 240
          direction: 'Outbound'
          sourcePortRanges: []
          destinationPortRanges: [
            '443'
            '1886'
          ]
          sourceAddressPrefixes: []
          destinationAddressPrefixes: []
          description: 'Allow AzMonitor Outbound ports(443,1886) from VirtualNetwork to AzureMonitor'
        }
      }
      {
        name: 'AllowAzAcrUksOutbound'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: 'AzureContainerRegistry.UKSouth'
          access: 'Allow'
          priority: 260
          direction: 'Outbound'
          sourcePortRanges: []
          destinationPortRanges: []
          sourceAddressPrefixes: []
          destinationAddressPrefixes: []
          description: 'Allow AzAcr Outbound port(443) from VirtualNetwork to AzureContainerRegistry.UKSouth'
        }
      }
      {
        name: 'AllowAzAcrUkwOutbound'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: 'AzureContainerRegistry.UKWest'
          access: 'Allow'
          priority: 265
          direction: 'Outbound'
          sourcePortRanges: []
          destinationPortRanges: []
          sourceAddressPrefixes: []
          destinationAddressPrefixes: []
          description: 'Allow AzAcr Outbound port(443) from VirtualNetwork to AzureContainerRegistry.UKWest'
        }
      }
      {
        name: 'AllowAzKvltUksOutbound'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: 'AzureKeyVault.UKSouth'
          access: 'Allow'
          priority: 280
          direction: 'Outbound'
          sourcePortRanges: []
          destinationPortRanges: []
          sourceAddressPrefixes: []
          destinationAddressPrefixes: []
          description: 'Allow Az Key vault Outbound port(443) from VirtualNetwork to AzureKeyVault.UKSouth'
        }
      }
      {
        name: 'AllowAzKvltUkwOutbound'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: 'AzureKeyVault.UKWest'
          access: 'Allow'
          priority: 285
          direction: 'Outbound'
          sourcePortRanges: []
          destinationPortRanges: []
          sourceAddressPrefixes: []
          destinationAddressPrefixes: []
          description: 'Allow Az Key vault Outbound port(443) from VirtualNetwork to AzureKeyVault.UKWest'
        }
      }
      {
        name: 'DenyAllOtherOutbound'
        properties: {
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Deny'
          priority: 4000
          direction: 'Outbound'
          sourcePortRanges: []
          destinationPortRanges: []
          sourceAddressPrefixes: []
          destinationAddressPrefixes: []
          description: 'Deny All Other Outbound'
        }
      }
    ]
  }
  {
    name: '#{{ networkResourceNamePrefix }}#{{ nc_resource_nsg }}#{{ nc_instance_regionid }}01'
    purpose: 'ADP Container Apps NSG'
    securityRules: [
      
      {
        name: 'Allow_Internal_Traffic'
        properties: {
          description: 'Allow vnet traffic'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 100
          direction: 'Inbound'
        }
      }
      {
        name: 'Allow_OpenVPN'
        properties: {
          description: 'Allow inbound from OPS subnet where APS and OPS VPNs live'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: '10.204.0.0/26'
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 110
          direction: 'Inbound'
        }
      }
      {
        name: 'Allow_AGW_Subnet_Inbound'
        properties: {
          description: 'Allow inbound connectivity from the application gateway via HTTPS'
          protocol: 'Tcp'
          sourcePortRange: '*'
          sourceAddressPrefix: '127.0.0.1/32'
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 300
          direction: 'Inbound'
          destinationPortRanges: [
            '80'
            '443'
          ]
        }
      }
      {
        name: 'AllowGWM'
        properties: {
          description: 'Allow all inbound Gateway Management ports'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '65200-65535'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 400
          direction: 'Inbound'
        }
      }
      {
        name: 'AllowAnyInboundFromAzLB'
        properties: {
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: 'AzureLoadBalancer'
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 3600
          direction: 'Inbound'
          sourcePortRanges: []
          destinationPortRanges: []
          sourceAddressPrefixes: []
          destinationAddressPrefixes: []
          description: 'Allow Any Inbound From AzLB'
        }
      }
      {
        name: 'CCoE-SOC-Deny-IOC-Inbound'
        properties: {
          description: 'Deny-IOCs-Inbound-27-04-2023'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          destinationAddressPrefix: '*'
          access: 'Deny'
          priority: 3990
          direction: 'Inbound'
          sourceAddressPrefixes: [
            '31.220.3.140'
            '43.131.66.209'
            '45.43.62.24'
            '45.43.62.46'
            '45.132.227.237'
            '45.132.227.240'
            '45.132.227.242'
            '45.132.227.243'
            '45.132.227.244'
            '64.62.197.125'
            '64.62.197.126'
            '64.62.197.128'
            '64.62.197.129'
            '64.62.197.131'
            '64.62.197.137'
            '64.62.197.139'
            '64.62.197.140'
            '64.62.197.145'
            '64.62.197.148'
            '64.62.197.150'
            '64.227.97.195'
            '65.49.20.69'
            '66.240.192.82'
            '66.240.236.116'
            '80.78.22.106'
            '89.248.165.120'
            '94.102.61.10'
            '104.156.155.13'
            '107.150.105.239'
            '118.123.105.85'
            '128.14.134.170'
            '128.14.209.154'
            '128.14.232.148'
            '134.209.236.238'
            '136.144.42.206'
            '136.144.42.216'
            '146.88.240.4'
            '152.32.145.137'
            '152.32.150.226'
            '152.32.201.23'
            '152.32.228.20'
            '154.89.5.69'
            '161.35.230.183'
            '161.35.236.158'
            '161.35.238.241'
            '162.62.191.220'
            '162.62.191.231'
            '167.71.102.181'
            '167.94.138.44'
            '167.94.138.60'
            '167.94.145.58'
            '167.94.145.59'
            '167.94.145.60'
            '167.94.146.59'
            '170.106.115.253'
            '172.104.4.17'
            '183.136.225.9'
            '184.105.139.83'
            '184.105.139.99'
            '184.105.139.103'
            '184.105.139.115'
            '184.105.139.119'
            '185.81.68.180'
            '185.142.236.41'
            '185.165.190.34'
            '185.180.143.7'
            '185.180.143.81'
            '185.180.143.141'
            '185.191.171.13'
            '185.191.171.20'
            '185.251.19.161'
            '192.241.192.25'
            '192.241.192.251'
            '192.241.195.124'
            '192.241.195.156'
            '192.241.196.120'
            '192.241.197.31'
            '192.241.199.246'
            '192.241.201.46'
            '192.241.202.246'
            '192.241.204.36'
            '192.241.204.169'
            '192.241.204.193'
            '192.241.205.118'
            '192.241.206.177'
            '192.241.207.208'
            '192.241.208.41'
            '192.241.208.53'
            '192.241.208.58'
            '192.241.208.69'
            '192.241.208.75'
            '192.241.208.82'
            '192.241.208.127'
            '192.241.208.203'
            '192.241.208.238'
            '192.241.209.34'
            '192.241.209.145'
            '192.241.212.15'
            '192.241.212.122'
            '192.241.212.192'
            '192.241.212.193'
            '192.241.212.203'
            '192.241.212.218'
            '193.37.255.114'
            '198.199.95.19'
            '198.199.96.229'
            '198.199.103.139'
            '198.199.117.15'
            '198.235.24.2'
            '198.235.24.3'
            '198.235.24.5'
            '198.235.24.6'
            '198.235.24.8'
            '198.235.24.9'
            '198.235.24.10'
            '198.235.24.12'
            '198.235.24.13'
            '198.235.24.14'
            '198.235.24.15'
            '198.235.24.17'
            '198.235.24.18'
            '198.235.24.19'
            '198.235.24.21'
            '198.235.24.22'
            '198.235.24.23'
            '198.235.24.24'
            '198.235.24.25'
            '198.235.24.26'
            '198.235.24.27'
            '198.235.24.29'
            '198.235.24.30'
            '198.235.24.32'
            '198.235.24.33'
            '198.235.24.34'
            '198.235.24.128'
            '198.235.24.129'
            '198.235.24.130'
            '198.235.24.131'
            '198.235.24.132'
            '198.235.24.133'
            '198.235.24.134'
            '198.235.24.135'
            '198.235.24.136'
            '198.235.24.137'
            '198.235.24.138'
            '198.235.24.139'
            '198.235.24.140'
            '198.235.24.141'
            '198.235.24.143'
            '198.235.24.144'
            '198.235.24.145'
            '198.235.24.146'
            '198.235.24.147'
            '198.235.24.148'
            '198.235.24.149'
            '198.235.24.150'
            '198.235.24.151'
            '198.235.24.152'
            '198.235.24.153'
            '198.235.24.154'
            '198.235.24.155'
            '198.235.24.158'
            '198.235.24.159'
            '198.235.24.161'
            '205.185.121.155'
            '205.210.31.2'
            '205.210.31.3'
            '205.210.31.5'
            '205.210.31.6'
            '205.210.31.8'
            '205.210.31.9'
            '205.210.31.10'
            '205.210.31.11'
            '205.210.31.12'
            '205.210.31.13'
            '205.210.31.14'
            '205.210.31.15'
            '205.210.31.16'
            '205.210.31.17'
            '205.210.31.18'
            '205.210.31.19'
            '205.210.31.20'
            '205.210.31.21'
            '205.210.31.22'
            '205.210.31.23'
            '205.210.31.24'
            '205.210.31.25'
            '205.210.31.26'
            '205.210.31.27'
            '205.210.31.28'
            '205.210.31.29'
            '205.210.31.30'
            '205.210.31.31'
            '205.210.31.33'
            '205.210.31.34'
            '205.210.31.35'
            '205.210.31.128'
            '205.210.31.129'
            '205.210.31.130'
            '205.210.31.131'
            '205.210.31.132'
            '205.210.31.133'
            '205.210.31.134'
            '205.210.31.135'
            '205.210.31.136'
            '205.210.31.137'
            '205.210.31.138'
            '205.210.31.139'
            '205.210.31.140'
            '205.210.31.141'
            '205.210.31.142'
            '205.210.31.143'
            '205.210.31.144'
            '205.210.31.148'
            '205.210.31.149'
            '205.210.31.151'
            '205.210.31.152'
            '205.210.31.154'
            '205.210.31.155'
            '205.210.31.156'
            '205.210.31.158'
            '205.210.31.159'
            '205.210.31.161'
            '213.32.122.82'
            '223.177.200.142'
            '223.229.132.51'
            '223.229.135.250'
          ]
        }
      }
      {
        name: 'DenyAnyOtherInbound'
        properties: {
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Deny'
          priority: 4000
          direction: 'Inbound'
          sourcePortRanges: []
          destinationPortRanges: []
          sourceAddressPrefixes: []
          destinationAddressPrefixes: []
          description: 'Deny All Other Inbound'
        }
      }
      {
        name: 'Allow_NTP_Outbound_To_Azure'
        properties: {
          description: 'Allow outbound NTP to AzureCloud'
          protocol: 'Udp'
          sourcePortRange: '*'
          destinationPortRange: '123'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: 'AzureCloud'
          access: 'Allow'
          priority: 100
          direction: 'Outbound'
        }
      }
      {
        name: 'Allow_HTTPs_Outbound_To_Any'
        properties: {
          description: 'Allow outbound HTTPS to Any'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 110
          direction: 'Outbound'
        }
      }
      {
        name: 'AllowVNetAnyOutbound'
        properties: {
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 200
          direction: 'Outbound'
          sourcePortRanges: []
          destinationPortRanges: []
          sourceAddressPrefixes: []
          destinationAddressPrefixes: []
          description: 'Allow Any Outbound from VNet to VNet.'
        }
      }
      {
        name: 'AllowAADAuthOutbound'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: 'AzureActiveDirectory'
          access: 'Allow'
          priority: 220
          direction: 'Outbound'
          sourcePortRanges: []
          destinationPortRanges: []
          sourceAddressPrefixes: []
          destinationAddressPrefixes: []
          description: 'Allow AAD Auth Outbound port(443) from VirtualNetwork to AzureActiveDirectory'
        }
      }
      {
        name: 'AllowDevOpsSSHOutbound'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '22'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: 'AzureDevOps'
          access: 'Allow'
          priority: 230
          direction: 'Outbound'
          sourcePortRanges: []
          destinationPortRanges: []
          sourceAddressPrefixes: []
          destinationAddressPrefixes: []
          description: 'Allow SSH Outbound port(22) from VirtualNetwork to AzureDevOps'
        }
      }
      {
        name: 'AllowAzMonitorOutbound'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: 'AzureMonitor'
          access: 'Allow'
          priority: 240
          direction: 'Outbound'
          sourcePortRanges: []
          destinationPortRanges: [
            '443'
            '1886'
          ]
          sourceAddressPrefixes: []
          destinationAddressPrefixes: []
          description: 'Allow AzMonitor Outbound ports(443,1886) from VirtualNetwork to AzureMonitor'
        }
      }
      {
        name: 'AllowAzAcrUksOutbound'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: 'AzureContainerRegistry.UKSouth'
          access: 'Allow'
          priority: 260
          direction: 'Outbound'
          sourcePortRanges: []
          destinationPortRanges: []
          sourceAddressPrefixes: []
          destinationAddressPrefixes: []
          description: 'Allow AzAcr Outbound port(443) from VirtualNetwork to AzureContainerRegistry.UKSouth'
        }
      }
      {
        name: 'AllowAzAcrUkwOutbound'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: 'AzureContainerRegistry.UKWest'
          access: 'Allow'
          priority: 265
          direction: 'Outbound'
          sourcePortRanges: []
          destinationPortRanges: []
          sourceAddressPrefixes: []
          destinationAddressPrefixes: []
          description: 'Allow AzAcr Outbound port(443) from VirtualNetwork to AzureContainerRegistry.UKWest'
        }
      }
      {
        name: 'AllowAzKvltUksOutbound'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: 'AzureKeyVault.UKSouth'
          access: 'Allow'
          priority: 280
          direction: 'Outbound'
          sourcePortRanges: []
          destinationPortRanges: []
          sourceAddressPrefixes: []
          destinationAddressPrefixes: []
          description: 'Allow Az Key vault Outbound port(443) from VirtualNetwork to AzureKeyVault.UKSouth'
        }
      }
      {
        name: 'AllowAzKvltUkwOutbound'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: 'AzureKeyVault.UKWest'
          access: 'Allow'
          priority: 285
          direction: 'Outbound'
          sourcePortRanges: []
          destinationPortRanges: []
          sourceAddressPrefixes: []
          destinationAddressPrefixes: []
          description: 'Allow Az Key vault Outbound port(443) from VirtualNetwork to AzureKeyVault.UKWest'
        }
      }
      {
        name: 'DenyAllOtherOutbound'
        properties: {
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Deny'
          priority: 4000
          direction: 'Outbound'
          sourcePortRanges: []
          destinationPortRanges: []
          sourceAddressPrefixes: []
          destinationAddressPrefixes: []
          description: 'Deny All Other Outbound'
        }
      }
    ]
  }
]

param resourceLockEnabled = #{{ resourceLockEnabled }}
