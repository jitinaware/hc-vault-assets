## This script generates a password locally, 
## changes it on the target user, and pushes it to Vault. 
## Modified from the original which was written by Sean Carolan.


$VAULT_ADDR = "http://127.0.0.1:8200"
$VAULT_TOKEN = "127.0.0.1"
$HOSTNAME = $env:computername
$VAULT_NAMESPACE = "acmecorp/it"
$USERNAME = "infrauser"

$ErrorActionPreference = "Stop"

Function MakeUp-String([Int]$Size = 16, [Char[]]$CharSets = "ULNS", [Char[]]$Exclude) {
    $Chars = @(); $TokenSet = @()
    If (!$TokenSets) {$Global:TokenSets = @{
        U = [Char[]]'ABCDEFGHIJKLMNPQRSTUVWXYZ'                                #Upper case
        L = [Char[]]'abcdefghijkmnpqrstuvwxyz'                                #Lower case
        N = [Char[]]'0123456789'                                                #Numerals
        S = [Char[]]'!"#$%&''()*+,-./:;<=>?@[\]^_`{|}~'                         #Symbols
    }}
    $CharSets | ForEach {
        $Tokens = $TokenSets."$_" | ForEach {If ($Exclude -cNotContains $_) {$_}}
        If ($Tokens) {
            $TokensSet += $Tokens
            If ($_ -cle [Char]"Z") {$Chars += $Tokens | Get-Random}             #Character sets defined in upper case are mandatory
        }
    }
    While ($Chars.Count -lt $Size) {$Chars += $TokensSet | Get-Random}
    ($Chars | Sort-Object {Get-Random}) -Join ""                                #Mix the (mandatory) characters and output string
}; Set-Alias Generate-Password MakeUp-String -Description "Generate a random string (password)"

# Check if running in an elevated prompt
$IsElevated = ([Security.Principal.WindowsPrincipal] `
[Security.Principal.WindowsIdentity]::GetCurrent()
).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator) 

if ($IsElevated -match "False")
{
    clear
    Write-Warning "Current shell doesn't have admin privs, re-run this script w/ admin rights to continue!"
    break
}
    
# See if target user exists
Try
{
    Get-LocalUser $USERNAME 
}
Catch [Microsoft.PowerShell.Commands.UserNotFoundException]
{
    clear
    Write-Warning "User doesn't exist, creating..."
    New-LocalUser -Name $USERNAME -Description "Account used by infra team for local access." -NoPassword
    Add-LocalGroupMember -Group "Administrators" -Member $USERNAME 
}
Catch
{   
    Write-Warning "There was an error querying for $USERNAME"
}

# Renew our token before we do anything else.
Try
{
    Invoke-RestMethod -Headers @{"X-Vault-Token" = ${VAULT_TOKEN}; "X-Vault-Namespace" = ${VAULT_NAMESPACE}} -Method POST -Uri ${VAULT_ADDR}/v1/auth/token/renew-self 
}
Catch [System.Net.WebException]
{
    Write-Warning $error[0].exception.Message
}
Catch
{
    Write-Warning "There was some other error when trying to renew self token."
} 


$NEWPASS = (Generate-Password 16 ULN)

# Convert into a SecureString
$SECUREPASS = ConvertTo-SecureString $NEWPASS -AsPlainText -Force

# Create the JSON payload to write to Vault's K/V store. Keep the last 12 versions of this credential.
$JSON="{ `"options`": { `"max_versions`": 12 }, `"data`": { `"$USERNAME`": `"$NEWPASS`" } }"

# First commit the new password to vault, then change it locally.
Invoke-RestMethod -Headers @{"X-Vault-Token" = ${VAULT_TOKEN}; "X-Vault-Namespace" = ${VAULT_NAMESPACE}} -Method POST -Body $JSON -Uri ${VAULT_ADDR}/v1/infra/data/windows-servers/${HOSTNAME}
if($?) 
{
    Remove-Variable NEWPASS
    Write-Output "Vault updated with new password."
    $UserAccount = Get-LocalUser -name $USERNAME
    $UserAccount | Set-LocalUser -Password $SECUREPASS
    if($?) 
    {
        Write-Output "${USERNAME}'s password was stored in Vault and updated locally."
    }
    else 
    {
        Write-Warning "${USERNAME}'s password was stored in Vault but NOT updated locally."
    }
}
else 
{
    Write-Warning "Something went wrong when saving the new password to Vault. Local password will remain unchanged."
} 
     
    