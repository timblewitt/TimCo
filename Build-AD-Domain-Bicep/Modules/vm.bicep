param name string
param location string
param subnetId string
param storageAccountName string
param windowsVersion string
param zone string
param vmSize string
param publicIpAddressId string = ''
param adminUserName string
@secure()
param adminPassword string
@allowed([
  'Standard'
  'TrustedLaunch'
])
param securityType string = 'TrustedLaunch'

resource nic 'Microsoft.Network/networkInterfaces@2024-05-01' = {
  name: '${name}-nic01'  
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: subnetId
          }
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: empty(publicIpAddressId) ? null : {
            id: publicIpAddressId
          }
        }
      }
    ]
  }
}

resource vm 'Microsoft.Compute/virtualMachines@2024-11-01' = {
  name: name
  location: location
  zones: [zone]
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: name
      adminUsername: adminUserName
      adminPassword: adminPassword
    }
    securityProfile: {
      securityType: securityType
      uefiSettings: securityType == 'TrustedLaunch' ? {
        secureBootEnabled: true
        vTpmEnabled: true
      } : {
        secureBootEnabled: false
        vTpmEnabled: false
      }
    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: windowsVersion
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'Standard_LRS'
        }
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic.id
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
        storageUri: 'https://${storageAccountName}.blob.core.windows.net'
      }
    }
  }
}
