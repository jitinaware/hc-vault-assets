# Allows users/admins to read Windows Server passwords.

path "servers/windows/*" {
  capabilities = ["read", "list"]
}