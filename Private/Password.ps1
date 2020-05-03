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
    
    $CommonName = Get-HtValidateString -Type "CommonName"
    $Username = Get-HtValidateString -Type "Email"
    $Service = Get-HtValidateString -Type "Service"
    if (($Username -ne $false) -and ($CommonName -ne $false) -and ($Service -ne $false)) {
        $Password = Read-Host -AsSecureString "Enter Password: " | ConvertFrom-SecureString -key (get-content $KeyFile)

        $HtCred | Add-Member -MemberType NoteProperty -Name CommonName -Value $CommonName
        $HtCred | Add-Member -MemberType NoteProperty -Name CommonName -Value $Service
        $HtCred | Add-Member -MemberType NoteProperty -Name Username -Value $Username
        $HtCred | Add-Member -MemberType NoteProperty -Name Password -Value $Password

        $Path = Join-Path $CredFolder ($CommonName + ".json")
        $HtCred | Select-Object -Property * | ConvertTo-Json | Set-Content -Encoding UTF8 -Path $Path
    }
    else {
        Write-Verbose "Set-HtCredential Error !"
    }
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
        $CommonName
    )

    if (!(Test-Path (Join-Path $CredFolder ($CommonName + ".json")))) {
        return $false
    }
    else {
        $HtCred = (Get-Content (Join-Path $CredFolder ($CommonName + ".json")) | Out-String | ConvertFrom-Json)
        $Password = $HtCred.Password | ConvertTo-SecureString -Key (Get-Content $KeyFile)
        $Credential = New-Object System.Management.Automation.PsCredential($HtCred.Username, $Password)
        return $Credential
    }
}