param orgId string
param elzSubName string
param elzRegionId string
param vnetName string
param vnetAddress string
param snetWeb string
param snetApp string
param snetDb string
param snetMgt string
param location string 

resource nsgWeb 'Microsoft.Network/networkSecurityGroups@2021-03-01' = {
  name: 'nsg-${orgId}-${elzSubName}-${elzRegionId}-web'
  location: location
  properties: {
    securityRules: [
      {
      name: 'Drop_All'
      properties: {
        protocol: 'Tcp'
        sourcePortRange: '*'
        destinationPortRange: '*'
        sourceAddressPrefix: '*'
        destinationAddressPrefix: '*'
        access: 'Deny'
        priority: 4096
        direction: 'Inbound'
        }      
      }
    ]
  }
}

resource nsgApp 'Microsoft.Network/networkSecurityGroups@2021-03-01' = {
  name: 'nsg-${orgId}-${elzSubName}-${elzRegionId}-app'
  location: location
  properties: {
    securityRules: [
      {
      name: 'Drop_All'
      properties: {
        protocol: 'Tcp'
        sourcePortRange: '*'
        destinationPortRange: '*'
        sourceAddressPrefix: '*'
        destinationAddressPrefix: '*'
        access: 'Deny'
        priority: 4096
        direction: 'Inbound'
        }      
      }
    ]
  }
}

resource nsgDb 'Microsoft.Network/networkSecurityGroups@2021-03-01' = {
  name: 'nsg-${orgId}-${elzSubName}-${elzRegionId}-db'
  location: location
  properties: {
    securityRules: [
      {
      name: 'Drop_All'
      properties: {
        protocol: 'Tcp'
        sourcePortRange: '*'
        destinationPortRange: '*'
        sourceAddressPrefix: '*'
        destinationAddressPrefix: '*'
        access: 'Deny'
        priority: 4096
        direction: 'Inbound'
        }      
      }
    ]
  }
}

resource nsgMgt 'Microsoft.Network/networkSecurityGroups@2021-03-01' = {
  name: 'nsg-${orgId}-${elzSubName}-${elzRegionId}-mgt'
  location: location
  properties: {
    securityRules: [
      {
      name: 'Drop_All'
      properties: {
        protocol: 'Tcp'
        sourcePortRange: '*'
        destinationPortRange: '*'
        sourceAddressPrefix: '*'
        destinationAddressPrefix: '*'
        access: 'Deny'
        priority: 4096
        direction: 'Inbound'
        }      
      }
    ]
  }
}

resource vnet 'Microsoft.Network/virtualNetworks@2021-03-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetAddress
      ]
    }
    subnets: [
      {
        id: 'snetWeb'
        name: 'snet-web'
        properties: {
          addressPrefix: snetWeb          
          networkSecurityGroup: {
            id: nsgWeb.id
          }
          routeTable: {
            id: rt.id
          }
        }
      }
      {
        id: 'snetApp'
        name: 'snet-app'
        properties: {
          addressPrefix: snetApp
          networkSecurityGroup: {
            id: nsgApp.id
          }
          routeTable: {
            id: rt.id
          }
        }
      }
      {
        id: 'snetDb'
        name: 'snet-db'
        properties: {
          addressPrefix: snetDb
          networkSecurityGroup: { 
            id: nsgDb.id
          }
          routeTable: {
            id: rt.id
          }
        }
      }
      {
        id: 'snetMgt'
        name: 'snet-mgt'
        properties: {
          addressPrefix: snetMgt
          networkSecurityGroup: { 
            id: nsgMgt.id
          }
          routeTable: {
            id: rt.id
          }
        }
      }
    ]
  }
}

resource rt 'Microsoft.Network/routeTables@2021-03-01' = {
  name: 'rt-${orgId}-${elzSubName}-${elzRegionId}-01'
  location: location
  properties: {
    routes: [
      {
        name: 'Default_route_to_Azure_Firewall'
        properties: {
          addressPrefix: '0.0.0.0/0'
          nextHopIpAddress: '10.10.10.10'
          nextHopType: 'VirtualAppliance'
        }
      }
    ]
  }
}
