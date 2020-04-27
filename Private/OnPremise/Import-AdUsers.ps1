function Import-HtAdUsersFromCsv {
    param (     
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        $AdDomain, 
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        $CsvPath,
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        $ChangePwd = $true, 
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        $NotExpirePwd = $false,
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        $LockPwd = $false
    )
    
    Import-Module activedirectory
  
    $ADUsers = Import-csv $CsvPath -Delimiter ";"

    foreach ($User in $ADUsers) {	
        $Username = $User.username
        $Password = $User.password
        $Firstname = $User.firstname
        $Lastname = $User.lastname
        $OU = $User.ou
        $email = $User.email
        $streetaddress = $User.streetaddress
        $city = $User.city
        $state = $User.state
        $telephone = $User.telephone
        $jobtitle = $User.jobtitle
        $company = $User.company
        $department = $User.department
        $Password = $User.Password


        if (Get-ADUser -F { SamAccountName -eq $Username }) {
            Write-Warning "A user account with username $Username already exist in Active Directory."
        }
        else {
            New-ADUser `
                -SamAccountName $Username `
                -UserPrincipalName "$Username@$AdDomain" `
                -Name "$Firstname $Lastname" `
                -GivenName $Firstname `
                -Surname $Lastname `
                -Enabled $True `
                -DisplayName "$Firstname $Lastname" `
                -Path $OU `
                -City $city `
                -Company $company `
                -State $state `
                -StreetAddress $streetaddress `
                -OfficePhone $telephone `
                -EmailAddress $email `
                -Title $jobtitle `
                -Department $department `
                -AccountPassword (convertto-securestring $Password -AsPlainText -Force) -ChangePasswordAtLogon $ChangePwd `
                -PasswordNeverExpires $NotExpirePwd `
                -CannotChangePassword $LockPwd
        }
    }
}