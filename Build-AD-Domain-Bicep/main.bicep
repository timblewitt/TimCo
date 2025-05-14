// NSG rules
// Load balancer
// Bastion
// VM Size list
// VM generation/TPM
//

@minLength(3)
@maxLength(5)
param orgIdentifier string

@allowed([
  '2022-Datacenter-Azure-Edition'
  '2025-Datacenter-Azure-Edition'
])
param windowsVersion string = '2025-Datacenter-Azure-Edition'

@allowed([
  'uksouth'
  'ukwest'
  'westeurope'
  'northeurope'
])
param location string = 'uksouth'  

param adminUsername string = 'azureadmin'

@minLength(12)
@secure()
param adminPassword string

@minValue(0)
@maxValue(2)
param domainControllerCount int = 1

@minValue(0)
@maxValue(2)
param webServerCount int = 1

@minValue(0)
@maxValue(2)
param applicationServerCount int = 1

@minValue(0)
@maxValue(2)
param databaseServerCount int = 1

@allowed([
  'Standard_B2s'
  'Standard_D2s_v3'
  'Standard_D4s_v3'
  'Standard_DS2_v2'
  'Standard_DS3_v2'
  'Standard_E2s_v3'
])
param vmSize string = 'Standard_B2s'

param usePublicIP bool = false 

var orgId = toLower(orgIdentifier)
var randomString = uniqueString(orgId) 
var storageAccountName = toLower('sa${orgId}${randomString}diag') 
var vnetName = 'vnet-${orgId}-01'
var vnetAddress1 = '10.100.0.0/24'
var subnetConfig = [
  { name: 'snet-adc', orgId: '10.100.0.0/27', type: 'adc' }
  { name: 'snet-web', orgId: '10.100.0.32/27', type: 'web' }
  { name: 'snet-app', orgId: '10.100.0.64/27', type: 'app' }
  { name: 'snet-dbs',  orgId: '10.100.0.96/27', type: 'dbs'  }
]

resource sa 'Microsoft.Storage/storageAccounts@2024-01-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {}
}

resource nsgs 'Microsoft.Network/networkSecurityGroups@2024-05-01' = [for s in subnetConfig: {
  name: 'nsg-${orgId}-${s.type}'
  location: location
  properties: {
    securityRules: concat([{
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
    }], s.type == 'adc' ? [{
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
    }] : s.type == 'web' ? [{
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
    }] : [])
  }
}]

resource vnet 'Microsoft.Network/virtualNetworks@2024-05-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [vnetAddress1]
    }
    subnets: [
      for (s, index) in subnetConfig: {
        name: s.name
        properties: {
          addressPrefix: s.orgId
          networkSecurityGroup: {
            id: nsgs[index].id
          }
        }
      }
    ]
  }
}

// AD Domain Controllers
var adcVmList = [for i in range(0, domainControllerCount): {
  name: 'vm${orgId}adc${padLeft(string(i + 1), 2, '0')}'  
  type: 'adc'
  subnetName: 'snet-adc'
  index: i
}]

resource adcPips 'Microsoft.Network/publicIPAddresses@2024-05-01' = [for (vm, i) in adcVmList: if (usePublicIP) {
  name: 'pip-${vm.name}'
  location: location
  zones: [string((i % 3) + 1)]
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    dnsSettings: {
      domainNameLabel: 'pip-${vm.name}'
    }
  }
}]

module adcVms 'vm.bicep' = [for (vm, i) in adcVmList: {
  name: vm.name
  params: {
    name: vm.name
    location: location
    subnetId: vnet.properties.subnets[0].id
    storageAccountName: storageAccountName
    windowsVersion: windowsVersion
    zone: string((i % 3) + 1)
    vmSize: vmSize
    publicIpAddressId: usePublicIP ? adcPips[i].id : null
    adminUserName: adminUsername
    adminPassword: adminPassword
  }
}]

// Web Servers
var webVmList = [for i in range(0, webServerCount): {
  name: 'vm${orgId}web${padLeft(string(i + 1), 2, '0')}'  
  type: 'web'
  subnetName: 'snet-web'
  index: i
}]

resource webPips 'Microsoft.Network/publicIPAddresses@2024-05-01' = [for (vm, i) in webVmList: if (usePublicIP) {
  name: 'pip-${vm.name}'
  location: location
  zones: [string((i % 3) + 1)]
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    dnsSettings: {
      domainNameLabel: 'pip-${vm.name}'
    }
  }
}]

module webVms 'vm.bicep' = [for (vm, i) in webVmList: {
  name: vm.name
  params: {
    name: vm.name
    location: location
    subnetId: vnet.properties.subnets[1].id
    storageAccountName: storageAccountName
    windowsVersion: windowsVersion
    zone: string((i % 3) + 1)
    vmSize: vmSize
    publicIpAddressId: usePublicIP ? webPips[i].id : null
    adminUserName: adminUsername
    adminPassword: adminPassword
  }
}]

// App Servers
var appVmList = [for i in range(0, applicationServerCount): {
  name: 'vm${orgId}app${padLeft(string(i + 1), 2, '0')}' 
  type: 'app'
  subnetName: 'snet-app'
  index: i
}]

resource appPips 'Microsoft.Network/publicIPAddresses@2024-05-01' = [for (vm, i) in appVmList: if (usePublicIP) {
  name: 'pip-${vm.name}'
  location: location
  zones: [string((i % 3) + 1)]
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    dnsSettings: {
      domainNameLabel: 'pip-${vm.name}'
    }
  }
}]

module appVms 'vm.bicep' = [for (vm, i) in appVmList: {
  name: vm.name
  params: {
    name: vm.name
    location: location
    subnetId: vnet.properties.subnets[2].id
    storageAccountName: storageAccountName
    windowsVersion: windowsVersion
    zone: string((i % 3) + 1)
    vmSize: vmSize
    publicIpAddressId: usePublicIP ? appPips[i].id : null
    adminUserName: adminUsername
    adminPassword: adminPassword
  }
}]

// Database Servers
var dbsVmList = [for i in range(0, databaseServerCount): {
  name: 'vm${orgId}dbs${padLeft(string(i + 1), 2, '0')}'  
  type: 'dbs'
  subnetName: 'snet-dbs'
  index: i
}]

resource dbsPips 'Microsoft.Network/publicIPAddresses@2024-05-01' = [for (vm, i) in dbsVmList: if (usePublicIP) {
  name: 'pip-${vm.name}'
  location: location
  zones: [string((i % 3) + 1)]
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    dnsSettings: {
      domainNameLabel: 'pip-${vm.name}'
    }
  }
}]

module dbsVms 'vm.bicep' = [for (vm, i) in dbsVmList: {
  name: vm.name
  params: {
    name: vm.name
    location: location
    subnetId: vnet.properties.subnets[3].id
    storageAccountName: storageAccountName
    windowsVersion: windowsVersion
    zone: string((i % 3) + 1)
    vmSize: vmSize
    publicIpAddressId: usePublicIP ? dbsPips[i].id : null
    adminUserName: adminUsername
    adminPassword: adminPassword
  }
}]
