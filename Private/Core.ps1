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

function Install-HtBase {
    [CmdletBinding(
        SupportsShouldProcess = $true
    )]
    param (        
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        $InstallDefault
    )

    if (Test-Path "$($BaseFolder)/Config/Installed.txt") {
        return
    }

    $InstallConfig = Import-HtConfiguration -ProfilePath $InstallDefault

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