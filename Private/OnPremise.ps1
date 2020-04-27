function Get-HtComputerReport {
    param (
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        $SearchBase = "CN=Computers,DC=Domain,DC=local",
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        $CommonName
    )

    $AdComputers = Get-ADComputer -Filter * -Property * -SearchBase $SearchBase | Select-Object Name, OperatingSystem, OperatingSystemVersion, ipv4Address

    $Day = (Get-Date).Day
    $Month = (Get-Date).Month
    $Year = (Get-Date).Year
    $ExportPath = (Join-Path  (Get-HtRegKey -Key "InstallPath") "Export")
    $ReportName = ( "$Month" + "-" + "$Day" + "-" + "$Year" + "-" + $CommonName + "-Computer_Report")
    $AdComputers | Export-CSV (Join-Path $ExportPath $ReportName) -NoTypeInformation -Encoding UTF8 -Delimiter ";"
}