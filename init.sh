#!/bin/bash

az login -t 72f988bf-86f1-41af-91ab-2d7cd011db47
az login -t 72f988bf-86f1-41af-91ab-2d7cd011db47 --use-device-code -o table
az account set -s '0c378775-d18a-45bb-b426-3627de556dd1'  ## sub1
az account set -s 'ce8e7a90-6ff0-4074-8417-a55e6cac276f'  ## sub2
echo "Defining variables..."
export RESOURCE_GROUP_NAME=mslearn-gh-pipelines-$RANDOM
export AKS_NAME=contoso-video
export ACR_NAME=ContosoContainerRegistry$RANDOM

echo "Searching for resource group..."
az group create -n $RESOURCE_GROUP_NAME -l eastus

echo "Creating cluster..."
az aks create \
  --resource-group $RESOURCE_GROUP_NAME \
  --name $AKS_NAME \
  --node-count 1 \
  --enable-addons http_application_routing \
  --dns-name-prefix $AKS_NAME \
  --enable-managed-identity \
  --generate-ssh-keys \
  --node-vm-size Standard_B2s

echo "Obtaining credentials..."
az aks get-credentials -n $AKS_NAME -g $RESOURCE_GROUP_NAME

echo "Creating ACR..."
az acr create -n $ACR_NAME -g $RESOURCE_GROUP_NAME --sku basic
az acr update -n $ACR_NAME --admin-enabled true

export ACR_USERNAME=$(az acr credential show -n $ACR_NAME --query "username" -o tsv)
export ACR_PASSWORD=$(az acr credential show -n $ACR_NAME --query "passwords[0].value" -o tsv)

az aks update \
    --name $AKS_NAME \
    --resource-group $RESOURCE_GROUP_NAME \
    --attach-acr $ACR_NAME

export DNS_NAME=$(az network dns zone list -o json --query "[?contains(resourceGroup,'$RESOURCE_GROUP_NAME')].name" -o tsv)

sed -i '' 's+!IMAGE!+'"$ACR_NAME"'/contoso-website+g' kubernetes/deployment.yaml
sed -i '' 's+!DNS!+'"$DNS_NAME"'+g' kubernetes/ingress.yaml

echo "Installation concluded, copy these values and store them, you'll use them later in this exercise:"
echo "-> Resource Group Name: $RESOURCE_GROUP_NAME"
echo "-> ACR Name: $ACR_NAME"
echo "-> ACR Login Username: $ACR_USERNAME"
echo "-> ACR Password: $ACR_PASSWORD"
echo "-> AKS Cluster Name: $ACR_NAME"
echo "-> AKS DNS Zone Name: $DNS_NAME"

ACR_NAME=ContosoContainerRegistry7080
az acr list --query "[?contains(resourceGroup, 'mslearn-gh-pipelines')].loginServer" -o table
az acr repository list --name $ACR_NAME -o table 
az acr repository show-tags --repository contoso-website --name $ACR_NAME -o table
## Show the DNS of the cluster
## az aks show -g {resource-group-name} -n {aks-cluster-name} -o tsv --query addonProfiles.httpApplicationRouting.config.HTTPApplicationRoutingZoneName
az aks show -g mslearn-gh-pipelines-6500 -n contoso-video -o tsv --query addonProfiles.httpApplicationRouting.config.HTTPApplicationRoutingZoneName