Return 'Cláudio, come on, you are giving a presentation..do not try to run the whole script! :) '

# We are going to use the last relase (v0.9.18) that stils a bit beta from the (v1.0)

#If you don't have administratives rights you should use Install-Module dbatools -Scope CurrentUser

#Import-Module dbatools -force
Import-Module "C:\Program Files\WindowsPowerShell\Modules\dbatools\0.9.18\dbatools.psd1" -Force

# Which commands do we have?
Get-Command -Module dbatools

# How many?
(Get-Command -Module dbatools | Where-Object CommandType -eq 'Function').Count

# How do we find commands?
Find-DbaCommand -Tag Backup
Find-DbaCommand -Tag Migration
Find-DbaCommand -Tag Performance
Find-DbaCommand -Pattern Database 
Find-DbaCommand -Pattern Login

# Using commands

# ALWAYS (I'm serious), use Get-Help
Get-Help Test-DbaLinkedServerConnection -Full

# -ShowWindow allows to use a search
Get-Help Find-DbaStoredProcedure -ShowWindow


#Set instances variables
$ComputerSQL2014 = "sql2014"

$sql2008 = "sql2008"
$sql2012 = "sql2012"
$sql2016 = "sql2016"
$sql2016STDRTM = "sql2016\standardrtm"
$sql2016Express = "sql2016\sqlexpress"
$sqlALLInstances = $sql2008, $sql2016 , $sql2016STDRTM, $sql2016Express
$sqlAllcomputers = $sqlALLInstances, $ComputerSQL2014, $sql2012

# Lets back up those new databases to a Network Share
Backup-DbaDatabase -SqlInstance $sql2016STDRTM -BackupDirectory \\nas\sql\VGPortuguese\2016STDRTM -CompressBackup


# What are instance default Data/Log/Backup paths?
Get-DbaDefaultPath -SqlInstance $sqlALLInstances #| Format-Table

$sql2008DefaultBackupPath = "\\sql2008\c$\Program Files\Microsoft SQL Server\MSSQL10_50.MSSQLSERVER\MSSQL\Backup"
Invoke-Item $sql2008DefaultBackupPath


# View backup history
Get-DbaBackupHistory -SqlInstance $sql2016STDRTM

# Only last backup
Get-DbaBackupHistory -SqlInstance $sql2016STDRTM -Last

# Few information? Remember that you can use *
Get-DbaBackupHistory -SqlInstance $sql2016STDRTM | Select-Object *

# What sorcery is that? :-) Open results in a grid view, select and open the path of the select line
Get-DbaBackupHistory -SqlInstance $sql2016STDRTM | Select-Object * | Out-GridView -PassThru | Select-Object -ExpandProperty Path | Split-Path -Parent | Invoke-Item


# Do you test your backups right?! ;-)
Test-DbaLastBackup -SqlInstance $sql2016STDRTM | Out-GridView

## You 'Could' just verify them (will run DBCC CHECKDB)
Test-DbaLastBackup -SqlInstance $sql2016STDRTM -Destination $sql2016Express -VerifyOnly | Out-GridView


# Select databases to backup!
Get-DbaDatabase -SqlInstance $sql2008 | Out-GridView -PassThru | Backup-DbaDatabase -CopyOnly

# Please restore a copy of dbareports on the sql2016\Express instance
Backup-DbaDatabase -SqlInstance $sql2016Express -Database dbareports -CopyOnly -BackupDirectory \\nas\sql\VGPortuguese\2016STDRTM | Restore-DbaDatabase -SqlInstance $sql2016STDRTM #-WithReplace

# All backups from a folder and retore them on the server (show instance on SSMS)
Invoke-Item \\nas\sql\backups\SQL2008
Get-ChildItem -Directory \\nas\sql\backups\SQL2008 | Restore-DbaDatabase -SqlInstance $sql2016STDRTM


# Backup.bak?! What is inside? Read backup header
$backup = "\\nas\sql\VGPortuguese\backup.bak"
Read-DbaBackupHeader -SqlInstance $sql2016Express -Path $backup | Select ServerName, DatabaseName, UserName, BackupFinishDate, SqlVersion, BackupSizeMB




# Now lets verify some information for one or more instances with just a line of code!

# Get-DbaSqlService
$sqlAllcomputers | ForEach-Object { Get-DbaSqlService -ComputerName $_ } | Format-Table -AutoSize


#Test connection to instances
Test-DbaConnection -SqlServer $sql2016

$sqlALLInstances[0..3] | % {Test-DbaConnection -SqlServer $_}


<#
    Do you know in which port is your instance listening? 
    How do you get the TCP port? Get-DbaTcpPort for the rescue :-)
#>
Get-DbaTcpPort -SqlServer $sqlALLInstances | Format-Table

#Startup Parameters? Which ones? - We have a command to set them if you want :-)
Get-DbaStartupParameter -SqlInstance $sqlALLInstances

# Want to know specific version?
$sqlALLInstances | Get-DbaSqlBuildReference | Format-Table


# What about windows informations? 
# Test-DbaDiskAllocation
Test-DbaDiskAllocation -ComputerName $ComputerSQL2014 | Format-Table -AutoSize

# But we can also get information from disk space
Get-DbaDiskSpace -ComputerName $ComputerSQL2014 | Format-Table -AutoSize


# Some instance and databases validations
# Let's see how many memory is set for each instance
$sqlALLInstances | Test-DbaMaxMemory | Format-Table

# Verify which ones does not have the Recommended value
$sqlALLInstances | Test-DbaMaxMemory | Where-Object { $_.SqlMaxMB -gt $_.TotalMB } | Format-Table

# Fix that! Note: You can use Set-DbaMaxMemory with or without -MaxMb parameter - Take a look on the help ;-)
$sqlALLInstances | Test-DbaMaxMemory | Where-Object { $_.SqlMaxMB -gt $_.TotalMB } | Set-DbaMaxMemory -MaxMb 5120


# What about the MaxDOP (max degree of paralelism)
# Non-v2016
Test-DbaMaxDop -SqlInstance $sql2008

# v2016+
Test-DbaMaxDop -SqlInstance $sql2016 | Format-Table

Test-DbaMaxDop -SqlInstance $sql2016Express | Format-Table


# And more Test-* commands
Get-Command -Module dbatools -Name Test*




# Do you want to read your log files?
#Agent
Get-DbaAgentLog -SqlInstance $sql2016 | Out-GridView

#SqlErrorLog
Get-DbaSqlLog -SqlInstance $sql2016 | Out-GridView

#Database mail log
Get-DbaDbMailLog -SqlInstance $sql2016 | Out-GridView

# Job history
Get-DbaAgentJobHistory -SqlInstance $sql2016 -StartDate (Get-Date).AddDays(-2) | Format-Table


# Who changed my database and what did they do?  Remember this is temporay information because it relies on the default trace
Get-DbaSchemaChangeHistory -SqlInstance $sql2016 -Database tempdb | Out-GridView


# This commands not only but also help developers
# Want to know which modules changes since some date?
Get-DbaSqlModule -SqlInstance $sqlALLInstances -NoSystemDb -NoSystemObjects | Out-GridView


<# Find-DbaStoredProcedure - we also have Find-DbaView & Find-DbaTrigger #>
Find-DbaStoredProcedure -SqlInstance $sql2016 -Pattern 'Name' -Verbose | Out-GridView

# And if I told you that you can use regular expressions?! You can't do it with T-SQL
Find-DbaStoredProcedure $sql2016 -Pattern '\w+@\w+\.\w+'



# What depends on this table
Get-DbaTable -SqlInstance $sql2016 -Database AdventureWorks2014 | Out-GridView -PassThru | Get-DbaDependency

# What does that table depend on? (OrderLines)
$Depends = Get-DbaTable -SqlInstance $sql2008 -Database db1 | Out-GridView -PassThru | Get-DbaDependency -Parents 
$Depends

# but the object returns more than that lets look at the first 1
$Depends| Select -First 1 | Select *



# Working with Partitioned Tables?
# Show me Database Partition functions
Get-DbaDatabasePartitionFunction -SqlInstance $sql2008 -Database "WebAnalyticsServiceApplication_ReportingDB_181e8d07-d10d-4261-83b4-3f2c2648f65e"

# Once again we can get more detail
Get-DbaDatabasePartitionFunction -SqlInstance $sql2008 -Database "WebAnalyticsServiceApplication_ReportingDB_181e8d07-d10d-4261-83b4-3f2c2648f65e" | Select *

# Show Database Partition Schemes
Get-DbaDatabasePartitionScheme -SqlInstance $sql2008 -Database "WebAnalyticsServiceApplication_ReportingDB_181e8d07-d10d-4261-83b4-3f2c2648f65e" | Select *

# What about compression?
Test-DbaCompression -SqlInstance $sql2016 -Database Northwind | Out-GridView

# Do you know the query to find duplicate index? And the overlapping ones?
Find-DbaDuplicateIndex -SqlInstance $sql2016 -Database AdventureWorks2014

#And the overlapping ones?
Find-DbaDuplicateIndex -SqlInstance $sql2016 -Database AdventureWorks2014 -IncludeOverlapping


# And more
# Get Execution Plans
Get-DbaExecutionPlan -SqlInstance $sql2016 | Out-GridView

# Also Export-DbaExecutionPlan
Export-DbaExecutionPlan -SqlInstance $sql2016 -Database AutoGrowth -Path C:\temp\ExecutionPlans

# everyone uses sp_whoisactive
Invoke-DbaWhoisActive -SqlInstance $sql2016 -ShowOwnSpid | Out-GridView


# How about something cool with Glenn Berrys Diagnostic Queries ?
Invoke-DbaDiagnosticQuery -SqlInstance $sql2016 | Out-GridView

# But I can save it?! Sure :-)
$Suffix = 'VGPortuguese' + (Get-Date -Format yyyy-MM-dd_HH-mm-ss)
Invoke-DbaDiagnosticQuery -SqlInstance $sql2016 | Export-DbaDiagnosticQuery -Path C:\temp\ExportDbaDiagnosticQuery -Suffix $Suffix
explorer C:\temp\ExportDbaDiagnosticQuery


# Last successful itegrity check (DBCC CHECKDB). How to do it with T-SQL?
# You need to run DBCC DBINFO([DBA-Admin]) WITH TABLERESULTS
# Filter results
# Run for each database in each instance

# So, how much time it will take to get this info from all of the instances / databases?

# This long for 5 instances and 101 databases :-)
Measure-Command {$sql2012, $sqlALLInstances | Get-DbaLastGoodCheckDb | Out-GridView}



# AutoGrowth, VLFs (Tlog fragmentation), Expand Tlog Responsibly
<# Find-DbaDatabaseGrowthEvent #>
Find-DbaDatabaseGrowthEvent -SqlInstance $sql2016 -Database AutoGrowth | Where-Object StartTime -gt (Get-Date).AddMinutes(-120) | Out-GridView
(Find-DbaDatabaseGrowthEvent -SqlInstance $sql2016 -Database AutoGrowth | Where-Object StartTime -gt (Get-Date).AddMinutes(-120)).Count

# How maby VLFs we have?
Test-DbaVirtualLogFile -SqlInstance $sql2016 -Database AutoGrowth

Get-DbaDatabaseSpace -SqlInstance $sql2016 -Database AutoGrowth

<# Expand-DbaTLogResponsibly #>
Expand-DbaTLogResponsibly -SqlInstance $sql2016 -Database AutoGrowth -TargetLogSizeMB 512 -ShrinkLogFile -ShrinkSizeMB 1 -BackupDirectory "\\nas\sql\VGPortuguese\AutoGrowth"

# when we know that a lot of data will be load into database
Expand-DbaTLogResponsibly -SqlInstance $sql2016 -Database AutoGrowth -TargetLogSizeMB 2048 

# Clean up the waste of space on your server by removing orphaned files
<# Orphaned File #>
$Files = Find-DbaOrphanedFile -SqlInstance $sql2016Express
$Files 

(($Files | ForEach-Object { Get-ChildItem $_.RemoteFileName | Select -ExpandProperty Length} ) | Measure-Object -Sum).Sum / 1Mb

# You can, for example, zip them and move to another location
$Files.RemoteFileName  | Remove-Item -WhatIf


# Want more? Look at the Community presentations 
Start-Process 'https://github.com/sqlcollaborative/community-presentations'

# and here:
Start-Process 'https://dbatools.io/presentations'
