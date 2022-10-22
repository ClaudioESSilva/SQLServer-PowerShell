<#
    Creates the Mi Link between on prem and Azure SQL Managed Instance
#>
Import-Module dbatools -Force

$dbatoolsAzSQLMI = sqlmi.public.******.database.windows.net,3342
$dbatoolsAzSQLMIcred = Get-Credential -UserName "<login>" -Message "Azure SQL MI pwd"

$splatNewMiLink = @{
    ResourceGroupName = "dbatools"
    ManagedInstanceName = "dbatoolssqlmi"
    SqlInstance = "dbatoolsVM"
    SqlManagedInstance = $dbatoolsAzSQLMI
    SqlManagedInstanceCredential = $dbatoolsAzSQLMIcred
    DatabaseName = "dbatools2"
    PrimaryAvailabilityGroup = "ag_basic"
    SecondaryAvailabilityGroup = "mi_basic" 
    LinkName = "dag_basic"
    Verbose = $true
}
New-MiLink @splatNewMiLink




# Cutover Mi Link
$splatMiLinkCutover = @{
    ResourceGroupName = "dbatools"
    ManagedInstanceName = "dbatoolssqlmi"
    SqlInstance = "dbatoolsVM"
    #SqlManagedInstance = $dbatoolsAzSQLMI
    SqlManagedInstanceCredential = $dbatoolsAzSQLMIcred
    DatabaseName = "dbatools2"
    PrimaryAvailabilityGroup = "ag_basic"
    SecondaryAvailabilityGroup = "mi_basic" 
    LinkName = "dag_basic"
    CleanupPreference = "DELETE_AG_AND_DAG"
    ForcedCutover = $false
    WaitSecondsForSync = 60
    Verbose = $true
}
Invoke-MiLinkCutover @splatMiLinkCutover

