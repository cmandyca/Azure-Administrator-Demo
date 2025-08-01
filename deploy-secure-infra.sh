#!/bin/bash

# Stop on any error
set -e

# --- Configuration Variables ---
RESOURCE_GROUP="MySecureDemo-RG"
LOCATION="westus2"
VM_NAME="Secure-Web-VM"
VNET_NAME="Secure-VNet"
SUBNET_NAME="Web-Subnet"
KEY_VAULT_NAME="kv-sec-demo-$(openssl rand -hex 4)"
ADMIN_USERNAME="azureadmin"
ADMIN_PASSWORD="Password1234!"

# --- Login and Set Subscription ---
echo "Logging in to Azure..."
az login
az account set --subscription "cbcb5615-4e14-4db6-8569-0fc9dc70a04b"

# --- 1. Enable Microsoft Defender Plans ---
echo "Enabling Microsoft Defender for Cloud..."
az security pricing create -n "CloudPosture" --tier "Standard"
az security pricing create -n "VirtualMachines" --tier "Standard"

# --- 2. Create Resource Group ---
echo "Creating resource group: $RESOURCE_GROUP..."
az group create --name "$RESOURCE_GROUP" --location "$LOCATION"

# --- 3. Create Key Vault for Disk Encryption ---
echo "Creating Key Vault: $KEY_VAULT_NAME..."
az keyvault create \
    --name "$KEY_VAULT_NAME" \
    --resource-group "$RESOURCE_GROUP" \
    --location "$LOCATION" \
    --enabled-for-disk-encryption

# --- 4. Create Networking ---
echo "Creating VNet and Subnet..."
az network vnet create \
    --name "$VNET_NAME" \
    --resource-group "$RESOURCE_GROUP" \
    --address-prefix "10.1.0.0/16" \
    --subnet-name "$SUBNET_NAME" \
    --subnet-prefix "10.1.1.0/24"

# --- 5. Create Virtual Machine with a System-Assigned Managed Identity ---
echo "Creating Virtual Machine: $VM_NAME..."
az vm create \
    --resource-group "$RESOURCE_GROUP" \
    --name "$VM_NAME" \
    --image "Win2019Datacenter" \
    --admin-username "$ADMIN_USERNAME" \
    --admin-password "$ADMIN_PASSWORD" \
    --vnet-name "$VNET_NAME" \
    --subnet "$SUBNET_NAME" \
    --size "Standard_B2s" \
    --public-ip-sku "Standard" \
    --assign-identity

# --- 6. Grant VM Access to Key Vault ---
echo "Granting VM Managed Identity access to Key Vault..."
VM_IDENTITY_ID=$(az vm identity show --resource-group "$RESOURCE_GROUP" --name "$VM_NAME" --query "principalId" -o tsv)
KEY_VAULT_ID=$(az keyvault show --name "$KEY_VAULT_NAME" --resource-group "$RESOURCE_GROUP" --query "id" -o tsv)

az role assignment create \
    --role "Key Vault Crypto Service Encryption User" \
    --assignee-object-id "$VM_IDENTITY_ID" \
    --scope "$KEY_VAULT_ID"

# --- 7. Apply Security Policies using PowerShell ---
echo "Waiting for services to initialize before applying policies..."
sleep 90

echo "Applying JIT Policy and Disk Encryption via PowerShell..."
VM_ID=$(az vm show --resource-group "$RESOURCE_GROUP" --name "$VM_NAME" --query "id" -o tsv)
KEY_VAULT_URL=$(az keyvault show --name "$KEY_VAULT_NAME" --resource-group "$RESOURCE_GROUP" --query "properties.vaultUri" -o tsv)
ACCESS_TOKEN=$(az account get-access-token --resource-type arm --query accessToken --output tsv)
USER_ID=$(az ad signed-in-user show --query userPrincipalName --output tsv)
TENANT_ID=$(az account show --query tenantId --output tsv)

# This single PowerShell block handles both JIT and Disk Encryption
pwsh -Command "
  Import-Module Az.Security -ErrorAction Stop;
  Import-Module Az.Compute -ErrorAction Stop;
  Connect-AzAccount -AccessToken \"$ACCESS_TOKEN\" -AccountId \"$USER_ID\" -TenantId \"$TENANT_ID\";

  Write-Host 'Applying JIT Network Access Policy...';
  Set-AzJitNetworkAccessPolicy -Name 'default' -Kind 'Basic' -ResourceGroupName '$RESOURCE_GROUP' -Location '$LOCATION' -VirtualMachine @{Id='$VM_ID'; Ports=@(@{Number=3389; Protocol='TCP'; AllowedSourceAddressPrefix='*'; MaxRequestAccessDuration='PT4H'})};

  Write-Host 'Enabling Azure Disk Encryption...';
  Set-AzVMDiskEncryptionExtension -ResourceGroupName '$RESOURCE_GROUP' -VMName '$VM_NAME' -DiskEncryptionKeyVaultUrl '$KEY_VAULT_URL' -DiskEncryptionKeyVaultId '$KEY_VAULT_ID' -VolumeType 'All';
"

echo "-----------------------------------------------------"
echo "Deployment Complete!"
echo "Resource Group: $RESOURCE_GROUP"
echo "-----------------------------------------------------"