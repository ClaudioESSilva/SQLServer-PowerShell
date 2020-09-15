<#
Idea: Export-DbaInstance (without pwds)  

Other/optional
1. replace suffix 
2. put on git

NOTE: You can read more about this approach on my blog posts:
- Backup your SQL instances configurations to GIT with dbatools – Part 1
  (https://claudioessilva.eu/2020/06/02/backup-your-sql-instances-configurations-to-git-with-dbatools-part-1/)

- Backup your SQL instances configurations to GIT with dbatools – Part 2 – Add parallelism
  (https://claudioessilva.eu/2020/06/04/backup-your-sql-instances-configurations-to-git-with-dbatools-part-2-add-parallelism/)
#>

$path = "D:\Presentations\Github\SQLServer-PowerShell\Presentations\Sinta-se um m�gico usando dbatools\temp"
$dbatools1 = "localhost,1433"
$secureString = ConvertTo-SecureString "dbatools.IO" -AsPlainText -Force
$cred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList "sqladmin", $secureString


#Perform export (not currently supported on Core)
#You may note that linked servers, credentials and central management server are excluded from the export.
#This is because they aren’t currently supported for various Windows-centric reasons.
$splatExportInstance = @{
    SqlInstance = $dbatools1
    SqlCredential = $cred
    Path = $path
    Exclude = @("LinkedServers", "Credentials", "CentralManagementServer", "BackupDevices", "Endpoints", "Databases", "ReplicationSettings", "PolicyManagement")
    ExcludePassword = $true
}
Export-DbaInstance @splatExportInstance

# View output
Invoke-Item $path



####################################################
# If you want to versioning it, example put on GIT #
####################################################

# 1. Save the results to a temp folder
# 2. Remove the suffix "-datetime"
Get-ChildItem -Path $path | ForEach-Object {Rename-Item -Path $_.FullName -NewName $_.Name.Substring(0, $_.Name.LastIndexOf('-')) -Force}

# 3. Copy and overwrite the files within your GIT folder. (This way you will keep the history)
Copy-Item -Path "$path\*" -Destination $(Split-Path -Path $path -Parent) -Recurse -Force


<#
    When working with GIT you can add the following example:

    git commit -m "Export-DbaInstance @ $((Get-Date).ToString("yyyyMMdd-HHmmss"))"
    git push
#>