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
    $Name = Get-HtAddUserName
    if ($Name -ne $false) {
        $Password = Read-Host -AsSecureString "Enter Password: " | ConvertFrom-SecureString -key (get-content $KeyFile)

        $HtCred | Add-Member -MemberType NoteProperty -Name CommonName -Value $CommonName
        $HtCred | Add-Member -MemberType NoteProperty -Name Username -Value $Name
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
        [ValidateNotNullOrEmpty()]
        $CommonName
    )

    $HtCred = (Get-Content (Join-Path $CredFolder ($CommonName + ".json")) | Out-String | ConvertFrom-Json)

    $Password = $HtCred.Password | ConvertTo-SecureString -Key (Get-Content $KeyFile)
    $Credential = New-Object System.Management.Automation.PsCredential($HtCred.Username, $Password)

    return $Credential

}

function Get-HtAddUserName {
    
    [OutputType([bool], [PSCredential])]
    [CmdletBinding()]
    param (
        # Maximum amount of Azure Credential tries.
        [uint16]$MaxTry = 3
    )
    
    $Regex = "[a-z0-9!#$%&'*+/=?^_`{|}~-]+(?:\.[a-z0-9!#$%&'*+/=?^_`{|}~-]+)*@(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?"

    try {

        $Counter = 1
        do {
        
            $UserPrincipalName = Read-Host "Enter Username: "
            
            if ($UserPrincipalName -match $Regex) {
                
                Write-Verbose -Message 'Credential match the regex.'
                $UserPrincipalName
                break
            }
            if ($Counter -lt $MaxTry) {
        
                Write-Warning -Message 'Credentials does not match a valid UserPrincipalName in AzureAD, please provide a corrent UserPrincipalName.'
                Write-Warning -Message ('Try {0} of {1}' -f ($Counter + 1), $MaxTry)
            }
            elseif ($Counter -ge $MaxTry) {
                
                Write-Error -Message 'Credentials does not match a UserPrincipalName in AzureAD' -Exception 'System.Management.Automation.SetValueException' -Category InvalidResult -ErrorAction Stop
                break
            }

            $Counter++
        }
        # Regular expression for a valid UserPrincipalName.
        while ($UserPrincipalName -notmatch $Regex)
        #"[a-z0-9!#$%&'*+/=?^_`{|}~-]+(?:\.[a-z0-9!#$%&'*+/=?^_`{|}~-]+)*@(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?")
    }
    catch {

        Write-Verbose -Message ('Problem with Credentials - {0}' -f $_.Exception.Message)
        return $false
    }
}