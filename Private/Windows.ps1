function Get-HtOsVersion {

    try {
        $OsInfos = Get-CimInstance -ClassName Win32_Operatingsystem -ErrorAction Stop
    }
    catch {
        Write-Host "Error: Unable to get OS type" -ForegroundColor Red
    }
    return $OsInfos.ProductType

}

function New-HtLocalAdmin {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Name,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Password
    )

    $Group = "Administrateurs"

    try {
        Get-LocalUser -Name $Name -ErrorAction Stop
        Write-Host "User already exist, reseting the password..." -ForegroundColor Yellow
        Set-LocalUser -Name $Name -Password (ConvertTo-SecureString -AsPlainText $Password -Force)
    }
    catch {
        try {
            New-LocalUser -Name $Name -Password (ConvertTo-SecureString -AsPlainText $Password -Force) -FullName $Name -Description "Created date: $(Get-Date)" -ErrorAction Stop
            Write-Host "User created" -ForegroundColor Green
        }
        catch {
            Write-Host "Error: User not created" -ForegroundColor Red
        }
    }
    try {
        Add-LocalGroupMember -Group $Group -Member $Name -ErrorAction Stop
    }
    catch {
        Write-Host "Error: Unable to add the user to admin group" -ForegroundColor Red
    }

}

function Test-HtLocalGroupMember {
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Name,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Group
    )

    try {
        $GroupMembers = Get-LocalGroupMember -Group $Group -ErrorAction Stop
        if ($GroupMembers -match $Name) {
            return $true
        }
        else {
            return $false
        }
    }
    catch {
        Write-Host "Group doesn't exist"
    }
    
}

function Install-HtFeatures {
    [CmdletBinding(
        SupportsShouldProcess = $true
    )]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [array]$Features
    )

    if (! (Test-HtPsCommand -Command "Install-WindowsFeature")) {
        Write-Verbose -Message "Device is not a server ! Exit"
    }
    else {
        $InstalledFeatures = Get-WindowsFeature | Where-Object InstallState -eq "Installed"

        foreach ($Feature in $Features) {
    
            if (!($InstalledFeatures.Name -match $Feature)) {
                Write-Host "Installing $Feature"
                Install-WindowsFeature $Feature
            }
            else {
                Write-Host "Feature $Feature is already installed"
            }
        } 
    }
}

Function Get-HtDeviceInfos {
    [CmdletBinding(
        SupportsShouldProcess = $true
    )]
    param(
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string]$Export = $null
    )
    <# DynamicParam {
        if ($Export -ne $null) {
            $ageAttribute = New-Object System.Management.Automation.ParameterAttribute
            $ageAttribute.Mandatory = $true
            $ageAttribute.HelpMessage = "Provide a folder path to export CSV file: "
 
            $attributeCollection = new-object System.Collections.ObjectModel.Collection[System.Attribute]

            $attributeCollection.Add($ageAttribute)
 
            $ageParam = New-Object System.Management.Automation.RuntimeDefinedParameter('ExportPath', [string], $attributeCollection)
 
            $paramDictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
            $paramDictionary.Add('ExportPath', $ageParam)
            return $paramDictionary 
        }
    } #>

    Process {
        $os = Get-WmiObject -class win32_operatingsystem | Select-Object *
        $pc = Get-WmiObject -Class Win32_ComputerSystem | Select-Object *
        $pf = Get-CimInstance -Class Win32_PageFileUsage | Select-Object *

        $DeviceInfo = @{ }
        $DeviceInfo.add("OperatingSystem", $os.name.split("|")[0])
        $DeviceInfo.add("Version", $os.Version)
        $DeviceInfo.add("Architecture", $os.OSArchitecture)
        $DeviceInfo.add("SerialNumber", $os.SerialNumber)
        $DeviceInfo.add("PsVersion", [string]($PSVersionTable.PSVersion.Major) + "." + [string]($PSVersionTable.PSVersion.Minor))

        $DeviceInfo.add("SystemName", $env:COMPUTERNAME)
        $DeviceInfo.add("Domain", $pc.PartOfDomain)
        $DeviceInfo.add("WorkGroup", $pc.Workgroup)
        $DeviceInfo.add("CurrentUserName", $env:UserName)

        $PageFileStats = [PSCustomObject]@{
            Computer              = $computer
            FilePath              = $pf.Description
            AutoManagedPageFile   = $pc.AutomaticManagedPagefile
            "TotalSize(in MB)"    = $pf.AllocatedBaseSize
            "CurrentUsage(in MB)" = $pf.CurrentUsage
            "PeakUsage(in MB)"    = $pf.PeakUsage
            TempPageFileInUse     = $pf.TempPageFile
        }

        $DeviceInfo.add("PageFileSize", $PageFileStats.("TotalSize(in MB)"))
        $DeviceInfo.add("PageFileCurrentSize", $PageFileStats.("CurrentUsage(in MB)"))
        $DeviceInfo.add("PageFilePeakSize", $PageFileStats.("PeakUsage(in MB)"))

        $out += New-Object PSObject -Property $DeviceInfo | Select-Object `
            "SystemName", "SerialNumber", "OperatingSystem", `
            "Version", "Architecture", "PageFileSize", "PageFileCurrentSize", "PageFilePeakSize", "PsVersion", "Domain", "WorkGroup", "CurrentUserName"

        if ($Export -ne $null) {
            Write-Verbose -Message "Config file exported in export folder"
            $out | Export-CSV -Path (Join-Path $Export "Device_Infos.csv") -Delimiter ";" -NoTypeInformation
        }
        else {
            return $out
        }
    }
}

function Install-HtChocolatey {
    [CmdletBinding(
        SupportsShouldProcess = $true
    )]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [array]$Apps
    )
    If (!(Test-Path -Path "$env:ProgramData\Chocolatey")) {
        Set-ExecutionPolicy Bypass -Scope Process -Force; Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
    }

    ForEach ($PackageName in $Apps) {
        choco install $PackageName -y
    }
}

function Install-HtBlob {
    param (
        [System.String]$ZipSourceFiles = "",
        [system.string]$IntuneProgramDir = "$env:APPDATA\Intune",
        [System.String]$FullEXEDir = "$IntuneProgramDir\Folder\setup.exe",
        [System.String]$ZipLocation = "$IntuneProgramDir\Package.zip",
        [System.String]$TempNetworkZip = "\\Server\Intune$\Package.zip",
        [System.Boolean]$Lnk = $false
    )
    If ((Test-Path $TempNetworkZip) -eq $False) {
        #Start download of the source files from Azure Blob to the network cache location
        Start-BitsTransfer -Source $ZipSourceFiles -Destination $TempNetworkZip

        #Check to see if the local cache directory is present
        If ((Test-Path -Path $IntuneProgramDir) -eq $False) {
            #Create the local cache directory
            New-Item -ItemType Directory $IntuneProgramDir -Force -Confirm:$False
        }

        #Copy the binaries from the network cache to the local computer cache
        Copy-Item $TempNetworkZip -Destination $IntuneProgramDir  -Force
    
        #Extract the install binaries
        Expand-Archive -Path $ZipLocation -DestinationPath $IntuneProgramDir -Force

        #Install the program
        Start-Process "$FullEXEDir" -ArgumentList "ARGS"
    }
    Else {
        #Check to see if the local cache directory is present
        If ((Test-Path -Path $IntuneProgramDir) -eq $False) {
            #Create the local cache directory
            New-Item -ItemType Directory $IntuneProgramDir -Force -Confirm:$False
        }

        #Copy the installer binaries from the network cache location to the local computer cache
        Copy-Item $TempNetworkZip -Destination $IntuneProgramDir  -Force
    
        #Extract the install binaries
        Expand-Archive -Path $ZipLocation -DestinationPath $IntuneProgramDir -Force

        #Install the program
        Start-Process "$FullEXEDir" -ArgumentList "ARGS"
    }

    if ($Lnk -eq $true) {
        $ShortcutFile = "$env:Public\Desktop\" + $OutputFile.name + ".lnk"
        $WScriptShell = New-Object -ComObject WScript.Shell
        $Shortcut = $WScriptShell.CreateShortcut($ShortcutFile)
        $Shortcut.TargetPath = (Join-Path "PATH" ("\temp\" + $OutputFile))
        $Shortcut.Save()
        Write-Host "Shortcut created"
    }
}