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