#How get the module
#Install-Module ReportingServicesTools

#Import-Module ReportingServicesTools

#Report server URL parameter

$reportServerUri = 'http://localhost:8080/ReportServer'

#source parameters
$sourceRSFolder = "/zFolder"
$downloadFolder = "D:\temp\Download"

#destination parameters
$destinationFolderPath = "/"
$destinationFolderName = "xFolder"
$newRSFolderPath = "$destinationFolderPath$destinationFolderName"

#data source configuration
$newRSDSFolder = "$destinationFolderPath$destinationFolderName"
$newRSDSName = "Datasource"
$newRSDSExtension = "SQL"
$newRSDSConnectionString = "Initial Catalog=msdb; Data Source=localhost"
$newRSDSCredentialRetrieval = "Store"
$newRSDSCredential = Get-Credential -Message "Enter user credentials for data source" -Username u_DataGrillen

$DataSourcePath = "$newRSDSFolder/$newRSDSName"

# Create a new proxy to be used on the subsequent invocations
$proxy = New-RsWebServiceProxy -ReportServerUri $reportServerUri

# Creates a new folder on the root of report server
New-RsFolder -Proxy $proxy -RsFolder $destinationFolderPath -FolderName $destinationFolderName

#Download all objects of type Report
Get-RsFolderContent -Proxy $proxy -RsFolder $sourceRSFolder |  Where-Object TypeName -eq 'Report' |
    Select-Object -ExpandProperty Path |
    Out-RsCatalogItem -Proxy $proxy -Destination $downloadFolder


#Download all files in the diretory
#Out-RsFolderContent -Proxy $proxy -RsFolder $sourceRSFolder -Destination $downloadFolder

#Upload all files from the download folder
Write-RsFolderContent -Proxy $proxy -Path $downloadFolder -RsFolder $newRSFolderPath

#Add new datasource
New-RsDataSource -Proxy $proxy -RsFolder $newRSDSFolder -Name $newRSDSName -Extension $newRSDSExtension -ConnectionString $newRSDSConnectionString -CredentialRetrieval $newRSDSCredentialRetrieval -DatasourceCredentials $newRSDSCredential

# Set report datasource
Get-RsCatalogItems -Proxy $proxy -RsFolder $newRSFolderPath | Where-Object TypeName -eq 'Report' | ForEach-Object {
    $dataSource = Get-RsItemReference -Proxy $proxy -Path $_.Path
    if ($null -ne $dataSource) {
        Set-RsDataSourceReference -Proxy $proxy -Path $_.Path -DataSourceName $dataSource.Name -DataSourcePath $DataSourcePath
        Write-Output "Changed datasource $($dataSource.Name) set to $DataSourcePath on report $($_.Path) "
    }
    else {
        Write-Warning "Report $($_.Path) does not contain an datasource."
    }
}
