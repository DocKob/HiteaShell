function Install-HtM365Modules {
    [CmdletBinding(
        SupportsShouldProcess = $true
    )]
    param ()
    
    $Modules = @("Microsoft.Online.SharePoint.PowerShell", "AzureAD", "MicrosoftTeams")

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

function Connect-HtMicrosoft365 {
    [CmdletBinding(
        SupportsShouldProcess = $true
    )]
    param(
        [Parameter(
            ValueFromPipeline = $true,
            Position = 0
        )]
        [ValidateSet('AllServices', 'AzureAD', 'ComplianceCenter', 'ExchangeOnline', 'ExchangeOnlineProtection', 'MSOnline', 'SharepointOnline' , 'SkypeforBusinessOnline')]
        [ValidateNotNullOrEmpty()]
        [string[]]$Service = @('AzureAD', 'MSOnline', 'ExchangeOnline'),
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [pscredential]$Credential
    )

    dynamicparam {

        if ($Service -match 'AllServices|SharepointOnline') {

            # Create a Parameter Attribute Object
            $SPAttrib = New-Object -TypeName System.Management.Automation.ParameterAttribute
            $SPAttrib.Position = 1
            $SPAttrib.Mandatory = $true            
            $SPAttrib.HelpMessage = 'Enter a valid Sharepoint Online Domain. Example: "Contoso"'
            
            # Create an Alias Attribute Object for the parameter
            $SPAlias = New-Object -TypeName System.Management.Automation.AliasAttribute -ArgumentList @('Domain', 'DomainHost', 'Customer')

            # Create an AttributeCollection Object
            $SPCollection = New-Object -TypeName System.Collections.ObjectModel.Collection[System.Attribute]
                       
            # Add the attributes and aliases to the Attribute Collection
            $SPCollection.Add($SPAttrib)
            $SPCollection.Add($SPAlias)
            
            # Add the SharepointDomain paramater to the "Runtime"
            $SPParam = New-Object -TypeName System.Management.Automation.RuntimeDefinedParameter -ArgumentList ('SharepointDomain', [string], $SPCollection)
            
            # Expose the parameter
            $SPParamDictionary = New-Object -TypeName System.Management.Automation.RuntimeDefinedParameterDictionary
            $SPParamDictionary.Add('SharepointDomain', $SPParam)
            return $SPParamDictionary
        }
    }
    begin {
        
        $EOPExclusive = 'Will not use Exchange Online Protection. EOP and EO are mutually exclusive.'

        # Sorting all input strings from the Service parameter to avoid duplicates.
        if (([Collections.ArrayList]@($Service = $Service | Sort-Object -Unique)).Count -gt 6 -or $Service -match 'AllServices') {
            $Service = 'AllServices'
            Write-Verbose -Message $EOPExclusive
        }
        
        if ($Service -match 'ExchangeOnline' -and $Service -match 'ExchangeOnlineProtection') {
            Write-Verbose -Message $EOPExclusive
            $Service.Remove('ExchangeOnlineProtection')
        }

        if ($Credential -eq $false) {

            Write-Warning -Message 'Need valid credentials to connect, please provide the correct credentials.'
            break
        }    
    }
    process {

        foreach ($s in $Service) {
            
            if ($PSCmdlet.ShouldProcess('Establishing a PowerShell session to {0} - Office 365.' -f ('{0}' -f $s), $MyInvocation.MyCommand.Name)) {
                
                switch ($s) {

                    'AzureAD' {
                        Write-Verbose -Message 'Conncting to AzureAD.' -Verbose
                        $Credential | Connect-AzureADOnline
                    }
                    'MSOnline' {
                        Write-Verbose -Message 'Conncting to MSolService.' -Verbose
                        $Credential | Connect-MsolServiceOnline
                    }
                    'ComplianceCenter' {
                        Write-Verbose -Message 'Conncting to Compliance Center.' -Verbose
                        $Credential | Connect-CCOnline
                    }
                    'ExchangeOnline' {
                        Write-Verbose -Message 'Conncting to Exchange Online.' -Verbose
                        $Credential | Connect-ExchangeOnline
                    }
                    'ExchangeOnlineProtection' {
                        Write-Verbose -Message 'Conncting to Exchange Online Protection.' -Verbose
                        $Credential | Connect-ExchangeOnlineProt
                    }
                    'SharepointOnline' {
                        Write-Verbose -Message 'Conncting to Sharepoint Online.' -Verbose
                        $Credential | Connect-SPOnline -SharepointDomain $PSBoundParameters['SharepointDomain']
                    }
                    'SkypeforBusinessOnline' {
                        Write-Verbose -Message 'Conncting to Skype for Business Online.' -Verbose
                        $Credential | Connect-SfBOnline
                    }
                    Default {
                        Write-Verbose -Message 'Connecting to all Office 365 Services.' -Verbose
                        $Credential | Connect-AzureADOnline
                        $Credential | Connect-MsolServiceOnline
                        $Credential | Connect-CCOnline
                        $Credential | Connect-ExchangeOnline
                        $Credential | Connect-SPOnline -SharepointDomain $PSBoundParameters['SharepointDomain']
                        $Credential | Connect-SfBOnline
                    }
                }
            }
        }
    }
    end {

        Remove-Variable -Name Credential -ErrorAction SilentlyContinue
    }
}

function Disconnect-HtMicrosoft365 {
    [CmdletBinding(
        SupportsShouldProcess = $true
    )]
    param(
        [Parameter(
            ValueFromPipeline = $true            
        )]
        [ValidateSet('AllServices', 'AzureAD', 'ComplianceCenter', 'ExchangeOnline', 'ExchangeOnlineProtection', 'MSOnline', 'SharepointOnline' , 'SkypeforBusinessOnline')]
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

            if ($PSCmdlet.ShouldProcess('End the PowerShell session for {0} - Office 365.' -f ('{0}' -f $s), $MyInvocation.MyCommand.Name)) {

                switch ($s) {

                    'AzureAD' {
                        Write-Verbose -Message 'Disconnecting from AzureAD.' -Verbose
                        Disconnect-AzureADOnline
                    }
                    'MSOnline' {
                        Write-Verbose -Message 'Disconnecting from MsolService.' -Verbose
                        Disconnect-MsolServiceOnline
                    }
                    'ComplianceCenter' {
                        Write-Verbose -Message 'Disconnecting from Compliance Center.' -Verbose
                        Disconnect-CCOnline
                    }
                    'ExchangeOnline' {
                        Write-Verbose -Message 'Disconnecting from Exchange Online.' -Verbose
                        Disconnect-ExchangeOnline
                    }
                    'ExchangeOnlineProtection' {
                        Write-Verbose -Message 'Disconnecting from Exchange Online Protection.' -Verbose
                        Disconnect-ExchangeOnlineProt
                    }
                    'SharepointOnline' {
                        Write-Verbose -Message 'Disconnecting from Sharepoint Online.' -Verbose
                        Disconnect-SPOnline
                    }
                    'SkypeforBusinessOnline' {
                        Write-Verbose -Message 'Disconnecting from Skype for Business Online.' -Verbose
                        Disconnect-SfBOnline
                    }
                    Default {
                        Write-Verbose -Message 'Disconnecting from all Office 365 Services.' -Verbose
                        Disconnect-AzureADOnline
                        Disconnect-MsolServiceOnline
                        Disconnect-CCOnline
                        Disconnect-ExchangeOnline
                        Disconnect-ExchangeOnlineProt
                        Disconnect-SPOnline
                        Disconnect-SfBOnline
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