## This script unseals Vault
## Can be used w/ init-vault.sh script
## You can set variables manually or specify them in a file via:
## Ex. VAULT_ADDR=$(cat ./variables.file | sed -n -e 's/^.*VAULT_ADDR=//p')

#!/bin/bash
set -e

export VAULT_ADDR=http://127.0.0.1:8200


VAULT_TOKEN=$(cat ./vault-init-output.txt | sed -n -e 's/^.*Root Token: //p')

IFS=$'\r\n' GLOBIGNORE='*' command eval \
  "UNSEAL_KEYS=($(cat ./vault-init-output.txt | grep '^Unseal' | rev | cut -d ' ' -f 1 | rev))"

function vaultstatuscheck(){
        vault status | grep Sealed | awk '{print $2}'
}

echo -e "\n Unsealing Vault..."

KEY_INDEX=0
while [[ `vaultstatuscheck` = "true" ]]; do
  sleep 1s
  vault operator unseal $(echo "${UNSEAL_KEYS[$KEY_INDEX]}") > /dev/null
  KEY_INDEX=$(( $KEY_INDEX + 1 ))
done

# Alternative unseal method:
#for i in {0..3}
#do
#        sleep 1s
#        vault operator unseal $(echo "${UNSEAL_KEYS[KEY_INDEX]}")
#        KEY_INDEX=$(( $KEY_INDEX + 1))
#done

sleep 2

case `vaultstatuscheck` in
    "false")
        #clear
        echo -e "\nVault is now unsealed!\n"
        exit 0;
        ;;
    "true")
        #clear
        echo -e "\nERROR: There was an error unsealed Vault, exiting...\n"
        exit 1;
        ;;
    *)
        #clear
        echo -e "\nThere was an error unsealing Vault - is the service running? \nMore info:"
        sudo systemctl is-active vault.service 
        exit 1;
        ;;
esac