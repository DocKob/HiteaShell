function Set-HtCryptKey {
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        $Path
    )

    $Key = New-Object Byte[] 32
    [Security.Cryptography.RNGCryptoServiceProvider]::Create().GetBytes($Key)
    $Key | out-file (Join-Path $Path "aes.key")
    
}

function Set-HtCredential {
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        $KeyFile,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        $CredPath
    )

    $HtCred = New-Object -TypeName psobject
    
    $Name = Read-Host "Enter Username: "
    $Password = Read-Host -AsSecureString "Enter Password: " | ConvertFrom-SecureString -key (get-content $KeyFile)

    $HtCred | Add-Member -MemberType NoteProperty -Name Username -Value $Name
    $HtCred | Add-Member -MemberType NoteProperty -Name Password -Value $Password

    $HtCred | Select-Object -Property * | ConvertTo-Json | Set-Content -Encoding UTF8 -Path $CredPath

}

function Get-HtCredential {
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        $KeyFile,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        $CredPath
    )

    $HtCred = (Get-Content $CredPath | Out-String | ConvertFrom-Json)

    $Password = $HtCred.Password | ConvertTo-SecureString -Key (Get-Content $KeyFile)
    $Credential = New-Object System.Management.Automation.PsCredential($HtCred.Username, $Password)

    return $Credential

}