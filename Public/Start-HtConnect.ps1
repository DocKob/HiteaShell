function Start-HtConnect {
    [CmdletBinding(
        SupportsShouldProcess = $true
    )]
    param ()
    
    if (!(Test-Path "$($BaseFolder)/Config/Installed.txt") ) {
        Install-HtBase
    }
    else {
        Write-Host "Install folder is Already created !"
        $Config = Import-HtConfiguration -ProfilePath "$($BaseFolder)/Config/Install_Default.json"
    }

    $ConfigFolder = Join-Path $Config.BasePath "Config"
    if (!(Test-Path (Join-Path $ConfigFolder "aes.key") -ErrorAction SilentlyContinue)) {
        $KeyPath = Set-HtCryptKey -Path $ConfigFolder
    }
    else {
        $KeyPath = Join-Path $ConfigFolder "aes.key"
    }

    $RunConfig = Import-HtConfiguration -ProfilePath "$($BaseFolder)/Config/Config_Default.json"

    $MenuTitle = " Start HtConnect"
    $WizardMenu = @"

1: Enter MSOL Session

2: Enter Exchange Session

3: Enter Teams Session

C: Create new cred file

T: Remove Temp

Q: Press Q to exist

"@

    Do {
        Switch (Invoke-HtMenu -menu $WizardMenu -title $MenuTitle) {
            "1" {
                $CommonName = Read-Host "Type a common name to connect "
                $SessionCred = Get-HtCredential -KeyFile $KeyPath -CredFolder $ConfigFolder -CommonName $CommonName
                Connect-HtMsol -Credential $SessionCred
                return
            }
            "2" {
                $CommonName = Read-Host "Type a common name to connect "
                $ActivesSessions = Get-HtPsSession
                if ([bool]($ActivesSessions.Name -match ("HT_EXCH_" + $CommonName))) {
                    Write-Verbose "A session already exist !"
                }
                else {
                    Write-Verbose "Create a new session !"
                    $SessionCred = Get-HtCredential -KeyFile $KeyPath -CredFolder $ConfigFolder -CommonName $CommonName
                    Connect-HtExchange -Credential $SessionCred -SessionName $CommonName
                }
                return
            }
            "3" {
                $CommonName = Read-Host "Type a common name to connect "
                $SessionCred = Get-HtCredential -KeyFile $KeyPath -CredFolder $ConfigFolder -CommonName $CommonName
                Connect-HtTeams -Credential $SessionCred
                return
            }
            "C" {
                Set-HtCredential -KeyFile $KeyPath -CredFolder $ConfigFolder
            }
            "T" {
                Remove-HtTemp
            }
            "Q" {
                Read-Host "Closing..., press enter"
                Get-PSSession | Remove-PSSession
                Clear-Host
                Return
            }
            Default {
                Clear-Host
                Start-Sleep -milliseconds 100 
            }
        } 
    } While ($True)
}