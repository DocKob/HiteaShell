function Get-HtComputerReport {
    param (
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        $SearchBase = "CN=Computers,DC=Domain,DC=local",
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        $Export = "Filename.csv"
    )

    $AdComputers = Get-ADComputer -Filter * -Property * -SearchBase $SearchBase | Select-Object Name, OperatingSystem, OperatingSystemVersion, ipv4Address

    $AdComputers | Export-CSV (Join-Path  (Get-HtRegKey -Key "InstallPath") $Export) -NoTypeInformation -Encoding UTF8 -Delimiter ";"
}