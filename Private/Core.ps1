function Import-HtConfiguration() {
    [CmdletBinding(
        SupportsShouldProcess = $true
    )]
    Param(
        [Parameter(Mandatory = $True)]
        [ValidateNotNullOrEmpty()]
        [string]$ProfilePath
    )

    if (Test-Path $ProfilePath -ErrorAction SilentlyContinue) {
        $Configuration = (Get-Content $ProfilePath | Out-String | ConvertFrom-Json)
    }
    else {
        Read-Host "Profile error, exit... "
        exit
    }
    $Configuration | Add-Member Filename $ProfilePath
    return $Configuration
}

function Save-HtConfiguration() {
    [CmdletBinding(
        SupportsShouldProcess = $true
    )]
    Param(
        [Parameter(Mandatory = $True)]
        [ValidateNotNullOrEmpty()]
        $Configuration
    )
    
    $excluded = @('Filename')
    $Configuration | Select-Object -Property * -ExcludeProperty $excluded | ConvertTo-Json | Set-Content -Encoding UTF8 -Path $Configuration.Filename
    Write-Verbose -Message "Config file saved !"
}

function Confirm-HtConfigurationItem {
    [CmdletBinding(
        SupportsShouldProcess = $true
    )]
    Param(
        [Parameter(Mandatory = $True)]
        [ValidateNotNullOrEmpty()]
        $ConfigurationItem,
        [Parameter(Mandatory = $True)]
        $Item
    )

    if ([string]::IsNullOrEmpty($Item)) {
        return $null
    }
    elseif ([bool]($ConfigurationItem -match $Item)) {
        return $true
    }
    else {
        return $false
    }
    
}

function Install-HtBase {
    [CmdletBinding(
        SupportsShouldProcess = $true
    )]
    param (        
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        $InstallConfig
    )

    if ((Test-Path "$($BaseFolder)/Config/Installed.txt") -and (Test-Path $InstallConfig.BasePath) ) {
        return
    }

    New-HtFolders -Folders $InstallConfig.BaseFolders -Path $InstallConfig.BasePath
    Install-HtModules -Modules $InstallConfig.PsModules -Path (Join-Path $InstallConfig.BasePath "PsModule")
    Install-HtM365Modules
    Get-HtDeviceInfos -Export (Join-Path $InstallConfig.BasePath "Export")

    Set-HtRegKey -Key "InstallPath" -Value $InstallConfig.BasePath -Type "String"
    Set-HtRegKey -Key "InstallDate" -Value (Get-Date) -Type "String"
    Get-Date | Out-File -Encoding UTF8 -FilePath "$($BaseFolder)/Config/Installed.txt"
}

Function Invoke-HtMenu {
    [CmdletBinding(
        SupportsShouldProcess = $true
    )]
    Param(
        [Parameter(Position = 0, Mandatory = $True, HelpMessage = "Choice an Option !")]
        [ValidateNotNullOrEmpty()]
        [string]$Menu,
        [Parameter(Position = 1)]
        [ValidateNotNullOrEmpty()]
        [string]$Title = "",
        [Alias("cls")]
        [switch]$ClearScreen
    )

    if ($ClearScreen) { 
        Clear-Host 
    }

    $menuprompt = "-" * $title.Length
    $menuprompt += "`n"
    $menuprompt += "-" * $title.Length
    $menuprompt += "`n"
    $menuPrompt += $title
    $menuprompt += "`n"
    $menuprompt += "-" * $title.Length
    $menuprompt += "`n"
    $menuprompt += "-" * $title.Length
    $menuprompt += "`n"
    $menuprompt += "`n"
    $menuPrompt += $menu
    $menuprompt += "`n`n`n"
    $menuprompt += "Choose an option "
    
 
    Read-Host -Prompt $menuprompt
 
}

function Get-HtValidateString {
    
    [OutputType([bool], [PSCredential])]
    [CmdletBinding()]
    param (
        [uint16]$MaxTry = 3,
        [Parameter(Mandatory = $true)]
        [ValidateSet('Email', 'CommonName')]
        [ValidateNotNullOrEmpty()]
        $Type
    )

    switch ($Type) {
        "Email" { 
            $Regex = "[a-z0-9!#$%&'*+/=?^_`{|}~-]+(?:\.[a-z0-9!#$%&'*+/=?^_`{|}~-]+)*@(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?"
        }
        "CommonName" { 
            $Regex = "^[a-z]{2,}\d*$"
        }
        "HostName" {
            $Regex = "^[A-Z-0-9]{1,15}$"
        }
        "Service" {
            $Regex = "^[a-z]{2,}\d*$"
        }
        Default { return $false }
    }
    try {

        $Counter = 1
        do {
        
            $UserPrincipalName = Read-Host "Enter $($Type): "
            
            if ($UserPrincipalName -match $Regex) {
                
                Write-Verbose -Message "$($Type) match the regex."
                $UserPrincipalName
                break
            }
            if ($Counter -lt $MaxTry) {
        
                Write-Warning -Message "$($Type) does not match a valid input, please provide a corrent $($Type)."
                Write-Warning -Message ("Try {0} of {1}" -f ($Counter + 1), $MaxTry)
            }
            elseif ($Counter -ge $MaxTry) {
                
                Write-Error -Message "$($Type) does not match the regex" -Exception "System.Management.Automation.SetValueException" -Category InvalidResult -ErrorAction Stop
                break
            }

            $Counter++
        }
        while ($UserPrincipalName -notmatch $Regex)
    }
    catch {
        Write-Verbose -Message ('Problem with Credentials - {0}' -f $_.Exception.Message)
        return $false
    }
}