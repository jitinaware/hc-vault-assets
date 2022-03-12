## This script performs the following functions for Vault:
## - initialize
## - unseal (external script)
## - log in as root token
## - enable file audit device
## - create namespace 
## - enable userpass authentication for new namespace
## You can set variables manually or specify them in a file via:
## Ex. VAULT_ADDR=$(cat ./variables.file | sed -n -e 's/^.*VAULT_ADDR=//p')

#!/bin/bash

export VAULT_ADDR=http://127.0.0.1:8200
export ROOT_NAMESPACE=acmecorp
export password=

set -e


echo -e "\n Starting Vault...\n"

vault operator init > ./vault-init-output.txt

# Vault is sealed on startup, so we're going to verify & unseal it
if vault status | grep Sealed | awk '{print $2}' | grep -q "true"; then 
  ./unseal-vault.sh
  sleep 5
else
  exit 1
fi

sleep 5

# Using this method instead of $VAULT_TOKEN as per
# this issue: https://github.com/hashicorp/vault/issues/6501
vault login token=$(cat ./vault-init-output.txt | sed -n -e 's/^.*Root Token: //p') >/dev/null

vault audit enable file file_path=/tmp/vault/logs/vault_audit.log
vault namespace create $ROOT_NAMESPACE
vault auth enable -namespace=$ROOT_NAMESPACE userpass
