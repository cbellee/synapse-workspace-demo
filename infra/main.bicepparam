using './main.bicep'

param location = ''
param tags = {}
param administratorUsername = 'SqlServerFPAAdmin'
param administratorPassword = ''
param synapseSqlAdminGroupName = 'synapseAdminGroup'
param synapseSqlAdminGroupObjectID = ''
param synapseDEPEnabled = true
param synapseManagedVnetEnabled = true

