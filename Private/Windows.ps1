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