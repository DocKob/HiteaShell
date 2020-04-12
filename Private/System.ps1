function Test-HtPsRunAs {  
    $user = [Security.Principal.WindowsIdentity]::GetCurrent();
    (New-Object Security.Principal.WindowsPrincipal $user).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)  
}

function Test-HtPsCommand {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Command
    )
 
    $found = $false
    $match = [Regex]::Match($Command, "(?<Verb>[a-z]{3,11})-(?<Noun>[a-z]{3,})", "IgnoreCase")
    if ($match.Success) {
        if (Get-Command -Verb $match.Groups["Verb"] -Noun $match.Groups["Noun"]) {
            $found = $true
        }
    }

    return $found
}

function Restart-HtService {
    Param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]$ServiceName
    )

    [System.Collections.ArrayList]$ServicesToRestart = @()

    function Get-HtDependServices($ServiceInput) {
        If ($ServiceInput.DependentServices.Count -gt 0) {
            ForEach ($DepService in $ServiceInput.DependentServices) {
                If ($DepService.Status -eq "Running") {
                    $CurrentService = Get-Service -Name $DepService.Name
                    if ($ServicesToRestart.Contains($DepService.Name) -eq $false) {
                        Write-Host "Adding service to restart $($DepService.Name)"
                        $ServicesToRestart.Add($DepService.Name)
                    }
                    Get-HtDependServices $CurrentService
                }
                Else {
                    Write-Host "$($DepService.Name) is stopped. No Need to stop or start or check dependancies."
                }

            }
        }
        Write-Host "Service to restart $($ServiceInput.Name)"
        if ($ServicesToRestart.Contains($ServiceInput.Name) -eq $false) {
            Write-Host "Adding service to restart $($ServiceInput.Name)"
            $ServicesToRestart.Add($ServiceInput.Name)
        }
    }

    $Service = Get-Service -Name $ServiceName

    Get-HtDependServices -ServiceInput $Service

    try {
        Write-Host "-------------------------------------------"
        Write-Host "Stopping Services"
        Write-Host "-------------------------------------------"
        foreach ($ServiceToStop in $ServicesToRestart) {
            Write-Host "StopService $ServiceToStop"
            Stop-Service $ServiceToStop -Force -Verbose -ErrorAction Stop
        }
        Write-Host "-------------------------------------------"
        Write-Host "Starting Services"
        Write-Host "-------------------------------------------"

        $ServicesToRestart.Reverse()

        foreach ($ServiceToStart in $ServicesToRestart) {
            Write-Host "StartService $ServiceToStart"
            Start-Service $ServiceToStart -Verbose -ErrorAction Stop
        }
        Write-Host "-------------------------------------------"
        Write-Host "Restart of services completed"
        Write-Host "-------------------------------------------"   
    }
    catch {
        Write-Host "Error: Unable to restart a service" -ForegroundColor Red
    }

}

function Install-HtModules {
    [CmdletBinding(
        SupportsShouldProcess = $true
    )]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        $Modules,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        $Path,
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        $Import = $false
    )

    ForEach ($Module in $Modules) {
        if (-not (Test-Path (Join-Path $Path $Module))) {
            Find-Module -Name $Module -Repository 'PSGallery' | Save-Module -Path $Path -Force | Out-Null
        }
        else {
            Write-Verbose -Message "Module already exists"
        }
        if ($Import -eq $true) {
            Import-Module -FullyQualifiedName (Join-Path $Path $Module)
        }
    }
}

function Set-HtConfigMode {
    [CmdletBinding(
        SupportsShouldProcess = $true
    )]
    Param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [bool]$ConfigMode
    )

    if ($ConfigMode -eq $true) {
        netsh advfirewall set allprofiles state off
        Enable-WSManCredSSP -Role server
    }
    elseif ($ConfigMode -eq $false) {
        netsh advfirewall set allprofiles state on
        Disable-WSManCredSSP -Role Server
    }
}

function Set-HtAccessibility {
    [CmdletBinding(
        SupportsShouldProcess = $true
    )]
    Param()

    Enable-PSRemoting -Force
    winrm quickconfig -q
    Start-Service WinRM
    Set-Service WinRM -StartupType Automatic

}

function Show-HtNotification {
    [CmdletBinding(
        SupportsShouldProcess = $true
    )]
    Param(
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [ValidateSet("Info", "Warning", "Error", "None")]
        [string]$Type,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Title,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Text,
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [int]$Timeout = 10
    )      
            
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing

    $notify = new-object system.windows.forms.notifyicon
    $notify.icon = [system.drawing.icon]::ExtractAssociatedIcon((join-path $pshome powershell.exe))
    $notify.visible = $True

    $notify.showballoontip($Timeout, $title, $text, $type)

    switch ($Host.Runspace.ApartmentState) {
        STA {
            $null = Register-ObjectEvent -InputObject $notify -EventName BalloonTipClosed -Action {
                $Sender.Dispose()
                Unregister-Event $EventSubscriber.SourceIdentifier
                Remove-Job $EventSubscriber.Action
            }
        }
        default {
            continue
        }
    }

}  