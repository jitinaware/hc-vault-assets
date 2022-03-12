storage "file" {
  path    = "vault/file"
}

listener "tcp" {
  address     = "0.0.0.0:8200"
  tls_disable = "true"
}

disable_mlock = true

license_path = "vault/config/vault.hclic"

plugin_directory = "vault/plugins"

api_addr = "http://0.0.0.0:8200"
ui = true