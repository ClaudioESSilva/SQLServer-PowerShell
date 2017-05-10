$servers = Import-Csv "C:\ua\servers.txt" -Delimiter "`t" #tab
$UA = "${env:ProgramFiles(x86)}\Microsoft SQL Server 2008 Upgrade Advisor\UpgradeAdvisorWizardCmd.exe"

#runs to all server in the file
foreach ($srv in $servers) {
    $server = $srv.Server
    
    if ($srv.Instance.ToString().Trim() -eq "") {
        $instance = "MSSQLSERVER"
    }
    else {
        $instance = $srv.Instance
    }

    Write-Output "`nAnalysing Server: $server & Instance : $instance"
    & $UA -Server $server -Instance $instance -CSV
    
    Write-Output "`n"
}

Write-Output "Please go to your documents and find the 'SQL Server 2008 Upgrade Advisor Reports' folder there with the results"
Write-Output "You may want to use the Report Viewer to analyse the results"
