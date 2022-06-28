# If not using the 'passgen' Vault plugin, only apply the first policy

# Allows hosts/scripts to write new passwords
path "servers/windows/*" {
  capabilities = ["create", "update"]
}

# Allow hosts to generate new passwords
# Only needed if using the Password Generator Plugin
path "passgen/password" {
  capabilities = ["update"]
}