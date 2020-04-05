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
        $Credential
    )

    $ExchangeSession = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri "https://outlook.office365.com/powershell-liveid/" -Credential $Credential -Authentication "Basic" -AllowRedirection
    Import-PSSession $ExchangeSession
    
}