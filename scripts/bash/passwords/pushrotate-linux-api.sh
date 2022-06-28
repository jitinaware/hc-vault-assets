#!/bin/bash

## If changing for multiple users, format data in curl request like this:
## https://www.vaultproject.io/api-docs/secret/kv/kv-v2#sample-payload-1

VAULT_ADDR=http://127.0.0.1:8200
VAULT_TOKEN=
USERNAME=root
HOSTNAME=$(hostname -s)
CHARLIST='A-Za-z0-9!"#$%&())*+,-./:;<=>?@[\]^_`{|}~' # Modify as desired
CHARLENGTH=26
NEWPASS=$(tr -dc $CHARLIST < /dev/urandom | head -c ${CHARLENGTH})

# If first command fails, we won't update Vault
# POST secret (will create if it doesn't exist, or update if exists)
echo -e $NEWPASS | sudo passwd --stdin ${USERNAME} && \
  curl -sS --header "X-Vault-Token: ${VAULT_TOKEN}" \
           --request POST \
           --data "{ \"data\": { \"${USERNAME}\": \"${NEWPASS}\"  }}" \
           ${VAULT_ADDR}/v1/secret/data/${HOSTNAME} | jq -r > /dev/null && \
  unset NEWPASS

# Uncomment to test read secret functionality
#curl -sS --header "X-Vault-Token: ${VAULT_TOKEN}" \
#	${VAULT_ADDR}/v1/secret/data/${HOSTNAME} | jq -r ".data.data.${USERNAME}"