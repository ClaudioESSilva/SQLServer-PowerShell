<#
Generating reports to Excel

> This example needs `ImportExcel` PowerShell module.

NOTE: You can read more on my SQL Server Central article:
    Generate Role Member Reports using dbatools and the ImportExcel PowerShell modules
    https://www.sqlservercentral.com/articles/generate-role-member-reports-using-dbatools-and-the-importexcel-powershell-modules
#>
# Set variables
$SQLInstance = "localhost,1433"
$secureString = ConvertTo-SecureString "dbatools.IO" -AsPlainText -Force
$cred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList "sqladmin", $secureString
$excludeDatabase = "myDB", "myDB2"
$excludeLogin = "renamedSA"
$excludeLoginFilter = "NT *", "##*"
 
# To be used on Export-Excel command
$excelFilepath = "D:\Presentations\Github\SQLServer-PowerShell\Presentations\Sinta-se um mágico usando dbatools\Excel-Report\$($SQLInstance -replace ',', '')_$((Get-Date).ToFileTime()).xlsx"
$freezeTopRow = $true
$tableStyle = "Medium6"
$autoSize = $true




#Region Get data
# Get all instance logins
$Logins = Get-DbaLogin -SqlInstance $SQLInstance -SqlCredential $cred -ExcludeLogin $excludeLogin -ExcludeFilter $excludeLoginFilter
 
# Get all server roles and its members
$instanceRoleMembers = Get-DbaServerRoleMember -SqlInstance $SQLInstance -SqlCredential $cred -Login $Logins.Name
 
# Get all database roles and its members
$dbRoleMembers = Get-DbaDbRoleMember -SqlInstance $SQLInstance -SqlCredential $cred -ExcludeDatabase $excludeDatabase | Where-Object UserName -in $logins.Name
#EndRegion



# Remove the report file if exists
Remove-Item -Path $excelFilepath -Force -ErrorAction SilentlyContinue


#Region Export Data to Excel
# Export data to Excel
## Export Logins
$excelLoginSplatting = @{
    Path = $excelFilepath 
    WorkSheetname = "Logins"
    TableName = "Logins"
    FreezeTopRow = $freezeTopRow
    TableStyle = $tableStyle
    AutoSize = $autoSize
}
$Logins | Select-Object "ComputerName", "InstanceName", "SqlInstance", "Name", "LoginType", "CreateDate", "LastLogin", "HasAccess", "IsLocked", "IsDisabled" | Export-Excel @excelLoginSplatting
 
## Export instance roles and its members
$excelinstanceRoleMembersOutput = @{
    Path = $excelFilepath 
    WorkSheetname = "InstanceLevel"
    TableName = "InstanceLevel"
    TableStyle = $tableStyle
    FreezeTopRow = $freezeTopRow
    AutoSize = $autoSize
}
$instanceRoleMembers | Export-Excel @excelinstanceRoleMembersOutput
 
## Export database roles and its members
$exceldbRoleMembersOutput = @{
    Path = $excelFilepath 
    WorkSheetname = "DatabaseLevel"
    TableName = "DatabaseLevel"
    TableStyle = $tableStyle
    FreezeTopRow = $freezeTopRow
    AutoSize = $autoSize
}
$dbRoleMembers | Export-Excel @exceldbRoleMembersOutput -Show
#EndRegion