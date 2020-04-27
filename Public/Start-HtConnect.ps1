function Start-HtConnect {
    [CmdletBinding(
        SupportsShouldProcess = $true
    )]
    param (        
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string]$CustomConfig = "$($BaseFolder)/Config/Install_Default.json"
    )

    if (!(Test-HtPsRunAs)) {
        Write-Host "You must launch HtShell as admin, exit..."
        pause
        exit
    }
    
    if (!(Test-Path ("HKLM:\SOFTWARE\HiteaNet\HtShell")) -or !(Test-Path "$($BaseFolder)/Config/Installed.txt")) {
        Install-HtBase -InstallDefault $CustomConfig
    }
    else {
        Write-Host "Install folder is Already created !"
    }

    $HtConfig = Import-HtConfiguration -ProfilePath "$($BaseFolder)/Config/Config_Default.json"
    $HtReg = Get-HtRegObj

    $ConfigFolder = Join-Path $HtReg.("InstallPath") "Config"
    if (!(Test-Path (Join-Path $ConfigFolder "aes.key") -ErrorAction SilentlyContinue)) {
        $KeyPath = Set-HtCryptKey -Path $ConfigFolder
    }
    else {
        $KeyPath = Join-Path $ConfigFolder "aes.key"
    }

    $MenuTitle = " Start HtConnect"
    $WizardMenu = @"

1: Connect to Microsoft 365

C: Create new cred file

T: Remove Temp

Q: Press Q to exist

"@

    Do {
        Switch (Invoke-HtMenu -menu $WizardMenu -title $MenuTitle -cls) {
            "1" {
                $CommonName = Read-Host "Type a common name to connect "
                $SessionCred = Get-HtCredential -KeyFile $KeyPath -CredFolder $ConfigFolder -CommonName $CommonName
                $Services = Read-Host "Choose services to connect. AzureAD, MSOnline and ExchangeOnline by default, all available: $($HtConfig.AvailableServices)"
                Connect-HtMicrosoft365 -Credential $SessionCred
                pause
                return
            }
            "C" {
                Set-HtCredential -KeyFile $KeyPath -CredFolder $ConfigFolder
                pause
            }
            "T" {
                Remove-HtTemp
                pause
            }
            "Q" {
                Read-Host "Closing..., press enter"
                Disconnect-HtMicrosoft365
                pause
                Return
            }
            Default {
                Clear-Host
                Start-Sleep -milliseconds 100 
            }
        } 
    } While ($True)
}