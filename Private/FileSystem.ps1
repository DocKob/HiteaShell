Function New-HtFolders {
    [CmdletBinding(
        SupportsShouldProcess = $true
    )]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        $Folders,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        $Path
    )
    ForEach ($Folder in $Folders) {
        $location = (Join-Path $Path $Folder)
        if (!(Test-Path $location)) {
            New-Item -Path $location -ItemType Directory | Out-Null
            Write-Verbose -Message "Create folder $($Folder) at location $($location)"
        }
        else {
            Write-Verbose -Message "Folder $($Folder) already exist at location $($location)"
        }
    } 
}

function Remove-HtTemp {
    [CmdletBinding()]
    Param()
    
    $objShell = New-Object -ComObject Shell.Application
    
    $temp = (get-ChildItem "env:\TEMP").Value
    $FoldersList = @($temp, "c:\Windows\Temp\*")

    foreach ($Folder in $FoldersList) {
        write-Host "Removing Junk files in $Folder." -ForegroundColor Magenta 
        Remove-Item -Recurse  "$Folder\*" -Force -Verbose
    }

    write-Host "Emptying Recycle Bin." -ForegroundColor Cyan
    $objFolder = $objShell.Namespace(0xA)
    $objFolder.items() | % { remove-item $_.path -Recurse -Confirm:$false }
	
    write-Host "Finally now , Running Windows disk Clean up Tool" -ForegroundColor Cyan
    cleanmgr /sagerun:1 | out-Null
	
    write-Host "I finished the cleanup task,Bye Bye " -ForegroundColor Yellow

}

function Set-HtCacheFolder {
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        $Path
    )

    If ((Test-Path -Path $Path) -eq $False) {
        #Create the local cache directory
        New-Item -ItemType Directory $Path -Force -Confirm:$False
    }

    $ShareName = Split-Path -Path $Path -Leaf

    New-SmbShare -Name $ShareName -Path $Path -FullAccess Everyone
}

function Set-HtShortcut {
    param (
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        $ShortcutPath = "$env:Public\Desktop\",
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        $ShortcutTarget,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        $ShortcutName
    )

    $Filename = $ShortcutName + ".lnk"
    $WScriptShell = New-Object -ComObject WScript.Shell
    $Shortcut = $WScriptShell.CreateShortcut((Join-Path $ShortcutPath $Filename))
    $Shortcut.TargetPath = $ShortcutTarget
    $Shortcut.Save()
    Write-Host "Shortcut created"
}

function Set-HtSymLink {
    param (
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        $SymlinkPath = "C:\",
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        $SymlinkTarget,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        $SymlinkName
    )
	
    New-Item -Path $SymlinkPath -Name $SymlinkName -ItemType SymbolicLink -Value $SymlinkTarget
    
}

function Set-HtPsDrive {
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        $PsDriveTarget,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        $PsDriveName
    )

    New-PSDrive -Name $PsDriveName -PSProvider FileSystem -Root $PsDriveTarget
    
}

function Compare-HtCsv {
    param (
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        $CsvPath = (Join-Path  (Get-HtRegKey -Key "InstallPath") "Export"),
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        $Csv1,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        $Csv2,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        $Property
    )

    $File1 = Import-Csv -Path (Join-Path $CsvPath $Csv1)
    $File2 = Import-Csv -Path (Join-Path $CsvPath $Csv2)

    $Results = Compare-Object  $File1 $File2 -Property $Property -IncludeEqual
 
    $Array = @()       
    Foreach ($R in $Results) {
        If ( $R.sideindicator -eq "==" ) {
            $Object = [pscustomobject][ordered] @{
 
                Username            = $R.$($Property)
                "Compare indicator" = $R.sideindicator
 
            }
            $Array += $Object
        }
    }
 
    # ($Array | sort-object username | Select-Object * -Unique).count
    return $Array
    
}