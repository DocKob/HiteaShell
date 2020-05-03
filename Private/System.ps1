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

function Set-HtWinTermBackup {
    [CmdletBinding(SupportsShouldProcess)]
    Param(
        [int]$Limit = 7,
        [parameter(Mandatory = $true, HelpMessage = "Specify the backup location")]
        [ValidateScript( { Test-Path $_ })]
        [string]$Destination
    )

    $json = "$ENV:Userprofile\AppData\Local\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
    #$json = "$ENV:Userprofile\OneDrive\windowsterminal\settings.json"

    Write-Verbose "Backing up $json to $Destination"
    Write-Verbose "Get existing backups and save as an array sorted by name"

    [array]$bak = Get-ChildItem -path $Destination -Name settings.bak*.json | Sort-Object -Property name

    if ($bak.count -eq 0) {
        Write-Verbose "Creating first backup copy."
        [int]$new = 1
    }
    else {
        #get the numeric value
        [int]$counter = ([regex]"\d+").match($bak[-1]).value
        Write-Verbose "Last backup is #$counter"

        [int]$new = $counter + 1
        Write-Verbose "Creating backup copy $new"
    }

    $backup = Join-Path -path $Destination -ChildPath "settings.bak$new.json"
    Write-Verbose "Creating backup $backup"
    Copy-Item -Path $json -Destination $backup

    #update the list of backups sorted by age and delete extras
    Write-Verbose "Removing any extra backup files over the limit of $Limit"

    Get-ChildItem -path $Destination\settings.bak*.json | 
    Sort-Object -Property LastWriteTime -Descending |
    Select-Object -Skip $Limit | Remove-Item

    #renumber backup files
    Write-Verbose "Renumbering backup files"

    Get-ChildItem -path $Destination\settings.bak*.json | 
    Sort-Object -Property LastWriteTime |
    ForEach-Object -Begin { $n = 0 } -process {
        #rename each file with a new number
        $n++
        $temp = Join-Path -path $env:TEMP -ChildPath "settings.bak$n.json"

        Write-Verbose "Copying temp file to $temp"
        $_ | Copy-Item -Destination $temp

        Write-Verbose "Removing $($_.name)"
        $_ | Remove-Item

    } -end {
        Write-Verbose "Restoring temp files to $Destination"
        Get-ChildItem -Path "$env:TEMP\settings.bak*.json" | Move-Item -Destination $Destination
    }

    Get-ChildItem -path $Destination\settings.bak*.json | Sort-Object -Property LastWriteTime -Descending

}
