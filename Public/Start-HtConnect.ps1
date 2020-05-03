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

2: Connect to OnPremise Session

C: Create new cred file

T: Remove Temp

Q: Press Q to exist

"@

    Do {
        Switch (Invoke-HtMenu -menu $WizardMenu -title $MenuTitle -cls) {
            "1" {
                $CommonName = Read-Host "Type a common name to connect "
                $M365Services = Read-Host "TYpe y to connect AzureAD, MSOnline and ExchangeOnline by default, all available: $($HtConfig.M365AvailableServices)"
                $SessionCred = Get-HtCredential -KeyFile $KeyPath -CredFolder $ConfigFolder -CommonName $CommonName
                $ConfigMatch = Confirm-HtConfigurationItem -ConfigurationItem $HtConfig.M365AvailableServices -Item $M365Services
                if (($SessionCred -eq $false) -or ($ConfigMatch -eq $false)) {
                    Write-Warning "Credential: $($SessionCred) - Service: $($ConfigMatch)"
                }
                elseif (($SessionCred -ne $false) -and ($ConfigMatch -eq $true)) {
                    Connect-HtMicrosoft365 -Service $M365Services -Credential $SessionCred
                }
                elseif (($SessionCred -ne $false) -and ([string]::IsNullOrEmpty($ConfigMatch))) {
                    Connect-HtMicrosoft365 -Credential $SessionCred
                }
                pause
                return
            }
            "2" {
                $ComputerName = Read-Host "Type a computer name to connect "
                $OnPremServices = Read-Host "Type y to connect PsSession by default, all available: $($HtConfig.OnPremAvailableServices)"
                $SessionCred = Get-HtCredential -KeyFile $KeyPath -CredFolder $ConfigFolder -CommonName $ComputerName
                $ConfigMatch = Confirm-HtConfigurationItem -ConfigurationItem $HtConfig.OnPremAvailableServices -Item $OnPremServices
                if (($SessionCred -eq $false) -or ($ConfigMatch -eq $false)) {
                    Write-Warning "Credential: $($SessionCred) - Service: $($ConfigMatch)"
                }
                elseif (($SessionCred -ne $false) -and ($ConfigMatch -eq $true)) {
                    Connect-HtOnPremise -Service $OnPremServices -Credential $SessionCred -ComputerName $ComputerName
                }
                elseif (($SessionCred -ne $false) -and ([string]::IsNullOrEmpty($ConfigMatch))) {
                    Connect-HtOnPremise -Credential $SessionCred -ComputerName $ComputerName
                }
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
                Disconnect-HtOnPremise
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