# Password Rotation Scripts

## pullrotate-linux-api.sh

This script performs a pull-rotate-push password rotation for linux hosts. An API call to sys/tools/random generates a new password (basically calls /dev/urandom), rotates it locally, then uses a limited-privs Vault token (tied to rotate_linux.hcl) to update it on the Vault server KV Store via API. 

<b>Vault Agent is NOT required for this method.</b>

## pushrotate-linux-api.sh


This script generates a new password locally and uses a limited-privs Vault token (tied to rotate_linux.hcl) to update it on the Vault server KV Store via API. 

<b>Vault Agent is NOT required for this method.</b>