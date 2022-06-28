# Allows users/admins to read Linux passwords.

path "servers/linux/*" {
  capabilities = ["read", "list"]
}