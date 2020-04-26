function Set-HtRegKey {
    [CmdletBinding(
        SupportsShouldProcess = $true
    )]
    param(
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        $BasePath = "HKLM:\SOFTWARE\HiteaNet\HtShell",
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        $Key,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        $Value,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        $Type
    )

    if (!(Test-Path $BasePath)) {
        New-Item -Path "HKLM:\SOFTWARE\" -Name "HiteaNet"
        New-Item -Path "HKLM:\SOFTWARE\HiteaNet" -Name "HtShell"
    }

    if (Get-ItemProperty -Path $BasePath -Name $Key -ErrorAction SilentlyContinue) {
        Remove-ItemProperty -Path $BasePath -Name $Key -Force
    }
    New-ItemProperty -Path $BasePath -Name $Key -Value $Value -PropertyType $Type

}

function Get-HtRegKey {
    [CmdletBinding(
        SupportsShouldProcess = $true
    )]
    param(
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        $BasePath = "HKLM:\SOFTWARE\HiteaNet\HtShell",
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        $Key
    )

    $RegKey = Get-ItemProperty -Path $BasePath -Name $Key

    return $RegKey.$Key
    
}

function Get-HtRegObj {
    [CmdletBinding(
        SupportsShouldProcess = $true
    )]
    Param(
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        $BasePath = "HKLM:\SOFTWARE\HiteaNet\HtShell"
    )
    $HtRegObj = [PSCustomObject]@{ }
    Push-Location
    Set-Location -Path $BasePath
    Get-Item . |
    Select-Object -ExpandProperty property |
    ForEach-Object {
        $HtRegObj | Add-Member $_ (Get-ItemProperty -Path . -Name $_).$_
    }
    Pop-Location
    Return $HtRegObj
}