# This commands not only help DBA but also help developers
# Want to know which modules changes since some date?
$splatGetModule = @{
    SqlInstance = $sql2016
    Database = "ReportServer"
    Type = "Trigger"
    ExcludeSystemDatabases = $true
    ExcludeSystemObjects = $true
}
Get-DbaModule @splatGetModule | Out-GridView


# Find-DbaStoredProcedure - we also have Find-DbaView & Find-DbaTrigger
Find-DbaStoredProcedure -SqlInstance $docker1 -SqlCredential $sqlCredential -Pattern 'FindEmail' -Verbose | Out-GridView

# And if I told you that you can use regular expressions?! You can't do it with T-SQL
Find-DbaStoredProcedure -SqlInstance $docker1 -SqlCredential $sqlCredential -Database Pubs -Pattern '\w+@\w+\.\w+'



# Do you know the query to find duplicate index? And the overlapping ones?
Find-DbaDBDuplicateIndex -SqlInstance $sql2016 -Database ReportServer

#And the overlapping ones? Ex: Same index keys but one of them have included columns
Find-DbaDbDuplicateIndex -SqlInstance $sql2016 -Database ReportServer -IncludeOverlapping




# Importing CSV to table
$csvPath = "D:\Presentations\Github\SQLServer-PowerShell\Presentations\Sinta-se um mágico usando dbatools\test.csv"

# Show the file
Invoke-Item $(Split-path $csvPath -Parent)

$splatImpCSV = @{
    Path = $csvPath
    Delimiter = ","
}
$csvData = Import-Csv @splatImpCSV


$splatWriteTable = @{
    SqlInstance = $sql2016 
    Database = "DataTuning" 
    Table = "SomeData" 
    AutoCreateTable = $true 
    Truncate = $true
}
$csvData | Write-DbaDataTable @splatWriteTable


# Checking the data
Invoke-DbaQuery -SqlInstance $sql2016 -Database "DataTuning" -Query "SELECT TOP 10 * FROM SomeData"