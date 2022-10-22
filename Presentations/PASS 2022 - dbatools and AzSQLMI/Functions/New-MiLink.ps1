function New-MiLink {
    <#
    .SYNOPSIS
        Creates a new instance link between SQL Server (primary) and SQL managed instance (secondary)
    
    .DESCRIPTION
        Creates a new instance link between SQL Server (primary) and SQL managed instance (secondary)
    
    .PARAMETER SqlInstance
        The SQL Server instance where database you want to migrate to Azure SQL Managed Instance lives.
        It can be either - SQL Server OnPrem, SQL Server on Azure VM

    .PARAMETER SqlCredential
        Login to the target instance using alternative credentials. Accepts PowerShell credentials (Get-Credential).

        Windows Authentication, SQL Server Authentication, Active Directory - Password, and Active Directory - Integrated are all supported.

        For MFA support, please use Connect-DbaInstance.

    .PARAMETER SqlManagedInstance
        The Azure SQL Managed Instance where database you want to migrate to Azure SQL Managed Instance lives.
        It can be either - SQL Server OnPrem, SQL Server on Azure VM

    .PARAMETER SqlManagedInstanceCredential
        Login to the target instance using alternative credentials. Accepts PowerShell credentials (Get-Credential).

        Windows Authentication, SQL Server Authentication, Active Directory - Password, and Active Directory - Integrated are all supported.

        For MFA support, please use Connect-DbaInstance.

    .PARAMETER ResourceGroupName
        Resource group name of Managed Instance 
    
    .PARAMETER ManagedInstanceName
        Azure SQL Managed Instance Name

    .PARAMETER DatabaseName
        Name of the database to be migrated

    .PARAMETER SourceIP
        Source IP address of the on-prem SQL Server. If you are running SQL Server on a Azure VM, this parameter is not required as we will auto-dected the value.
    
    .PARAMETER PrimaryAvailabilityGroup
        Primary availability group name
    
    .PARAMETER SecondaryAvailabilityGroup
        Secondary availability group name
    
    .PARAMETER LinkName
        Instance link name
        
    .EXAMPLE
        # Remove-Module New-MiLink
        # Import-Module 'C:\{pathtoscript}\New-MiLink.ps1'
        New-MiLink -ResourceGroupName CustomerExperienceTeam_RG -SqlManagedInstance chimera-ps-cli-v2 `
        -SqlInstance chimera -DatabaseName basic -PrimaryAvailabilityGroup ag_basic -SecondaryAvailabilityGroup mi_basic -LinkName dag_basic  -Verbose 
    
    .NOTES
        Author: Cláudio Silva (@claudioessilva), claudioeesilva.eu

        Based on:
            This script was adapted from the MS original one: https://github.com/microsoft/Azure-Managed-Instance-Link/blob/main/cmdlets/dbatools/New-MiLink.ps1
        
        Pre-requirements:
            - Install-Module dbatools -MinimumVersion 1.1.137 -Force
            - Install-Module Az.Sql -MinimumVersion 3.9.0 -Force
            - Install-Module Az.Compute
            - Install-Module Az.Accounts
            - Install-Module Az.Network

        Other Resources (how to):
            https://learn.microsoft.com/en-us/azure/azure-sql/managed-instance/managed-instance-link-feature-overview?view=azuresql
            https://techcommunity.microsoft.com/t5/azure-sql-blog/managed-instance-link-connecting-sql-server-to-azure-reimagined/ba-p/2911614

            - With SSMS
                - Configure Link MI: https://learn.microsoft.com/en-us/azure/azure-sql/managed-instance/managed-instance-link-use-ssms-to-replicate-database?view=azuresql
                - Fail over a database: https://learn.microsoft.com/en-us/azure/azure-sql/managed-instance/managed-instance-link-use-ssms-to-failover-database?view=azuresql
            - With scripts
                - Configure Link MI: https://learn.microsoft.com/en-us/azure/azure-sql/managed-instance/managed-instance-link-use-scripts-to-replicate-database?view=azuresql 
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter(Mandatory = $true, HelpMessage = 'Enter resource group name')]
        [string]$ResourceGroupName,

        [Parameter(Mandatory = $true, HelpMessage = 'Enter SQL managed instance name')]
        [string]$ManagedInstanceName,
        
        [Parameter(Mandatory = $true, HelpMessage = 'Enter SQL Server name')]
        [DbaInstanceParameter]$SqlInstance,

        [Parameter(Mandatory = $false, HelpMessage = 'Enter a PS Credential to connect to $SqlInstance server')]
        [PSCredential]$SqlCredential,

        [Parameter(Mandatory = $true, HelpMessage = 'Enter SQL Server name')]
        [DbaInstanceParameter]$SqlManagedInstance,

        [Parameter(Mandatory = $true, HelpMessage = 'Enter a PS Credential to connect to $SqlManagedInstance server')]
        [PSCredential]$SqlManagedInstanceCredential,

        [Parameter(Mandatory = $true, HelpMessage = 'Enter target database name')]
        [string]$DatabaseName,

        [Parameter(Mandatory = $false, HelpMessage = 'Enter source IP address. If you are on Azure VM, you don''t need this parameter')]
        [string]$SourceIP,

        [Parameter(Mandatory = $true, HelpMessage = 'Enter primary availability group name')]
        [string]$PrimaryAvailabilityGroup,

        [Parameter(Mandatory = $true, HelpMessage = 'Enter primary availability group name')]
        [string]$SecondaryAvailabilityGroup,

        [Parameter(Mandatory = $true, HelpMessage = 'Enter instance link name')]
        [string]$LinkName
    )

    process {

        Write-Verbose "Import Azure-trusted root certificates authority keys to SQL Server - MicrosoftPKI & DigiCertPKI"
        #Import Azure-trusted root certificate authority keys to SQL Server
        $queryCreateCertificates = @"
CREATE CERTIFICATE [MicrosoftPKI] FROM BINARY = 0x308205A830820390A00302010202101ED397095FD8B4B347701EAABE7F45B3300D06092A864886F70D01010C05003065310B3009060355040613025553311E301C060355040A13154D6963726F736F667420436F72706F726174696F6E313630340603550403132D4D6963726F736F66742052534120526F6F7420436572746966696361746520417574686F726974792032303137301E170D3139313231383232353132325A170D3432303731383233303032335A3065310B3009060355040613025553311E301C060355040A13154D6963726F736F667420436F72706F726174696F6E313630340603550403132D4D6963726F736F66742052534120526F6F7420436572746966696361746520417574686F72697479203230313730820222300D06092A864886F70D01010105000382020F003082020A0282020100CA5BBE94338C299591160A95BD4762C189F39936DF4690C9A5ED786A6F479168F8276750331DA1A6FBE0E543A3840257015D9C4840825310BCBFC73B6890B6822DE5F465D0CC6D19CC95F97BAC4A94AD0EDE4B431D8707921390808364353904FCE5E96CB3B61F50943865505C1746B9B685B51CB517E8D6459DD8B226B0CAC4704AAE60A4DDB3D9ECFC3BD55772BC3FC8C9B2DE4B6BF8236C03C005BD95C7CD733B668064E31AAC2EF94705F206B69B73F578335BC7A1FB272AA1B49A918C91D33A823E7640B4CD52615170283FC5C55AF2C98C49BB145B4DC8FF674D4C1296ADF5FE78A89787D7FD5E2080DCA14B22FBD489ADBACE479747557B8F45C8672884951C6830EFEF49E0357B64E798B094DA4D853B3E55C428AF57F39E13DB46279F1EA25E4483A4A5CAD513B34B3FC4E3C2E68661A45230B97A204F6F0F3853CB330C132B8FD69ABD2AC82DB11C7D4B51CA47D14827725D87EBD545E648659DAF5290BA5BA2186557129F68B9D4156B94C4692298F433E0EDF9518E4150C9344F7690ACFC38C1D8E17BB9E3E394E14669CB0E0A506B13BAAC0F375AB712B590811E56AE572286D9C9D2D1D751E3AB3BC655FD1E0ED3740AD1DAAAEA69B897288F48C407F852433AF4CA55352CB0A66AC09CF9F281E1126AC045D967B3CEFF23A2890A54D414B92AA8D7ECF9ABCD255832798F905B9839C40806C1AC7F0E3D00A50203010001A3543052300E0603551D0F0101FF040403020186300F0603551D130101FF040530030101FF301D0603551D0E0416041409CB597F86B2708F1AC339E3C0D9E9BFBB4DB223301006092B06010401823715010403020100300D06092A864886F70D01010C05000382020100ACAF3E5DC21196898EA3E792D69715B813A2A6422E02CD16055927CA20E8BAB8E81AEC4DA89756AE6543B18F009B52CD55CD53396D624C8B0D5B7C2E44BF83108FF3538280C34F3AC76E113FE6E3169184FB6D847F3474AD89A7CEB9D7D79F846492BE95A1AD095333DDEE0AEA4A518E6F55ABBAB59446AE8C7FD8A2502565608046DB3304AE6CB598745425DC93E4F8E355153DB86DC30AA412C169856EDF64F15399E14A75209D950FE4D6DC03F15918E84789B2575A94B6A9D8172B1749E576CBC156993A37B1FF692C919193E1DF4CA337764DA19FF86D1E1DD3FAECFBF4451D136DCFF759E52227722B86F357BB30ED244DDC7D56BBA3B3F8347989C1E0F20261F7A6FC0FBB1C170BAE41D97CBD27A3FD2E3AD19394B1731D248BAF5B2089ADB7676679F53AC6A69633FE5392C846B11191C6997F8FC9D66631204110872D0CD6C1AF3498CA6483FB1357D1C1F03C7A8CA5C1FD9521A071C193677112EA8F880A691964992356FBAC2A2E70BE66C40C84EFE58BF39301F86A9093674BB268A3B5628FE93F8C7A3B5E0FE78CB8C67CEF37FD74E2C84F3372E194396DBD12AFBE0C4E707C1B6F8DB332937344166DE8F4F7E095808F965D38A4F4ABDE0A308793D84D00716245274B3A42845B7F65B76734522D9C166BAAA8D87BA3424C71C70CCA3E83E4A6EFB701305E51A379F57069A641440F86B02C91C63DEAAE0F84

--Trust certificates issued by Microsoft PKI root authority for Azure database.windows.net domains
DECLARE @CERTID int
SELECT @CERTID = CERT_ID('MicrosoftPKI')
EXEC sp_certificate_add_issuer @CERTID, N'*.database.windows.net'
GO

CREATE CERTIFICATE [DigiCertPKI] FROM BINARY = 0x3082038E30820276A0030201020210033AF1E6A711A9A0BB2864B11D09FAE5300D06092A864886F70D01010B05003061310B300906035504061302555331153013060355040A130C446967694365727420496E6331193017060355040B13107777772E64696769636572742E636F6D3120301E06035504031317446967694365727420476C6F62616C20526F6F74204732301E170D3133303830313132303030305A170D3338303131353132303030305A3061310B300906035504061302555331153013060355040A130C446967694365727420496E6331193017060355040B13107777772E64696769636572742E636F6D3120301E06035504031317446967694365727420476C6F62616C20526F6F7420473230820122300D06092A864886F70D01010105000382010F003082010A0282010100BB37CD34DC7B6BC9B26890AD4A75FF46BA210A088DF51954C9FB88DBF3AEF23A89913C7AE6AB061A6BCFAC2DE85E092444BA629A7ED6A3A87EE054752005AC50B79C631A6C30DCDA1F19B1D71EDEFDD7E0CB948337AEEC1F434EDD7B2CD2BD2EA52FE4A9B8AD3AD499A4B625E99B6B00609260FF4F214918F76790AB61069C8FF2BAE9B4E992326BB5F357E85D1BCD8C1DAB95049549F3352D96E3496DDD77E3FB494BB4AC5507A98F95B3B423BB4C6D45F0F6A9B29530B4FD4C558C274A57147C829DCD7392D3164A060C8C50D18F1E09BE17A1E621CAFD83E510BC83A50AC46728F67314143D4676C387148921344DAF0F450CA649A1BABB9CC5B1338329850203010001A3423040300F0603551D130101FF040530030101FF300E0603551D0F0101FF040403020186301D0603551D0E041604144E2254201895E6E36EE60FFAFAB912ED06178F39300D06092A864886F70D01010B05000382010100606728946F0E4863EB31DDEA6718D5897D3CC58B4A7FE9BEDB2B17DFB05F73772A3213398167428423F2456735EC88BFF88FB0610C34A4AE204C84C6DBF835E176D9DFA642BBC74408867F3674245ADA6C0D145935BDF249DDB61FC9B30D472A3D992FBB5CBBB5D420E1995F534615DB689BF0F330D53E31E28D849EE38ADADA963E3513A55FF0F970507047411157194EC08FAE06C49513172F1B259F75F2B18E99A16F13B14171FE882AC84F102055D7F31445E5E044F4EA879532930EFE5346FA2C9DFF8B22B94BD90945A4DEA4B89A58DD1B7D529F8E59438881A49E26D56FADDD0DC6377DED03921BE5775F76EE3C8DC45D565BA2D9666EB33537E532B6

--Trust certificates issued by DigiCert PKI root authority for Azure database.windows.net domains
DECLARE @CERTID int
SELECT @CERTID = CERT_ID('DigiCertPKI')
EXEC sp_certificate_add_issuer @CERTID, N'*.database.windows.net'
"@
        Invoke-DbaQuery -SqlInstance $SqlInstance -SqlCredential $SqlCredential -Query $queryCreateCertificates
        Write-Verbose "Azure-trusted root certificates (MicrosoftPKI & DigiCertPKI) imported successfully."


        # Test connectivity to Azure SQL MI (port: 5022)
        Write-Verbose "Getting MI - $ManagedInstanceName - info"
        $instance = Get-AzSqlInstance -ResourceGroupName $ResourceGroupName -Name $ManagedInstanceName
        $miFQDN = $instance.FullyQualifiedDomainName
        # Create tcp connection string for Azure SQL MI
        $SqlMiInstanceConnectionString = "tcp://$($miFQDN):5022;Server=[$ManagedInstanceName]"
        Write-Verbose "MI FQDN: $miFQDN - MI Connection String: $SqlMiInstanceConnectionString"


        Write-Verbose "Test connectivity [started]"
        $testSqlMiConn = Test-NetConnection -ComputerName $miFQDN -Port 5022
        if ($testSqlMiConn.TcpTestSucceeded -eq $False) {
            throw "Can't establish TCP connection to specified MI. Please run Initialize-MiLinkEnvironment"
        }
        Write-Verbose "Test connectivity [completed]"

        

        if (!$SourceIP) {
            # Figure out if we're on a VM https://docs.microsoft.com/en-us/azure/virtual-machines/windows/instance-metadata-service?tabs=windows#example-scenarios-for-usage
            Write-Verbose "Parameter -SourceIP was not provided, assuming we are on a Azure VM instead. Getting VM info..."
            $vmMetadata = Invoke-RestMethod -Headers @{"Metadata" = "true" } -Method GET -Uri "http://169.254.169.254/metadata/instance?api-version=2021-02-01" 
            if ($vmMetadata) {
                $vmName = $vmMetadata.psobject.properties['compute'].value.name
                $vmRgName = $vmMetadata.psobject.properties['compute'].value.resourceGroupName
                $vm = Get-AzVm -ResourceGroupName $vmRgName -Name $vmName
                $nic = $vm.NetworkProfile.NetworkInterfaces[0] # TODO we can have more?
                $networkinterface = ($nic.id -split '/')[-1]
                $nicdetails = Get-AzNetworkInterface -Name $networkinterface
                
                # Grab the private ip of the server
                $srcIP = $nicdetails.IpConfigurations[0].PrivateIpAddress
                $sourceEndpoint = "tcp://$($srcIP):5022"
                Write-Verbose "Using $sourceEndpoint as source endpoint for the link."
            } else {
                throw "Parameter -SourceIP was not provided and we couldn't get metadata from Azure VM. Exiting..."
            }
        } else {
            $sourceEndpoint = "tcp://$($SourceIP):5022"
            Write-Verbose "Using $sourceEndpoint as source endpoint for the link."
        }

        # TODO:
        # check if managed instance has <100 DBs
        # Check if MI has enough storage

        # Query to get Endpoint Certificate Public Key
        $queryGetEnpointCert = "EXEC sp_get_endpoint_certificate @endpoint_type = 4"


        # TODO: If we don't have DBM endpoint, we have to create it
        # we can either create a new certificate for that purpose, or pick an existing one if it meets certain conditions such as:
        # - "select pvt_key_encryption_type from sys.certificates where name = N'$boxCertName'" must be MK
        # TODO: can we trust sp_get_endpoint_certificate ?
        Write-Verbose "Validate DBM endpoint certificate [started]"
        $dbmCert = Invoke-DbaQuery -SqlInstance $SqlInstance -SqlCredential $SqlCredential -Query $queryGetEnpointCert
        if (!$dbmCert) {
            $boxCertName = Read-Host "Creating a new certificate for DBM Endpoint. Enter cert name: "
            $boxCertSubject = Read-Host "Enter cert subject: "

            $splatNewCertificate = @{
                SqlInstance = $SqlInstance
                SqlCredential = $SqlCredential
                Database = "master"
                Name = $boxCertName
                Subject = $boxCertSubject
                ExpirationDate = $((Get-Date).AddYears(10).ToString("dd/MM/yyyy"))
            }
            New-DbaDbCertificate @splatNewCertificate
        }
        Write-Verbose "Validate DBM endpoint certificate [completed]"

        # Check if theres a DBM endpoint, whose cert is signed with MK
        Write-Verbose "Validate DBM endpoint [started]"
        $endpointDBM = Get-DbaEndpoint -SqlInstance $SqlInstance -SqlCredential $SqlCredential -Type DatabaseMirroring
        if (!$endpointDBM) {
            Write-Warning "No valid endpoint found. Creating one..."

            # Create a new Endpoint with the certificate
            New-DbaEndpoint -SqlInstance $SqlInstance -SqlCredential $SqlCredential -Name "dbm_endpoint" -Protocol Tcp -Port 5022 -Type DatabaseMirroring -Role All -Certificate $boxCertName -EndpointEncryption Required -EncryptionAlgorithm Aes

            # Start the endpoint
            Write-Warning "Starting endpoint..."
            Start-DbaEndpoint -SqlInstance $SqlInstance -SqlCredential $SqlCredential -Endpoint "dbm_endpoint"
        }
        Write-Verbose "Validate DBM endpoint certificate [completed]"

        # Fetch the public key of the authentication certificate from Managed Instance and import it to SQL Server
        Write-Verbose "Import MI DBM endpoint certificate into SQL Server [started]"

        # Get the array of bytes of the endpoint
        $EndpointCertificatePublicKey = Invoke-DbaQuery -SqlInstance $SqlManagedInstance -SqlCredential $SqlManagedInstanceCredential -Query $queryGetEnpointCert | Select-Object -ExpandProperty EndpointCertificatePublicKey

        # Converting from Byte to Hex string
        $outString = "0x"
        $EndpointCertificatePublicKey | ForEach-Object { $outString += ("{0:X}" -f $_).PadLeft(2, "0") }
        $EndpointCertificatePublicKey = $outString

        # Check if the cert is already imported
        $AzureMICertName = "AzureSQLMI"
        $miCertInSqlServer = Get-DbaDbCertificate -SqlInstance $SqlInstance -SqlCredential $SqlCredential -Certificate $AzureMICertName
        if (!$miCertInSqlServer) {
            Write-Warning "Certificate not found. Creating it"

            # Create the certificate on local SQL Server
            $queryCreateLocalMiCertificates = "CREATE CERTIFICATE [$AzureMICertName] FROM BINARY = $EndpointCertificatePublicKey"
            Invoke-DbaQuery -SqlInstance $SqlInstance -SqlCredential $SqlCredential -Query $queryCreateLocalMiCertificates
        }
        else {
            Write-Verbose "Certificate $AzureMICertName already exists on $SqlInstance"
        }


        # Fetch the public key of SQL Server authentication certificate (outputs a binary key)
        Write-Verbose "Export SQL server DBM endpoint certificate to MI [started]"
        # Get the public key from the SQL Server and import to Azure SQL MI

        # Get the array of bytes of the endpoint
        $onPremEndpointCertificatePublicKey = Invoke-DbaQuery -SqlInstance $SqlInstance -SqlCredential $SqlCredential -Query $queryGetEnpointCert | Select-Object -ExpandProperty EndpointCertificatePublicKey
        # Converting from Byte to Hex string
        $outString = "0x"
        $onPremEndpointCertificatePublicKey | ForEach-Object { $outString += ("{0:X}" -f $_).PadLeft(2, "0") }
        $onPremEndpointCertificatePublicKey = $outString

        # Create the certificate on local SQL Server
        $onPremMICertName = "DBM_Certificate_$SqlInstance"
        $miCertInSqlServer = Get-DbaDbCertificate -SqlInstance $SqlManagedInstance -SqlCredential $SqlManagedInstanceCredential -Certificate $AzureMICertName
        if (!$miCertInSqlServer) {
            $queryCreateLocalMiCertificates = "CREATE CERTIFICATE [$onPremMICertName] FROM BINARY = $onPremEndpointCertificatePublicKey"
            Invoke-DbaQuery -SqlInstance $SqlManagedInstance -SqlCredential $SqlManagedInstanceCredential -Query $queryCreateLocalMiCertificates
        }
        else {
            Write-Verbose "Certificate $onPremMICertName already exists on $AzureSQLMI"
        }
        Write-Verbose "Export SQL server DBM endpoint certificate to MI [completed]"

        Write-Verbose "Creating AG on local SQL server [started]"
        $onPremServer = Connect-DbaInstance -SqlInstance $SqlInstance -SqlCredential $SqlCredential -DisableException

        # Create AG
        $agName = "ag_basic"
        $splatAG = @{
            Primary = $onPremServer
            Name = "ag_basic"
            Database = $DatabaseName
            ClusterType = "None"
            SeedingMode = "Automatic"
            FailoverMode = "Manual"
            EndpointUrl = $sourceEndpoint
            Confirm = $false
        }
        New-DbaAvailabilityGroup @splatAG

        Write-Verbose "Creating AG on local SQL server [completed]"

        # Create DAG - dbatools doesn't support this yet
        Write-Verbose "Creating DAG on local SQL server [started]"
        $queryDAG = @"
CREATE AVAILABILITY GROUP [$LinkName]
WITH (DISTRIBUTED)
AVAILABILITY GROUP ON
N'$agName' WITH (LISTENER_URL = N'$sourceEndpoint', AVAILABILITY_MODE = ASYNCHRONOUS_COMMIT, FAILOVER_MODE = MANUAL, SEEDING_MODE = AUTOMATIC),
N'$SecondaryAvailabilityGroup' WITH (LISTENER_URL = N'$SqlMiInstanceConnectionString', AVAILABILITY_MODE = ASYNCHRONOUS_COMMIT, FAILOVER_MODE = MANUAL, SEEDING_MODE = AUTOMATIC);
"@
        Invoke-DbaQuery -SqlInstance $SqlInstance -SqlCredential $SqlCredential -Query $queryDAG
        Write-Verbose "Creating DAG on local SQL server [completed]"

        # join the distributed Availability Group on SQL Server
        Write-Verbose "Create mi link [started]"

        $existingMI = Get-AzSqlInstanceLink -InstanceObject $instance -Name $LinkName -ErrorAction SilentlyContinue
        if (!$existingMI) {
            $splatAzSqlInstanceLink = @{
                InstanceObject = $instance 
                Name = $LinkName 
                PrimaryAvailabilityGroupName = $PrimaryAvailabilityGroup
                SecondaryAvailabilityGroupName = $SecondaryAvailabilityGroup 
                TargetDatabase = $DatabaseName 
                SourceEndpoint = $sourceEndpoint 
                AsJob = $true
            }
            $newLinkJob = New-AzSqlInstanceLink @splatAzSqlInstanceLink

            Start-Sleep -Seconds 2

            $queryMonitor1 =
                    @"
SELECT
ag.local_database_name AS 'Local database name',
ar.current_state AS 'Current state',
ar.is_source AS 'Is source',
ag.internal_state_desc AS 'Internal state desc',
ag.database_size_bytes / 1024 / 1024 AS 'Database size MB',
ag.transferred_size_bytes / 1024 / 1024 AS 'Transferred MB',
ag.transfer_rate_bytes_per_second / 1024 / 1024 AS 'Transfer rate MB/s',
ag.total_disk_io_wait_time_ms / 1000 AS 'Total Disk IO wait (sec)',
ag.total_network_wait_time_ms / 1000 AS 'Total Network wait (sec)',
ag.is_compression_enabled AS 'Compression',
ag.start_time_utc AS 'Start time UTC',
ag.estimate_time_complete_utc as 'Estimated time complete UTC',
ar.completion_time AS 'Completion time',
ar.number_of_attempts AS 'Attempt No'
FROM sys.dm_hadr_physical_seeding_stats AS ag
INNER JOIN sys.dm_hadr_automatic_seeding AS ar
ON local_physical_seeding_id = operation_id
"@

                    $queryMonitor2 = 
                    @"
SELECT DISTINCT CONVERT(VARCHAR(8), DATEADD(SECOND, DATEDIFF(SECOND, start_time_utc, estimate_time_complete_utc) ,0), 108) as 'Estimated complete time'
FROM sys.dm_hadr_physical_seeding_stats
"@

            $tries = 0
            Get-Job -Id $newLinkJob.Id | Tee-Object -Variable getJobLink
            while (($getJobLink.State -eq "Running") -and ($tries -le 7)) {
                Write-Verbose "Checking if link creation is completed, try #$tries"
                Start-Sleep -Seconds 7
                $tries = $tries + 1
                Invoke-DbaQuery -SqlInstance $SqlInstance -SqlCredential $SqlCredential -Query $queryMonitor1
                Invoke-DbaQuery -SqlInstance $SqlInstance -SqlCredential $SqlCredential -Query $queryMonitor2
                Get-Job -Id $newLinkJob.Id | Tee-Object -Variable getJobLink
                try {
                    Get-AzSqlInstanceLink -InstanceObject $instance -Name $LinkName | Tee-Object -Variable getLinkResp
                    if ($getLinkResp -and ($getLinkResp.LinkState -eq "Catchup")) {
                        break
                    }
                }
                catch {
                    Write-Verbose $_
                }
            }
            if ($tries -ge 7) {
                Write-Verbose "Script finishing, instance link not yet fully established. Use following commands and TSQL for monitoring:"
                Write-Verbose 'Get-AzSqlInstanceLink -InstanceObject $instance -Name $LinkName'
                Write-Verbose "$queryMonitor1"
                Write-Verbose "$queryMonitor2"
                Write-Verbose "Get-Job -Id $($newLinkJob.Id) | Receve-Job "
            }
            else {   
                Write-Verbose "Create mi link [completed]"
                Receive-Job -Id $newLinkJob.Id
                Get-AzSqlInstanceLink -InstanceObject $instance -Name $LinkName
            }
        } else {
            throw "MiLink already exists"
        }
    }
}
