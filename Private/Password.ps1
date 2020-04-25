function Set-HtCryptKey {
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        $Path
    )

    $Key = New-Object Byte[] 32
    [Security.Cryptography.RNGCryptoServiceProvider]::Create().GetBytes($Key)
    $Key | out-file (Join-Path $Path "aes.key")
    
    return (Join-Path $Path "aes.key")
}

function Set-HtCredential {
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        $KeyFile,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        $CredFolder
    )

    $HtCred = New-Object -TypeName psobject
    
    $CommonName = Read-Host "Enter a Common Name: (aA, 01, -, _)"
    $Name = Read-Host "Enter Username: "
    $Password = Read-Host -AsSecureString "Enter Password: " | ConvertFrom-SecureString -key (get-content $KeyFile)

    $HtCred | Add-Member -MemberType NoteProperty -Name CommonName -Value $CommonName
    $HtCred | Add-Member -MemberType NoteProperty -Name Username -Value $Name
    $HtCred | Add-Member -MemberType NoteProperty -Name Password -Value $Password

    $Path = Join-Path $CredFolder ($CommonName + ".json")
    $HtCred | Select-Object -Property * | ConvertTo-Json | Set-Content -Encoding UTF8 -Path $Path

}

function Get-HtCredential {
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        $KeyFile,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        $CredFolder,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        $CommonName
    )

    $HtCred = (Get-Content (Join-Path $CredFolder ($CommonName + ".json")) | Out-String | ConvertFrom-Json)

    $Password = $HtCred.Password | ConvertTo-SecureString -Key (Get-Content $KeyFile)
    $Credential = New-Object System.Management.Automation.PsCredential($HtCred.Username, $Password)

    return $Credential

}