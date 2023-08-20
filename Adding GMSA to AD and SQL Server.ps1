## Setting up GMSA for SQL Servers

## ---------------------------------------------------------------- ##
## Run this on DOMAIN CONTROLLER
## ---------------------------------------------------------------- ##

## Run this once to import the module
Import-module activedirectory
Get-KdsRootKey
## if you aren't a Domain Admin, your DA MUST run this
#if doesn't return anything, then run this    ---    Add-KdsRootKey -EffectiveImmediately
## Create the new GMSA Group (Can be added manually) ##
## Add SQL server Computer objects as group members ##

$groupName = 'Svc_GMSA_SQL' ## replace this value with new gMSA group name  
$groupPath = 'OU=Service Account Groups,OU=Groups,DC=contoso,DC=com' ## Replace with actual AD OU
$groupSAMAccountName = 'Svc_GMSA_SQL' ## must be less than 15 chars

New-ADGroup -Name "$groupName" -SamAccountName $groupSAMAccountName -GroupCategory Security -GroupScope Global -DisplayName "$groupName" -Path "$groupPath" -Description "Members of this group are for gMSA"

## Checking whether organizational unit exists, if not create it.(Not really necessary)
$ous = dsquery ou "$adOU"
if ($ous.count -eq 0) {
    dsadd ou "$adOU"
}


## Create a Group Managed Service Account ##

<#
Run this script to create the following users:
1. svc_GmsaSqlDS (Database Services)
2. svc_GmsaSqlAS (Agent Services)
3. svc_GmsaSqlIS (Integration Services)
4. svc_GmsaSqlRS (Reporting Services)
4. svc_GmsaSqlAN (Analysis Services)
#>

$gMSAName = 'svc_GmsaSqlDS' ## Replace this value with new gMSA Name
$dnsHostName = 'svc_GmsaSqlDS.contoso.com'
$adOU = 'OU=Managed Service Accounts,OU=Service Accounts,OU=Admins,DC=contoso,DC=com' ## Replace with actual AD OU
$groupName = 'Svc_GMSA_SQL' ## Name of the GMSA Group

## Create the user account
New-ADServiceAccount -Name $gMSAName -Path $adOU -DNSHostName $dnsHostName -PrincipalsAllowedToRetrieveManagedPassword $groupName -TrustedForDelegation $true -ManagedPasswordIntervalInDays 30

## Check the newly created user account
Get-ADServiceAccount $gMSAName -Properties * | FL DNSHostName,KerberosEncryptionType,ManagedPasswordIntervalInDays,Name,PrincipalsAllowedToRetrieveManagedPassword,SamAccountName,ServicePrincipalNames




## ---------------------------------------------------------------- ##
## Run this on the SQL Servers
## ---------------------------------------------------------------- ##

## Run from SQL server - Powershell as admin
Install-WindowsFeature RSAT-AD-PowerShell
Import-module activedirectory

<#
Run this script to create the following users:
1. svc_GmsaSqlDS (Database Services)
2. svc_GmsaSqlAS (Agent Services)
3. svc_GmsaSqlIS (Integration Services)
4. svc_GmsaSqlRS (Reporting Services)
#>

$gMSAName = 'svc_GmsaSqlDS' ## Replace this value with new gMSA Name

## Install the gMSA account in server
Install-ADServiceAccount -Identity $gMSAName

## NOTE: If error here check the group membership or reboot the server

## Test gMSA account installation in Server
Test-AdServiceAccount $gMSAName

