param name string
param location string
param subnetId string
param storageAccountName string
param windowsVersion string
param zone string
param vmSize string
param publicIpAddressId string?  // New parameter to accept the public IP address (nullable)

var imageVersionMap = {
  '2019': '2019-Datacenter'
  '2022': '2022-Datacenter'
  '2025': '2025-Datacenter'
}

resource nic 'Microsoft.Network/networkInterfaces@2023-02-01' = {
  name: '${name}-nic01'  // Append -nic01 to each NIC name
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
          publicIPAddress: publicIpAddressId != null ? {
            id: publicIpAddressId
          } : null  // Only associate the public IP if it's provided
        }
      }
    ]
  }
}

resource vm 'Microsoft.Compute/virtualMachines@2023-03-01' = {
  name: name
  location: location
  zones: [zone]
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: name
      adminUsername: 'azureuser'
      adminPassword: 'P@ssword1234!' // Use Key Vault in production
    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: imageVersionMap[windowsVersion]
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
