TENANT_ID=$(az account show --query tenantId -o tsv)
SUBSCRIPTION_ID=$(az account show --query id -o tsv)
LOCATION='australiaeast'
CREDENTIAL_NAME='synapse-workspace-github-federated-id'
GITHUB_USER='cbellee'
GITHUB_REPO='synapse-workspace-demo'
GITHUB_BRANCH='main'

# create application registration
APP_OBJECT_ID=$(az ad app create --display-name $CREDENTIAL_NAME --query id -o tsv)
# APP_OBJECT_ID=$( az ad app list --display-name github-action-federated-id --query [].id -o tsv)
APP_CLIENT_ID=$(az ad app show --id $APP_OBJECT_ID --query appId -o tsv)
# APP_CLIENT_ID=$(az ad app show --id $APP_OBJECT_ID --query appId -o tsv)

# create service principal
SP_OBJECT_ID=$(az ad sp create --id $APP_CLIENT_ID --query id -o tsv)
# SP_OBJECT_ID=$(az ad sp show --id $APP_CLIENT_ID --query id -o tsv) 

# assign role to the service principal at a specific scope
az role assignment create --role owner \
  --subscription $SUBSCRIPTION_ID \
  --assignee-object-id  $SP_OBJECT_ID \
  --assignee-principal-type ServicePrincipal \
  --scope /subscriptions/$SUBSCRIPTION_ID

# add federated credentials
az rest \
  --method POST \
  --uri "https://graph.microsoft.com/beta/applications/$APP_OBJECT_ID/federatedIdentityCredentials" \
  --body "{ \
    \"name\":\"$CREDENTIAL_NAME\", \
    \"issuer\":\"https://token.actions.githubusercontent.com\", \
    \"subject\":\"repo:$GITHUB_USER/$GITHUB_REPO:ref:refs/heads/$GITHUB_BRANCH\", \
    \"description\":\"GitHub Federated Identity Credential\", \
    \"audiences\":[\"api://AzureADTokenExchange\"] \
  }" 

# add the following secrets to your GitHub account in the GitHub portal: 'Settings' -> 'Secrets' -> 'Actions' -> 'New Repository Secret'
':
AZURE_CLIENT_ID: $APP_CLIENT_ID
AZURE_TENANT_ID: $TENANT_ID
AZURE_SUBSCRIPTION_ID: $SUBSCRIPTION_ID
'
