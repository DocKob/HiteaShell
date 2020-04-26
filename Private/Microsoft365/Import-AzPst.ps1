function Import-AzPst {
    param ()

    cd "C:\Program Files (x86)\Microsoft SDKs\Azure\AzCopy"
 
    $PSTFile = "\\SRV01\PSTImport"
    $AzureStore = "AZ_BLOB_URL"
    $LogFile = "C:\importPST.txt"
 
    & .\AzCopy.exe /Source:$PSTFile /Dest:$AzureStore /V:$LogFile /Y
    
}