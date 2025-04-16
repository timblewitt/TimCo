@allowed([
  '2019'
  '2022'
  '2025'
])
param windowsVersion string = '2025'

@minLength(3)
@maxLength(5)
param orgId string

@allowed([
  'uksouth'
  'ukwest'
  'westeurope'
  'northeurope'
])
param location string = 'uksouth'

@minValue(0)
param domainControllerCount int = 1

@minValue(0)
param webServerCount int = 2

@minValue(0)
param appServerCount int = 2

@allowed([
  'Standard_B2s'
  'Standard_D2s_v3'
  'Standard_D4s_v3'
  'Standard_DS2_v2'
  'Standard_DS3_v2'
  'Standard_E2s_v3'
])
param vmSize string = 'Standard_B2s'

var prefix = toLower(orgId)
var storageAccountName = toLower('sa${prefix}vmstore')
var vnetName = 'vnet-${prefix}'

var subnetConfig = [
  { name: 'snet-inf', prefix: '10.100.0.0/27', type: 'inf' }
  { name: 'snet-web', prefix: '10.100.0.32/27', type: 'web' }
  { name: 'snet-app', prefix: '10.100.0.64/27', type: 'app' }
  { name: 'snet-db',  prefix: '10.100.0.96/27', type: 'db'  }
]

resource sa 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {}
}

resource nsgs 'Microsoft.Network/networkSecurityGroups@2023-02-01' = [for s in subnetConfig: {
  name: 'nsg-${prefix}-${s.type}'
  location: location
  properties: {
    securityRules: concat([
      {
        name: 'Deny-All-Inbound'
        properties: {
          priority: 4096
          direction: 'Inbound'
          access: 'Deny'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
        }
      }
    ], s.type == 'inf' ? [
      {
        name: 'Allow-RDP'
        properties: {
          priority: 100
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '3389'
        }
      }
    ] : s.type == 'web' ? [
      {
        name: 'Allow-HTTP'
        properties: {
          priority: 100
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '80'
        }
      }
      {
        name: 'Allow-HTTPS'
        properties: {
          priority: 110
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '443'
        }
      }
    ] : [])
  }
}]

resource vnet 'Microsoft.Network/virtualNetworks@2023-02-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: ['10.100.0.0/24']
    }
    subnets: [
      for (s, index) in subnetConfig: {
        name: s.name
        properties: {
          addressPrefix: s.prefix
          networkSecurityGroup: {
            id: nsgs[index].id
          }
        }
      }
    ]
  }
}

var vmTypes = [
  { count: domainControllerCount, type: 'dc', subnetName: 'snet-inf' }
  { count: webServerCount, type: 'web', subnetName: 'snet-web' }
  { count: appServerCount, type: 'app', subnetName: 'snet-app' }
]

// Precompute the individual VM lists for each type
var dcVmList = [for i in range(0, domainControllerCount): {
  name: 'vm${prefix}dc${padLeft(string(i + 1), 2, '0')}'  // Corrected usage of '0' as a string
  type: 'dc'
  subnetName: 'snet-inf'
  index: i
}]

var webVmList = [for i in range(0, webServerCount): {
  name: 'vm${prefix}web${padLeft(string(i + 1), 2, '0')}'  // Corrected usage of '0' as a string
  type: 'web'
  subnetName: 'snet-web'
  index: i
}]

var appVmList = [for i in range(0, appServerCount): {
  name: 'vm${prefix}app${padLeft(string(i + 1), 2, '0')}'  // Corrected usage of '0' as a string
  type: 'app'
  subnetName: 'snet-app'
  index: i
}]

// Combine all VM lists into one flattened list
var flattenedVmList = concat(dcVmList, webVmList, appVmList)

module vms 'vm.bicep' = [for vm in flattenedVmList: {
  name: vm.name
  params: {
    name: vm.name
    location: location
    subnetId: vnet.properties.subnets[vm.index].id  // Directly use vm.index to access the correct subnet
    storageAccountName: storageAccountName
    windowsVersion: windowsVersion
    zone: string((vm.index % 3) + 1)
    vmSize: vmSize
  }
}]
