function Import-HtAzCopyPst {
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        $PSTFile,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        $AzureUri,
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        $LogPath = (Join-Path  (Get-HtRegKey -Key "InstallPath") "Cache")
    )

    $AzPath = "C:\Program Files (x86)\Microsoft SDKs\Azure\AzCopy\AzCopy.exe"
    $LogFile = Join-Path $LogPath "AzCopyLog.txt"
 
    if (!(Test-Path $AzPath)) {

        & $AzPath /Source:$PSTFile /Dest:$AzureUri /V:$LogFile /Y
    } 
}