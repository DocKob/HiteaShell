function Import-HtAadUsersFromCsv {
    param (     
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        $CsvPath,
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        $ChangePwd = $true
    )

    $users = import-csv $CsvPath | Select-Object *

    foreach ($user in $users) {
        $emailAddress = $user.'Email Address'
        $firstName = $user.'First Name'
        $lastName = $user.'Last Name'
        $displayName = $user.'Display Name'
        $title = $user.'Job Title'
        $department = $user.'Department'
        $officeNumber = $user.'Office Number'
        $officePhone = $user.'Office Phone'
        $mobile = $user.'Mobile Phone'
        $fax = $user.'Fax'
        $address = $user.'Address'
        $city = $user.'City'
        $state = $user.'State or Province'
        $postalCode = $user.'ZIP or Postal Code'
        $country = $user.'Country or Region'
        
        $write = "Importing account " + $emailAddress + " ..."
        Write-Host $write

        Add-MSOnlineUser -Credential $cred -Identity $emailAddress -DisplayName $displayName -FirstName $firstName -LastName $lastName -JobTitle $title -Department $department -OfficeNumber $officeNumber -OfficePhone $officePhone -MobilePhone $mobile -FaxNumber $fax -StreetAddress $address -City $city -StateOrProvince $state -ZipOrPostalCode $postalCode -CountryOrRegion $country

    }
    
}