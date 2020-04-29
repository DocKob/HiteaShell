function Connect-HtComputerPsSession {
    [CmdletBinding()]
    param(

        [Parameter(
            ValueFromPipeline = $true,
            Mandatory = $true,
            HelpMessage = 'Credentials in AD to access remote computer.'
        )]
        [System.Management.Automation.Credential()]
        [PSCredential]$Credential,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$ComputerName
    )

    try {


    }
    catch {

        Write-Warning -Message ('Unable to enter PSSession - {0}' -f $_.Exception.Message)
        return
    }
    
}