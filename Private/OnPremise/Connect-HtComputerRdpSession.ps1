function Connect-HtComputerRdpSession {
    [CmdletBinding(
        SupportsShouldProcess = $true
    )]
    param(
        [Parameter(Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            Position = 0)]
        [string[]]     $ComputerName,
        [Parameter(
            ValueFromPipeline = $true,
            Mandatory = $true,
            HelpMessage = 'Credentials in AD to access RDP computer.'
        )]
        [System.Management.Automation.Credential()]
        [Parameter(ParameterSetName = 'Credential', Mandatory = $true, Position = 1)]
        [PSCredential]$Credential,
        [Alias('A')]
        [switch]       $Admin,
        [Alias('MM')]
        [switch]       $MultiMon,
        [Alias('F')]
        [switch]       $FullScreen,
        [Alias('Pu')]
        [switch]       $Public,
        [Alias('W')]
        [int]          $Width,
        [Alias('H')]
        [int]          $Height,
        [Alias('WT')]
        [switch]       $Wait
    )

    begin {
        [string]$MstscArguments = ''
        switch ($true) {
            { $Admin } { $MstscArguments += '/admin ' }
            { $MultiMon } { $MstscArguments += '/multimon ' }
            { $FullScreen } { $MstscArguments += '/f ' }
            { $Public } { $MstscArguments += '/public ' }
            { $Width } { $MstscArguments += "/w:$Width " }
            { $Height } { $MstscArguments += "/h:$Height " }
        }

    }
    process {
        foreach ($Computer in $ComputerName) {
            $ProcessInfo = New-Object System.Diagnostics.ProcessStartInfo
            $Process = New-Object System.Diagnostics.Process
            
            if ($Computer.Contains(':')) {
                $ComputerCmdkey = ($Computer -split ':')[0]
            }
            else {
                $ComputerCmdkey = $Computer
            }
            
            $ProcessInfo.FileName = "$($env:SystemRoot)\system32\cmdkey.exe"
            $ProcessInfo.Arguments = "/generic:TERMSRV/$ComputerCmdkey /user:$($Credential.Username) /pass:$($Credential.Password)"
            $ProcessInfo.WindowStyle = [System.Diagnostics.ProcessWindowStyle]::Hidden
            $Process.StartInfo = $ProcessInfo
            if ($PSCmdlet.ShouldProcess($ComputerCmdkey, 'Adding credentials to store')) {
                [void]$Process.Start()
            }

            try {
                $ProcessInfo.FileName = "$($env:SystemRoot)\system32\mstsc.exe"
                $ProcessInfo.Arguments = "$MstscArguments /v $Computer"
                $ProcessInfo.WindowStyle = [System.Diagnostics.ProcessWindowStyle]::Normal
                $Process.StartInfo = $ProcessInfo
                if ($PSCmdlet.ShouldProcess($Computer, 'Connecting mstsc')) {
                    [void]$Process.Start()
                    if ($Wait) {
                        $null = $Process.WaitForExit()
                    }       
                }
            }
            catch {

                Write-Warning -Message ('Unable to enter RDP session - {0}' -f $_.Exception.Message)
                return
            }
        }
    }
}