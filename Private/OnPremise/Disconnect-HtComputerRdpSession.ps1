function Disconnect-HtComputerRdpSession {

    [CmdletBinding()]
    param ()

    try {
        
    }
    catch {

        Write-Warning -Message ('Unable to remove RDP session - {0}' -f $_.Exception.Message)
        return
    }       
}