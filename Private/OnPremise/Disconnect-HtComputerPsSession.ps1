function Disconnect-HtComputerPsSession {

    [CmdletBinding()]
    param ()

    try {
        
    }
    catch {

        Write-Warning -Message ('Unable to remove PSSession - {0}' -f $_.Exception.Message)
        return
    }       
}