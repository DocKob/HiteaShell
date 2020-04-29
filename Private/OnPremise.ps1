function Install-HtOnPremModules {
    [CmdletBinding(
        SupportsShouldProcess = $true
    )]
    param ()
    
    $Modules = @("")

    ForEach ($Module in $Modules) {
        $IsInstalled = Get-Module -ListAvailable -Name $Module -ErrorAction SilentlyContinue
        if (! [bool]($IsInstalled.Name -match $Module)) {
            Install-Module -Name $Module -Force -Verbose
        }
        else {
            Write-Verbose "Module Already Installed"
        }
    }

}

function Connect-HtOnPremise {
    [CmdletBinding(
        SupportsShouldProcess = $true
    )]
    param(
        [Parameter(
            ValueFromPipeline = $true,
            Position = 0
        )]
        [ValidateSet('AllServices', 'PsSession', 'Rdp')]
        [ValidateNotNullOrEmpty()]
        [string[]]$Service = @('PsSession'),
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [pscredential]$Credential,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$ComputerName
    )

    begin {

        # Sorting all input strings from the Service parameter to avoid duplicates.
        if (([Collections.ArrayList]@($Service = $Service | Sort-Object -Unique)).Count -gt 6 -or $Service -match 'AllServices') {
            $Service = 'AllServices'
        }

        if ($Credential -eq $false) {

            Write-Warning -Message 'Need valid credentials to connect, please provide the correct credentials.'
            break
        }    
    }
    process {

        foreach ($s in $Service) {
            
            if ($PSCmdlet.ShouldProcess('Establishing a PowerShell session to {0}.' -f ('{0}' -f $s), $MyInvocation.MyCommand.Name)) {
                
                switch ($s) {

                    'PsSession' {
                        Write-Verbose -Message 'Connecting to Computer PsSession.' -Verbose
                        Connect-HtComputerPsSession -Credential $Credential -ComputerName $ComputerName
                    }
                    'Rdp' {
                        Write-Verbose -Message 'Connecting to RDP.' -Verbose
                        Connect-HtComputerRdpSession -Credential $Credential -ComputerName $ComputerName
                    }
                    Default {
                        Write-Verbose -Message 'Connecting to all OnPremise Services.' -Verbose
                        Connect-HtComputerPsSession -Credential $Credential -ComputerName $ComputerName
                        Connect-HtComputerRdpSession -Credential $Credential -ComputerName $ComputerName
                    }
                }
            }
        }
    }
    end {

        Remove-Variable -Name Credential -ErrorAction SilentlyContinue
    }
}

function Disconnect-HtOnPremise {
    [CmdletBinding(
        SupportsShouldProcess = $true
    )]
    param(
        [Parameter(
            ValueFromPipeline = $true            
        )]
        [ValidateSet('AllServices', 'PsSession', 'Rdp')]
        [ValidateNotNullOrEmpty()]
        [string[]]$Service = @('AllServices')
    )
    begin {

        if (($service = $Service | Sort-Object -Unique).Count -gt 6) {
            $Service = 'AllServices'
        }
    }
    process {

        foreach ($s in $Service) {

            if ($PSCmdlet.ShouldProcess('End the PowerShell session for {0}.' -f ('{0}' -f $s), $MyInvocation.MyCommand.Name)) {

                switch ($s) {

                    'PsSession' {
                        Write-Verbose -Message 'Disconnecting from Computer PsSession.' -Verbose
                        Disconnect-HtComputerPsSession
                    }
                    'Rdp' {
                        Write-Verbose -Message 'Disconnecting from RDP.' -Verbose
                        Disconnect-HtComputerRdpSession
                    }
                    Default {
                        Write-Verbose -Message 'Disconnecting from all Office 365 Services.' -Verbose
                        Disconnect-HtComputerPsSession
                        Disconnect-HtComputerRdpSession
                    }
                }
                
            }
        }
    }
    end {

        # If the saved credentials variables for some reason is not removed we remove them again.
        Remove-Variable -Name Credential -ErrorAction SilentlyContinue
    }
}