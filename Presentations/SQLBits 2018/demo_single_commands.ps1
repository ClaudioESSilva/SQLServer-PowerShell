# This script was presented sing ReportingServicesTools v0.0.4.4.
# You have to set the values for the parameters or you can just change the values directly on the commands

return "No no no..don't run the whole script :-)"
#How get the module (Force if you already have one version)
#Install-Module ReportingServicesTools -Force

#Remove-Module ReportingServicesTools
#Import-Module ReportingServicesTools -Force

#View command
Get-Module -Name ReportingServicesTools -ListAvailable

#View available Functions
Get-Command -Module ReportingServicesTools -CommandType Function

#Report server URL parameter
$reportServerUri = 'http://localhost:8080/ReportServer'
$RSItemsFolderWDS = 'C:\temp\SSRS Items\WithDataSource'
$RSItemsFolderPerfReports = 'C:\temp\SSRS Items\SQL Server Performance Dashboard Reporting Solution'
$downloadFolder = 'C:\temp\SSRS Items\Demo Download'
$EncryptionKeyPath = "C:\temp\SSRS Items\Demos\EncryptionKey"
$user = "domain\user"

# Backup Encryption key
Invoke-Item $EncryptionKeyPath
Backup-RsEncryptionKey -ReportServerInstance "SSRS" -ReportServerVersion SQLServer2017 -Password "str0ngPa55w0rd" -KeyPath "$EncryptionKeyPath\EncryptionKey_bck.snk"

# Configure email settings (if you have the SSRS configuration manager open you need to re-open it)
Set-RsEmailSettings -ReportServerInstance "SSRS" -SmtpServer "smtp.sqlbits.com" -SenderAddress "help@sqlbits.com" -ReportServerVersion SQLServer2017 -Authentication Ntlm


# Create a new proxy to be used on the subsequent invocations
$proxy = New-RsWebServiceProxy -ReportServerUri $reportServerUri

# Creates a new folder on the root of report server
New-RsFolder -Proxy $proxy -RsFolder "/" -FolderName "London"

New-RsFolder -Proxy $proxy -RsFolder "/" -FolderName "Lisbon"

# Grant Browser access to user u_sqlbits2018 (one at a time)
Grant-RsCatalogItemRole -Proxy $proxy -Path "/London" -RoleName 'Browser' -Identity $user

Grant-RsCatalogItemRole -Proxy $proxy -Path "/London" -RoleName 'Content Manager' -Identity $user

Grant-RsCatalogItemRole -Proxy $proxy -Path "/London" -RoleName 'My Reports' -Identity $user
Grant-RsCatalogItemRole -Proxy $proxy -Path "/London" -RoleName 'Publisher' -Identity $user
Grant-RsCatalogItemRole -Proxy $proxy -Path "/London" -RoleName 'Report Builder' -Identity $user

# Wrong RoleName - Will fail
Grant-RsCatalogItemRole -Proxy $proxy -Path "/London" -RoleName 'Publisher2' -Identity $user

# See list of accesses
Get-RsCatalogItemRole -Proxy $proxy -Path "/London"

# Revoke access to user domain\user (will remove ALL roles)
Get-help Revoke-RsCatalogItemAccess -Detailed
#Revoke-RsCatalogItemAccess -Proxy $proxy -Path "/London" -Identity $user

# Workaround
[System.Collections.ArrayList]$ActualRoles = (Get-RsCatalogItemRole -Proxy $proxy -Path "/London" | Where-Object Identity -eq $user).Roles | Select-Object -ExpandProperty Name

$ActualRoles

$ActualRoles.Remove("Report Builder")
$ActualRoles.Remove("Publisher")

$ActualRoles

Revoke-RsCatalogItemAccess -Proxy $proxy -Path "/London" -Identity $user

# See list of accesses
Get-RsCatalogItemRole -Proxy $proxy -Path "/London"

# Add each one
$ActualRoles | ForEach-Object {
    Grant-RsCatalogItemRole -Proxy $proxy -Path "/London" -RoleName "$_" -Identity $user
}

# See list of accesses - Now, just 3
Get-RsCatalogItemRole -Proxy $proxy -Path "/London"


## Reports
# Upload a single report on SQL Server 2017 GUI needs about: RS folder navigation + "upload" click + browsing to find .rdl + 1 if already exists (to Overwrite)
# You can't select more than 1 .rdl each time. If you have 10 reports to updload... 30 clicks (minimum!)

# Upload a single Report
Invoke-Item $RSItemsFolderPerfReports
Write-RsCatalogItem -Proxy $proxy -Path "D:\Presentations\SQLBits 2018\Demos\SSRS Items\SQL Server Performance Dashboard Reporting Solution\performance_dashboard_main.rdl" -RsFolder "/London"

# View existing reports inside folder
Get-RsCatalogItems -Proxy $proxy -RsFolder "/London"


# Upload an entire folder
# If you don't use -Overwrite and the rdl already exists it will give error and stop execution
Write-RsFolderContent -Proxy $proxy -Path "D:\Presentations\SQLBits 2018\Demos\SSRS Items\SQL Server Performance Dashboard Reporting Solution" -RsFolder "/London" -Overwrite -Verbose


# Download one item
Invoke-Item $downloadFolder
Out-RsCatalogItem -Proxy $proxy -Destination $downloadFolder -RsItem "/London/performance_dashboard_main"


# Download all folder content
Out-RsFolderContent -Proxy $proxy -Destination $downloadFolder -RsFolder "/London"

# Working with non-built-in data sources
# Create new Data Source
$newRSDSName = "Datasource"
$newRSDSExtension = "SQL"
$newRSDSConnectionString = "Initial Catalog=msdb; Data Source=localhost"
$newRSDSCredentialRetrieval = "Store"
$newRSDSCredential = Get-Credential -Message "Enter user credentials for data source" -UserName $user

New-RsDataSource -Proxy $proxy -RsFolder "/Lisbon" -Name $newRSDSName -Extension $newRSDSExtension `
                 -ConnectionString $newRSDSConnectionString -CredentialRetrieval $newRSDSCredentialRetrieval -DatasourceCredentials $newRSDSCredential

# Upload Instances.rdl report
Write-RsCatalogItem -Proxy $proxy -Path "D:\Presentations\SQLBits 2018\Demos\SSRS Items\WithDataSource\Instances.rdl" -RsFolder "/Lisbon"


## NOTE: Subscriptions only works if the report already have/had an DataSource (not working with Custom Data Sources)
# Set the datasource reference (6 clicks)
$dataSource = Get-RsItemReference -Proxy $proxy -Path "/Lisbon/Instances"
Set-RsDataSourceReference -Proxy $proxy -Path "/Lisbon/Instances" -DataSourceName $dataSource.Name -DataSourcePath "/Lisbon/Datasource"

# Crate new subscription (Thanks to Mark Wragg @markwragg) for instances report
1..100 | ForEach-Object {
    Write-Output "Creating subscription $_"

    $Schedule = New-RsScheduleXml -Daily -Interval (Get-Random -Minimum 1 -Maximum 5)

    if ($_ % 2 -eq 0) {
        $to = 'test@someaddress.com'
    }
    else {
        #$Schedule = New-RsScheduleXml -Weekly -Interval (Get-Random -Minimum 1 -Maximum 5)
        $to = 'manager@someaddress.com'
    }

    $params = @{
        Proxy = $proxy
        RsItem = '/Lisbon/instances'
        Description = "instances - $_"
        DeliveryMethod = 'Email'
        Schedule = $Schedule
        Subject = 'instances report'
        To = $to
        RenderFormat = 'PDF'
    }

    $newSub = New-RsSubscription @params
}
# Reset
#Get-RsSubscription -Proxy $proxy -Path "/Lisbon/instances" | Remove-RsSubscription -Proxy $proxy

# View Subscriptions
Get-RsSubscription -Proxy $proxy -Path "/Lisbon/instances" | Select-Object -First 5

# Grab all subscriptions which email is manager
$managerSubscriptions = Get-RsSubscription -Proxy $proxy -Path "/Lisbon/instances" | Where-Object {
         $_.DeliverySettings.Parametervalues.name -eq "to" `
    -and $_.DeliverySettings.Parametervalues.Value -Contains "manager@someaddress.com"
}

# Number of subscriptions to: manager
$managerSubscriptions.Count

$managerSubscriptions | Remove-RsSubscription -Proxy $proxy -Verbose


# Export/Import Subcriptions

# Get specific subscriptions
$subscriptionsToDownload = Get-RsSubscription -Proxy $proxy -Path "/Lisbon/instances" | Select-Object -First 5

# Export to individual files
Invoke-Item "$downloadFolder\Subscriptions"
$subscriptionsToDownload | ForEach-Object {Export-RsSubscriptionXml -Subscription $_ -Path "$downloadFolder\Subscriptions\$($_.SubscriptionId).xml"}

# Export all subscriptions to just one file
$subscriptionsToDownload | Export-RsSubscriptionXml -Path "$downloadFolder\Subscriptions\AllSubscriptions.xml"

# Get all subscriptions pipe to remove
Get-RsSubscription -Proxy $proxy -Path "/Lisbon/instances" | Remove-RsSubscription -Proxy $proxy -Verbose

# Import subscritpion file and set to a report
Import-RsSubscriptionXml -Proxy $proxy "$downloadFolder\Subscriptions\AllSubscriptions.xml" | Copy-RsSubscription -Proxy $proxy -RsItem "/Lisbon/instances"

# Import various subscription files
Get-ChildItem -Path "$downloadFolder\Subscriptions\*.xml" | ForEach-Object {
    Import-RsSubscriptionXml -Proxy $proxy $_.FullName | Copy-RsSubscription -Proxy $proxy -RsItem "/Lisbon/instances"
}


# PBIRS
#The ones for PBIRS
Get-Command -Module ReportingServicesTools -Name *RSRest* -CommandType Function

$PBIRSItemsFolder = 'SSRS:\SSRS Items'
$pbirsServerUri = "http://redgluel1:8081/Reports"
$session = New-RsRestSession -ReportPortalUri $pbirsServerUri

$proxyPBIRS = New-RsWebServiceProxy -ReportServerUri $pbirsServerUri

$pbirsFolderName = "Cities"
$pbirsFolderPath = "/$pbirsFolderName"
New-RsRestFolder -WebSession $session -FolderName $pbirsFolderName -RsFolder "/"

# Create a new proxy to be used on the subsequent invocations
$user = "redgluel1\u_sqlbits2018"
Grant-RsCatalogItemRole -Proxy $proxyPBIRS -Path $pbirsFolderPath  -RoleName 'Browser' -Identity $user


# Just one
Write-RsRestCatalogItem -WebSession $session -Path "D:\Presentations\SQLBits 2018\24HoP_Report_1.pbix" -RsFolder $pbirsFolderPath

# A folder with all sub-folders
Invoke-Item "$PBIRSItemsFolder\Cities"
Write-RsRestFolderContent -WebSession $session -Path "D:\Presentations\SQLBits 2018\Demos\SSRS Items\Cities" -RsFolder $pbirsFolderPath -Recurse -Verbose

