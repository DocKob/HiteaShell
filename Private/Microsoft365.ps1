function Install-HtM365Modules {
    param ()
    
    $Modules = @("Microsoft.Online.SharePoint.PowerShell", "AzureAD", "MicrosoftTeams")

    ForEach ($Module in $Modules) {
        Install-Module -Name $Module -Force -Verbose
    }

}

function Connect-HtExchange {
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        $Credential,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        $SessionName
    )

    $HtSessionName = "HT_EXCH_" + $SessionName
    $ExchangeSession = New-PSSession -Name $HtSessionName -ConfigurationName Microsoft.Exchange -ConnectionUri "https://outlook.office365.com/powershell-liveid/" -Credential $Credential -Authentication "Basic" -AllowRedirection
    Import-Module (Import-PSSession $ExchangeSession -AllowClobber -DisableNameChecking) -Global
}

function Connect-HtMsol {
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        $Credential,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        $SessionName
    )

    $HtSessionName = "HT_MSOL_" + $SessionName
    Connect-MsolService -Credential $Credential -ErrorAction Stop -WarningAction SilentlyContinue | Out-Null
}

function Connect-HtTeams {
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        $Credential,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        $SessionName
    )

    $HtSessionName = "HT_TEAMS_" + $SessionName
    Connect-MicrosoftTeams -Credential $Credential | Out-Null
}

function Get-HtPsSession {
    param (
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [ValidateSet("ALL", "EXCH")]
        $SessionType = "ALL"
    )
    
    if ($SessionType -eq "ALL") {
        $HtSession = Get-PSSession | Where-Object { $_.Name -like "HT_*" }
    }
    else {
        $HtSession = Get-PSSession | Where-Object { $_.Name -like "HT_EXCH_*" }
    }
    
    return $HtSession
}