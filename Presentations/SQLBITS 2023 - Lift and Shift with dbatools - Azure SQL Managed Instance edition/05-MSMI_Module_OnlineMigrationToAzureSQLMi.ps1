<#
    Creates the Mi Link between on prem and Azure SQL Managed Instance

    PowerShell Az.Sql module version 3.9.0 or newer.
    PowerShell Az.Accounts module version 2.8.0 or newer.
    SqlServer module version 21.1.18256 or newer.
    dbatools

    Instructions:
        Start-Process "https://techcommunity.microsoft.com/t5/modernization-best-practices-and/automating-the-setup-of-azure-sql-managed-instance-link/ba-p/3696961"
#>

Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope Process
Import-Module 'C:\Temp\MiLinkAutomation_v1\MiLinkSetup.ps1' -Force


$SqlInstance = "localhost"
$SqlMIInstance = "<your MI name>"

#Pre-requirements not done by MS module (example)
ValidateAndPrepareMiLinkSetup -SqlInstance $SqlInstance -ManagedInstanceName $SqlMIInstance


$splatCreateMILink = @{
    SqlInstance = $SqlInstance
    ManagedInstanceName = $SqlMIInstance
    DatabaseNameList = "sqlbits"
    BackupPathLocation = “C:\temp”
    Verbose = $true
}
CreateMiLink @splatCreateMILink


<#
    Load the function Invoke-MiLinkCutover.
    NOTE: This is a custom function, not part of the MS module.
    NOTE2: MS may make available a new function as part of their module.
#>
. ".\Functions\Invoke-MiLinkCutover.ps1"

# Cutover Mi Link
$splatMiLinkCutover = @{
    ResourceGroupName = "dbatools"
    ManagedInstanceName = "dbatoolsmi"
    SqlInstance = "dbatoolsVM"
    #SqlManagedInstance = $dbatoolsAzSQLMI
    SqlManagedInstanceCredential = $dbatoolsAzSQLMIcred
    DatabaseName = "sqlbits"
    PrimaryAvailabilityGroup = "sqlbits_LINK_AG"
    SecondaryAvailabilityGroup = "dbatoolsmi"
    LinkName = "sqlbits_LINK_DAG"
    CleanupPreference = "DELETE_AG_AND_DAG"
    ForcedCutover = $false
    WaitSecondsForSync = 60
    Verbose = $true
}
Invoke-MiLinkCutover @splatMiLinkCutover
















Clear-AzContext -Scope CurrentUser -Force;
Disconnect-AzAccount;