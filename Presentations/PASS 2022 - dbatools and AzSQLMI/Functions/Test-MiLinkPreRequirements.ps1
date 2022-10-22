#Requires -Modules dbatools
function Test-MiLinkPreRequirements {
    <#
    .SYNOPSIS
        Function that checks if all pre-requirements are met to be able to configure a new MI Link
    
    .DESCRIPTION
        This function will check if a set of pre-requirements are met to be able to create a MI Link.
        It relies on dbatools module (make sure you have a recent version installed)

        1. Check SQL Server version
        2. Create a database master key in the master database
        3. Enable availability groups
        4. Enable startup trace flags
        5. Restart SQL Server

        This is based on: https://learn.microsoft.com/en-us/azure/azure-sql/managed-instance/managed-instance-link-preparation?view=azuresql#prepare-your-sql-server-instance
        NOTE: This may change overtime and therefore keep in mind that can/will need some update.


    .PARAMETER SqlInstance
        The SQL Server instance where database you want to migrate to Azure SQL Managed Instance lives.
        It can be either - SQL Server OnPrem, SQL Server on Azure VM

    .PARAMETER SqlCredential
        Login to the target instance using alternative credentials. Accepts PowerShell credentials (Get-Credential).

        Windows Authentication, SQL Server Authentication, Active Directory - Password, and Active Directory - Integrated are all supported.

        For MFA support, please use Connect-DbaInstance.

    .PARAMETER SqlMIInstance
        The Azure SQL Managed Instance that will be the destination of the database you want to migrate.

    .PARAMETER SqlMICredential
        Login to the target instance using alternative credentials. Accepts PowerShell credentials (Get-Credential).

        Windows Authentication, SQL Server Authentication, Active Directory - Password, and Active Directory - Integrated are all supported.

        For MFA support, please use Connect-DbaInstance.


    .PARAMETER Database
        The database you want to migrate to Azure SQL Managed Instance.

    .PARAMETER FixPreRequirements
        If set to $true, the function will try to fix the pre-requirements that are not met.
        If set to $false, the function will only check if the pre-requirements are met and will not try to fix them.

    .PARAMETER SkipMasterKey
        If set to $true, the function will skip the check for the master key in the master database.
        If set to $false, the function will check if the master key in the master database is present.

    .PARAMETER SkipAgHadr
        If set to $true, the function will skip the check for HADR.
        If set to $false, the function will check if HADR are enabled.

    .PARAMETER SkipDatabase
        If set to $true, the function will skip the check for the database.
        If set to $false, the function will check if the database is present.

    .EXAMPLE
        Test-MiLinkPreRequirements -SqlInstance sql2016 -SqlMiInstance sqlmi01 -SqlMiCredential (Get-Credential sqlmi01)

        This will check if all pre-requirements of the OnPrem instance are met to be able to configure a new MI Link between sql2016 and sqlmi01
 
    .NOTES
        Author: Cláudio Silva (@claudioessilva), claudioeesilva.eu

        Based on: This is based on: https://learn.microsoft.com/en-us/azure/azure-sql/managed-instance/managed-instance-link-preparation?view=azuresql#prepare-your-sql-server-instance
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [DbaInstanceParameter]$SqlInstance,
        [PSCredential]$SqlCredential,
        [DbaInstanceParameter]$SqlMiInstance,
        [PSCredential]$SqlMiCredential,
        [string]$Database,
        [switch]$FixPreRequirements,
        [switch]$SkipMasterKey,
        [switch]$SkipAgHadr,
        [switch]$SkipTraceFlags,
        [Switch]$SkipDatabase
    )

    begin {

        #Pre-requirements
        #Import-Module dbatools -Force
    }

    process {

        # Check if destination is a Azure SQL Managed Instance
        $serverMI = Connect-DbaInstance -SqlInstance $SqlMiInstance -SqlCredential $SqlMiCredential
        if ($serverMI.IsAzure -and $serverMI.EngineEdition -eq "SqlManagedInstance") {
            Write-Verbose -Message "[OK] Destination is a Azure SQL Managed Instance"
        } else {
            throw "Destination ($SqlMiInstance) is not a Azure SQL Managed Instance"
        }

        # Collection of minimum patching level required depending on SQL Server version
        $minVersion2016 = [System.Version]"13.0.6300.2"
        $minVersion2016AzFeaturePack = [System.Version]"13.0.7000.253"

        # SQL Server 2019 CU15 or above for Enterprise and Developer Editions
        $minVersion2019WOStandard = [System.Version]"15.0.4198.2"
        
        # SQL Server 2019 CU17 or above for Standard Edition
        $minVersion2019WStandard = [System.Version]"15.0.4249.2"

        $server = Connect-DbaInstance -SqlInstance $SqlInstance -SqlCredential $SqlCredential

        if ($server.VersionMajor -lt '13' -or $server.VersionMajor -eq '14') {
            throw "SQL Server version $($server.Version) not supported. For more information please check: https://learn.microsoft.com/en-us/azure/azure-sql/managed-instance/managed-instance-link-preparation?view=azuresql#install-service-updates"
        } else {
            switch ($server.Version) {
                '13' { 
                        if ($server.Version -lt $minVersion2016) {
                            throw "SQL Server 2016 version ($($server.Version)) is not supported. For more information please check: https://learn.microsoft.com/en-us/azure/azure-sql/managed-instance/managed-instance-link-preparation?view=azuresql#install-service-updates"
                        } else {
                            if ($server.Version -lt $minVersion2016AzFeaturePack) {
                                throw "SQL Server 2016 version $($server.Version) is not supported. For more information please check: https://learn.microsoft.com/en-us/azure/azure-sql/managed-instance/managed-instance-link-preparation?view=azuresql#install-service-updates"
                            } else {
                                if ($server.EngineEdition -in ('Standard', 'Enterprise', 'Developer')) {
                                    Write-Verbose "[OK] SQL Server 2016 version $($server.Version) is supported"
                                } else {
                                    throw "SQL Server 2019 $($server.EngineEdition) edition is not supported. For more information please check: https://learn.microsoft.com/en-us/azure/azure-sql/managed-instance/managed-instance-link-preparation?view=azuresql#install-service-updates"
                                }
                            }
                        }
                }
                '16' { 
                    if ($server.Version -lt $minVersion2019WOStandard) {
                        throw "SQL Server 2019 version ($($server.Version)) is not supported. For more information please check: https://learn.microsoft.com/en-us/azure/azure-sql/managed-instance/managed-instance-link-preparation?view=azuresql#install-service-updates"
                    } else {
                        if ($server.Version -lt $minVersion2019WStandard) {
                            if ($server.EngineEdition -notin ('Enterprise', 'Developer')) {
                                throw "SQL Server 2019 $($server.EngineEdition) edition is not supported. For more information please check: https://learn.microsoft.com/en-us/azure/azure-sql/managed-instance/managed-instance-link-preparation?view=azuresql#install-service-updates"
                            } else {
                                Write-Verbose "[OK] SQL Server 2019 version $($server.Version) is supported"   
                            }
                        } else {
                            if ($server.EngineEdition -in ('Standard', 'Enterprise', 'Developer')) {
                                Write-Verbose "[OK] SQL Server 2019 version $($server.Version) is supported"
                            } else {
                                throw "SQL Server 2019 $($server.EngineEdition) edition is not supported. For more information please check: https://learn.microsoft.com/en-us/azure/azure-sql/managed-instance/managed-instance-link-preparation?view=azuresql#install-service-updates"
                            }
                        }
                    }
                }
            }
        }

        # Make sure that you have the database master key (source)
        if (-not $SkipMasterKey) {
            Write-Verbose "Checking if a Master Key exists"
            $masterKeyResult = Get-DbaDbMasterKey -SqlInstance $SqlInstance -SqlCredential $SqlCredential -Database "master"
            if (!$masterKeyResult) {
                Write-Warning "Database Master Key is missing."
                if ($FixPreRequirements) {
                    Write-Verbose " Creating new one"
                    New-DbaDbMasterKey -SqlInstance $SqlInstance -SqlCredential $SqlCredential -Database "master" -Confirm:$false -Verbose

                    $masterKeyResult = Get-DbaDbMasterKey -SqlInstance $SqlInstance -SqlCredential $SqlCredential -Database "master"
                    if (!$masterKeyResult) {
                        throw "Something happened! Master key wasn't created!"
                    } else {
                        Write-Verbose "Master Key was created successfully"
                    }
                } else {
                    Write-Verbose "Parameter -FixPreRequirements was not specified. Skipping creation of Master Key"
                }
            } else {
                Write-Verbose "[OK] There is already a master key."
            }
        } else {
            Write-Verbose "Parameter -SkipMasterKey was specified. Skipping check of Master Key"
        }

        # The link feature for SQL Managed Instance relies on the Always On Availability groups feature, which isn't enabled by default.
        if (-not $SkipAgHadr) {
            Write-Verbose "Checking if a Always On Availability Groups is enabled"
            $alwaysOnIsHadrEnabled = Get-DbaAgHadr -SqlInstance $SqlInstance -SqlCredential $SqlCredential | Select-Object -ExpandProperty IsHadrEnabled
            if ($alwaysOnIsHadrEnabled -eq $false) {
                Write-Warning "Always On is off"
                if ($FixPreRequirements) {
                    Write-Verbose "Enabling Always On"
                    
                    # Enable Hadr
                    Enable-DbaAgHadr -SqlInstance $SqlInstance -SqlCredential $SqlCredential -Confirm:$false -Verbose

                    Write-Verbose "Always On was enabled successfully"
                } else {
                    Write-Verbose "Parameter -FixPreRequirements was not specified. Skipping enable of Always On"
                }
            } else {
                Write-Verbose "[OK] Always On is enabled"
            }
        } else {
            Write-Verbose "Parameter -SkipAgHadr was specified. Skipping check of Always On"
        }

        # Enable startup trace flags - https://learn.microsoft.com/en-us/azure/azure-sql/managed-instance/managed-instance-link-preparation?view=azuresql#enable-startup-trace-flags
        if (-not $SkipTraceFlags) {
            Write-Verbose "Checking if a trace flags T1800 and T9567 are enabled"
            $traceFlags = Get-DbaTraceFlag -SqlInstance $SqlInstance -SqlCredential $SqlCredential -TraceFlag 1800, 9567 | Select-Object -ExpandProperty TraceFlag
            if ($traceFlags.Count -lt 2) {
                Write-Warning "Some recommend trace falgs are missing."
                if ($FixPreRequirements) {
                    Write-Verbose "Configuring trace flags"

                    # Set two trace flags
                    Set-DbaStartupParameter -SqlInstance $SqlInstance -SqlCredential $SqlCredential -TraceFlag 1800, 9567 -Confirm:$false -Verbose

                    # Restart SQL Server
                    Restart-DbaService -SqlInstance $SqlInstance -SqlCredential $SqlCredential -Type Engine -Confirm:$true

                    Write-Verbose "Trace flags were configured successfully"
                } else {
                    Write-Verbose "Parameter -FixPreRequirements was not specified. Skipping enable of trace flags"
                }
            } else {
                Write-Verbose "[OK] Trace flags are enabled"
            }
        } else {
            Write-Verbose "Parameter -SkipTraceFlags was specified. Skipping check of trace flags"
        }

        # To be possible to migrate the database using Mi Link, it needs to be in 'FULL' recovery model and have at least one full backup
        if (-not $SkipDatabase -and $Database) {
            $db = Get-DbaDatabase -SqlInstance $SqlInstance -SqlCredential $SqlCredential -Database $Database
            if ($db) {
                Write-Verbose "Checking if a database $($Database) exists and is in FULL recovery model"
                # Source database needs to be in FULL recovery model and have at least one backup.
                $recoveryModel = Get-DbaDbRecoveryModel -SqlInstance $SqlInstance -SqlCredential $SqlCredential -Database $Database | Select-Object -ExpandProperty RecoveryModel
                if ($recoveryModel -ne "Full") {
                    Write-Warning "Database $Database is not in 'FULL' recovery model."
                    if ($FixPreRequirements) {
                        Write-Verbose "Setting recovery model to FULL"
                        Set-DbaRecoveryModel -SqlInstance $SqlInstance -SqlCredential $SqlCredential -Database $Database -RecoveryModel FULL -Confirm:$false -Verbose
                        Write-Verbose "Recovery model was set to FULL successfully"
                    } else {
                        Write-Verbose "Parameter -FixPreRequirements was not specified. Skipping setting recovery model to 'FULL'.  Please change it to 'FULL' and do at least one backup and try again."
                    }
                } else {
                    Write-Verbose "[OK] Database $($Database) recovery model is 'FULL'"
                }

                # Check if database has at least one full backup
                $backupHistory = Get-DbaDbBackupHistory -SqlInstance $SqlInstance -SqlCredential $SqlCredential -Database $Database
                if ($backupHistory.Count -eq 0) {
                    Write-Warning "Database $Database has no backups. Please do a 'FULL' backup and try again."
                }
            } else {
                Write-Warning "Database $Database does not exist."
            }
        } else {
            Write-Verbose "Parameter -SkipDatabase was specified or -Database wasn't. Skipping check of database recovery model and backups"
        }
    }
}