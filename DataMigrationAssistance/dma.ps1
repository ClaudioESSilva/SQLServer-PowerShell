#& "${env:ProgramFiles}\Microsoft Data Migration Assistant\DmaCmd.exe" /AssessmentName="TestAssessment" /AssessmentDatabases="Server=SQL2000;Initial Catalog=pubs;Integrated Security=true" /AssessmentTargetPlatform="SqlServer2016" /AssessmentEvaluateCompatibilityIssues /AssessmentOverwriteResult /AssessmentResultCsv="C:\temp\Results\AssessmentReport2000.csv" /AssessmentResultJson="C:\temp\results\test2000.json"
$servers = Import-Csv "C:\dma\servers.txt" -Delimiter "`t" #tab

$resultFolder = "C:\temp\results"

#passar todos os servidores e bases de dados da lista
foreach ($srv in $servers) {
    $instance = $srv.Server
    $database = $srv.Database

    $fileDate = Get-Date -Format "yyyymmdd-HHmmss"

    $resultFileName = "$($database.replace('\','_'))_$fileDate"
    $resultFullPath = "$resultFolder\$($instance.replace('\','_'))\$($database.replace('\','_'))"
    
    New-Item -Path $resultFullPath -ItemType Directory -Force

    & "${env:ProgramFiles}\Microsoft Data Migration Assistant\DmaCmd.exe" /AssessmentName="TestAssessment" /AssessmentDatabases="Server=$instance;Initial Catalog=$database;Integrated Security=true" /AssessmentTargetPlatform="SqlServer2016" /AssessmentEvaluateCompatibilityIssues /AssessmentOverwriteResult /AssessmentResultCsv="$resultFullPath\$resultFileName.csv" /AssessmentResultJson="$resultFullPath\$resultFileName.json"
}


