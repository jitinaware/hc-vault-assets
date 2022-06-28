#!/bin/bash

## If changing for multiple users, format data in curl request like this:
## https://www.vaultproject.io/api-docs/secret/kv/kv-v2#sample-payload-1

VAULT_ADDR=http://127.0.0.1:8200
VAULT_TOKEN=
VAULT_NAMESPACE=
USERNAME=root
HOSTNAME=$(hostname -s)
JSON='{"format":"base64"}'
CHARLENGTH=26
NEWPASS=$(curl -sS --fail \
  --header "X-Vault-Token: ${VAULT_TOKEN}" \
  --request POST \
  --data ${JSON} ${VAULT_ADDR}/v1/sys/tools/random/${CHARLENGTH} | jq -r '.data.random_bytes')

# If first command fails, we won't update Vault
# POST secret (will create if it doesn't exist, or update if exists)
echo -e $NEWPASS | sudo passwd --stdin ${USERNAME} && \
  curl -sS --header "X-Vault-Token: ${VAULT_TOKEN}" \
          # --header "X-Vault-Namespace: ${VAULT_NAMESPACE}" \  # Uncomment to specify namespace
           --request POST \
           --data "{ \"data\": { \"${USERNAME}\": \"${NEWPASS}\"  }}" \
           ${VAULT_ADDR}/v1/secret/data/${HOSTNAME} | jq -r > /dev/null

# Uncomment to test read secret functionality
#curl -sS --header "X-Vault-Token: ${VAULT_TOKEN}" \
#	${VAULT_ADDR}/v1/secret/data/${HOSTNAME} | jq -r ".data.data.${USERNAME}"