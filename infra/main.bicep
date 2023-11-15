// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

// This template is used to create a Synapse workspace.
targetScope = 'resourceGroup'

// Parameters
param location string = resourceGroup().location
param tags object = {}
param administratorUsername string = 'SqlServerFPAAdmin'
@secure()
param administratorPassword string
param synapseSqlAdminGroupName string = 'synapseAdminGroup'
param synapseSqlAdminGroupObjectID string = ''
param synapseDEPEnabled bool = true
param synapseManagedVnetEnabled bool = true

var affix = uniqueString(resourceGroup().id)
var storageAccountName = 'stor${affix}'
var synapseName = 'syn${affix}'
var managedResourceGroupName = 'syn-${affix}-rg'

// Resources
resource storage 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
}

resource synapse 'Microsoft.Synapse/workspaces@2021-06-01' = {
  name: synapseName
  location: location
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    defaultDataLakeStorage: {
      accountUrl: 'https://${storageAccountName}.dfs.${environment().suffixes.storage}' 
      filesystem: 'files'
      resourceId: storage.id
      createManagedPrivateEndpoint: synapseManagedVnetEnabled ? true : false
    }
    managedResourceGroupName: managedResourceGroupName
    managedVirtualNetwork: synapseManagedVnetEnabled ? 'default' : null
    managedVirtualNetworkSettings: synapseManagedVnetEnabled ? {
      allowedAadTenantIdsForLinking: []
      linkedAccessCheckOnTargetResource: true
      preventDataExfiltration: synapseDEPEnabled
    } : null
    publicNetworkAccess: 'Disabled'
    // purviewConfiguration: {
    //   purviewResourceId: purviewId
    // }
    sqlAdministratorLogin: administratorUsername
    sqlAdministratorLoginPassword: administratorPassword
  }
}

resource synapseManagedIdentitySqlControlSettings 'Microsoft.Synapse/workspaces/managedIdentitySqlControlSettings@2021-06-01' = {
  parent: synapse
  name: 'default'
  properties: {
    grantSqlControlToManagedIdentity: {
      desiredState: 'Enabled'
    }
  }
}

resource synapseAadAdministrators 'Microsoft.Synapse/workspaces/administrators@2021-03-01' = if (!empty(synapseSqlAdminGroupName) && !empty(synapseSqlAdminGroupObjectID)) {
  parent: synapse
  name: 'activeDirectory'
  properties: {
    administratorType: 'ActiveDirectory'
    login: synapseSqlAdminGroupName
    sid: synapseSqlAdminGroupObjectID
    tenantId: subscription().tenantId
  }
}



// Outputs
output synapseId string = synapse.id
