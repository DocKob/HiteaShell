function Set-HtRegKey {
    [CmdletBinding(
        SupportsShouldProcess = $true
    )]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        $BasePath,
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

    if (!(Test-Path (Join-Path $BasePath "AllMyIT"))) {
        New-Item -Path $BasePath -Name "AllMyIT"
        # New-PSDrive -Name "AllMyCloud" -PSProvider "Registry" -Root "HKLM:\SOFTWARE\AllMyCloud"
    }

    $BasePath = (Join-Path $BasePath "AllMyIT")

    if (Get-ItemProperty -Path $BasePath -Name $Key) {
        Remove-ItemProperty -Path $BasePath -Name $Key -Force
    }
    New-ItemProperty -Path $BasePath -Name $Key -Value $Value -PropertyType $Type

}

function Get-HtRegKey {
    [CmdletBinding(
        SupportsShouldProcess = $true
    )]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        $BasePath,
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
        [Parameter(Mandatory = $true)]
        [string]$BasePath
    )
    $HtRegObj = [PSCustomObject]@{ }
    Push-Location
    Set-Location -Path $BasePath
    Get-Item . |
    Select-Object -ExpandProperty property |
    ForEach-Object {
        $HtRegObj | Add-Member -MemberType NoteProperty -Name $_ -Value (Get-ItemProperty -Path . -Name $_).$_
    }
    Pop-Location
    Return $HtRegObj
}