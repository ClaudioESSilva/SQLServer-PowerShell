return "No no no..don't run the whole script :-)"

#Using v0.0.5.0 - Released @ 2019-06-18

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
$RSItemsFolderWDS = 'SSRS:\SSRS Items\WithDataSource'
$RSItemsFolderPerfReports = 'SSRS:\SSRS Items\SQL Server Performance Dashboard Reporting Solution'
$downloadFolder = 'SSRS:\Demo Download'
$EncryptionKeyPath = "D:\temp\EncryptionKey"
$userName = "DataGrillen"
$user = "localhost\u_$userName"
$folderCurrentCity = "Lingen"
$folderHomeCity = "Lisbon"

# Backup Encryption key
Invoke-Item $EncryptionKeyPath

$params = @{
    ReportServerInstance = "SSRS"
    ReportServerVersion = "SQLServer2017"
    Password = "str0ngPa55w0rd"
    KeyPath = "$EncryptionKeyPath\EncryptionKey_bck.snk"
}
Backup-RsEncryptionKey @params


# Configure email settings (if you have the SSRS configuration manager open you need to re-open it)
# 1st show current configurations
Invoke-Item "C:\Program Files\Microsoft SQL Server Reporting Services\Shared Tools\RSConfigTool.exe"
# Set new values
$params = @{
    ReportServerInstance = "SSRS"
    ReportServerVersion = "SQLServer2017"
    SmtpServer = "smtp.$userName.com"
    Authentication = "Ntlm"
    SenderAddress = "help@$userName.com"
}
Set-RsEmailSettings @params


# Create a new proxy to be used on the subsequent invocations
$proxy = New-RsWebServiceProxy -ReportServerUri $reportServerUri

Grant-RsSystemRole -Proxy $proxy -Identity "domain\user" -RoleName "System Administrator" -Verbose

# Creates a new folder on the root of report server
New-RsFolder -Proxy $proxy -RsFolder "/" -FolderName $folderCurrentCity

New-RsFolder -Proxy $proxy -RsFolder "/" -FolderName $folderHomeCity

# Grant Browser access to user u_$userName (one at a time)
Grant-RsCatalogItemRole -Proxy $proxy -Path "/$folderCurrentCity" -RoleName 'Browser' -Identity $user

Grant-RsCatalogItemRole -Proxy $proxy -Path "/$folderCurrentCity" -RoleName 'Content Manager' -Identity $user

Grant-RsCatalogItemRole -Proxy $proxy -Path "/$folderCurrentCity" -RoleName 'My Reports' -Identity $user
Grant-RsCatalogItemRole -Proxy $proxy -Path "/$folderCurrentCity" -RoleName 'Publisher' -Identity $user
Grant-RsCatalogItemRole -Proxy $proxy -Path "/$folderCurrentCity" -RoleName 'Report Builder' -Identity $user

# Wrong RoleName - Will fail
Grant-RsCatalogItemRole -Proxy $proxy -Path "/$folderCurrentCity" -RoleName 'Publisher2' -Identity $user

# See list of accesses
Get-RsCatalogItemRole -Proxy $proxy -Path "/$folderCurrentCity"

# Revoke access to user domain\user (will remove ALL roles)
Get-help Revoke-RsCatalogItemAccess -Detailed
#Revoke-RsCatalogItemAccess -Proxy $proxy -Path "/$folderCurrentCity" -Identity $user

# Workaround
[System.Collections.ArrayList]$ActualRoles = (Get-RsCatalogItemRole -Proxy $proxy -Path "/$folderCurrentCity" | Where-Object Identity -eq $user).Roles | `
                                                Select-Object -ExpandProperty Name

$ActualRoles

$ActualRoles.Remove("Report Builder")
$ActualRoles.Remove("Publisher")

$ActualRoles

Revoke-RsCatalogItemAccess -Proxy $proxy -Path "/$folderCurrentCity" -Identity $user

# See list of accesses
Get-RsCatalogItemRole -Proxy $proxy -Path "/$folderCurrentCity"

# Add each one
$ActualRoles | ForEach-Object {
    Grant-RsCatalogItemRole -Proxy $proxy -Path "/$folderCurrentCity" -RoleName "$_" -Identity $user
}

# See list of accesses - Now, just 3
Get-RsCatalogItemRole -Proxy $proxy -Path "/$folderCurrentCity"


## Reports
# Upload a single report on SQL Server 2017 GUI needs like:
#  RS folder navigation
#   + "upload" click
#   + browsing to find .rdl
#   + 1 if already exists (to Overwrite)
# You can't select more than 1 .rdl each time. If you have 10 reports to upload...30 clicks (minimum!) 40 clicks (when you want to update)

# Upload a single Report
Invoke-Item $RSItemsFolderPerfReports
Write-RsCatalogItem -Proxy $proxy -Path "$RSItemsFolderPerfReports\performance_dashboard_main.rdl" -RsFolder "/$folderCurrentCity" -Verbose

# View existing reports inside folder
Get-RsCatalogItems -Proxy $proxy -RsFolder "/$folderCurrentCity"


# Upload an entire folder (since v0.0.4.7 JPG/PNG are also uploaded! And since v0.0.5.1 BMP,GIF,XLS,XLSX also available!)
# If you don't use -Overwrite and the rdl already exists it will give error and stop execution
Write-RsFolderContent -Proxy $proxy -Path $RSItemsFolderPerfReports -RsFolder "/$folderCurrentCity" -Overwrite -Verbose


# Download one item
Invoke-Item $downloadFolder
Out-RsCatalogItem -Proxy $proxy -Destination $downloadFolder -RsItem "/$folderCurrentCity/performance_dashboard_main"


# Download all folder content
Out-RsFolderContent -Proxy $proxy -Destination $downloadFolder -RsFolder "/$folderCurrentCity"

# Working with non-built-in data sources
# Create new Data Source
$newRSDSName = "Datasource"
$newRSDSExtension = "SQL"
$newRSDSConnectionString = "Initial Catalog=msdb; Data Source=localhost"
$newRSDSCredentialRetrieval = "Store"
$newRSDSCredential = Get-Credential -Message "Enter user credentials for data source" -UserName $user

$params = @{
    Proxy = $proxy
    RsFolder = "/$folderHomeCity"
    Name = $newRSDSName
    Extension = $newRSDSExtension
    ConnectionString = $newRSDSConnectionString
    CredentialRetrieval = $newRSDSCredentialRetrieval
    DatasourceCredentials = $newRSDSCredential
}
New-RsDataSource @params

# Upload Instances.rdl report
Write-RsCatalogItem -Proxy $proxy -Path "$RSItemsFolderWDS\Instances.rdl" -RsFolder "/$folderHomeCity"


## NOTE: Subscriptions only works if the report already have/had an DataSource (not working with Custom Data Sources)
# Set the datasource reference (6/7 clicks)
$dataSource = Get-RsItemReference -Proxy $proxy -Path "/$folderHomeCity/Instances"
Set-RsDataSourceReference -Proxy $proxy -Path "/$folderHomeCity/Instances" -DataSourceName $dataSource.Name -DataSourcePath "/$folderHomeCity/Datasource"





# Create new subscription (Thanks to Mark Wragg @markwragg) for instances report
1..100 | ForEach-Object {
    Write-Output "Creating subscription $_"

    $Schedule = New-RsScheduleXml -Daily -Interval (Get-Random -Minimum 1 -Maximum 5)

    if ($_ % 2 -eq 0) {
        $to = 'test@someaddress.com'
    }
    else {
        $to = 'manager@someaddress.com'
    }

    $params = @{
        Proxy = $proxy
        RsItem = "/$folderHomeCity/instances"
        Description = "instances - $_"
        DeliveryMethod = 'Email'
        Schedule = $Schedule
        Subject = 'instances report'
        To = $to
        RenderFormat = 'PDF'
    }

    $null = New-RsSubscription @params
}
# Reset
# Get-RsSubscription -Proxy $proxy -Path "/$folderHomeCity/instances" | Remove-RsSubscription -Proxy $proxy

# View Subscriptions
Get-RsSubscription -Proxy $proxy -Path "/$folderHomeCity/instances" | Select-Object -First 5

# Grab all subscriptions which email is manager
$managerSubscriptions = Get-RsSubscription -Proxy $proxy -Path "/$folderHomeCity/instances" | Where-Object {
         $_.DeliverySettings.Parametervalues.name -eq "to" `
    -and $_.DeliverySettings.Parametervalues.Value -Contains "manager@someaddress.com"
}

# Number of subscriptions to: manager
$managerSubscriptions.Count

$managerSubscriptions | Remove-RsSubscription -Proxy $proxy -Verbose


# Export/Import Subcriptions

# Get specific subscriptions
$subscriptionsToDownload = Get-RsSubscription -Proxy $proxy -Path "/$folderHomeCity/instances" | Select-Object -First 5

# Open download folder
Invoke-Item "$downloadFolder\Subscriptions"

# Export to individual files
$subscriptionsToDownload | ForEach-Object {Export-RsSubscriptionXml -Subscription $_ -Path "$downloadFolder\Subscriptions\$($_.SubscriptionId).xml"}

# Export all subscriptions to just one file
$subscriptionsToDownload | Export-RsSubscriptionXml -Path "$downloadFolder\Subscriptions\AllSubscriptions.xml"

# Get all subscriptions pipe to remove
Get-RsSubscription -Proxy $proxy -Path "/$folderHomeCity/instances" | Remove-RsSubscription -Proxy $proxy -Verbose

# Import subscritpion file and set to a report
Import-RsSubscriptionXml -Proxy $proxy "$downloadFolder\Subscriptions\AllSubscriptions.xml" | Copy-RsSubscription -Proxy $proxy -RsItem "/$folderHomeCity/instances"

# Import various subscription files
Get-ChildItem -Path "$downloadFolder\Subscriptions\*.xml" | ForEach-Object {
    Import-RsSubscriptionXml -Proxy $proxy $_.FullName | Copy-RsSubscription -Proxy $proxy -RsItem "/$folderHomeCity/instances"
}

# Set subscription start date time schedule property to today. Supports also for EndDate
$oneSub = Get-RsSubscription -Proxy $proxy -Path "/$folderHomeCity/instances" | Select-Object -First 1 *
$oneSub | Set-RsSubscription -Proxy $proxy -StartDateTime "2019-06-21 8:00" -Verbose


# PBIRS
#The ones for PBIRS
Get-Command -Module ReportingServicesTools -Name *RSRest* -CommandType Function

$PBIRSItemsFolder = 'D:\temp\SSRS Items'
$pbirsServerUri = "http://localhost:8081/Reports"

# Create a new REST session to be used on the subsequent invocations
$session = New-RsRestSession -ReportPortalUri $pbirsServerUri

# Create a new proxy session to be used with non-RsRest subsequent invocations
$proxyPBIRS = New-RsWebServiceProxy -ReportServerUri $pbirsServerUri

Grant-RsSystemRole -Proxy $proxyPBIRS -Identity "domain\user" -RoleName "System Administrator" -Verbose

$pbirsFolderName = "Cities"
$pbirsFolderPath = "/$pbirsFolderName"
New-RsRestFolder -WebSession $session -FolderName $pbirsFolderName -RsFolder "/"

$pbirsFolderName = "Germany"
$pbirsFolderPath = "/Cities/$pbirsFolderName"
New-RsRestFolder -WebSession $session -FolderName $pbirsFolderName -RsFolder $pbirsFolderPath

# Shows that even when we are working with PBIRS we can use the SSRS commands to set some things (Ex: folder permissions)
$userName = "DataGrillen"
$user = "localhost\u_$userName"
Grant-RsCatalogItemRole -Proxy $proxyPBIRS -Path $pbirsFolderPath  -RoleName 'Browser' -Identity $user


# Just one - Remember that pbix needs to be saved for Report Server otherwise you can get an "(422) Unprocessable Entity." error message
Write-RsRestCatalogItem -WebSession $session -Path "$PBIRSItemsFolder\dbachecks_Düsseldorf.pbix" -RsFolder $pbirsFolderPath

# A folder with all sub-folders
Invoke-Item "$PBIRSItemsFolder\Cities"
Write-RsRestFolderContent -WebSession $session -Path "$PBIRSItemsFolder\Cities" -RsFolder $pbirsFolderPath -Recurse -Verbose

