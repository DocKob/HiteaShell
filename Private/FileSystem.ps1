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