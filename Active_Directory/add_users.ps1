import-module ActiveDirectory

$UserList = Import-Csv -Path 'C:\user_list.csv'
foreach ($User in $UserList) {
    New-ADUser `
    -SamAccountName $User.username `
    -Name "$($User.First) $($User.Last)" `
    -GivenName $($User.First) `
    -Surname $($User.Last) `
    -UserPrincipalName "$($User.username)@team5.isucdc.com" `
    -AccountPassword ($User.password | ConvertTo-SecureString -AsPlainText -Force) `
    -Enabled $true

    if ($User.group) {
        Add-ADGroupMember -Identity $($User.group) -Members $($User.username)
    }
}