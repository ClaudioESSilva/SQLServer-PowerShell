$topic = "relational-databases"
$baseAdress = "https://opbuildstorageprod.blob.core.windows.net/output-pdf-files/en-us/SQL.sql-content/live/$topic"
$gitHubRepo = "https://github.com/MicrosoftDocs/sql-docs/tree/live/docs/$topic"

$outputDirectory = "d:\temp\MSDocs"

if (!(Test-Path $outputDirectory)) {
    Write-Warning "Output directory $outputDirectory does not exists."
    return
}

$response = Invoke-WebRequest $gitHubRepo
$webclient = New-Object System.Net.WebClient

#Download base file - current $topic value
Write-Output "Downloading root pdf file '$topic.pdf'"
$webclient.DownloadFile("$baseAdress.pdf", "$outputDirectory\$topic.pdf")

# Get all TOC e folder names (excluding 'media '). The folder name is the pdf file name
$fileName = $response.AllElements | Where-Object { $_.class -eq "content" -and $_.innerHTML -like "*href*" -and $_.outerText -notlike "*.md*" -and $_.outerText -notin ("media ")} | Select-Object -ExpandProperty outerText

#Number of files to iterate (helps with the progress bar)
$numberFiles = $fileName.Count
if ($numberFiles -gt 0) {

    for ($i=0; $i -lt $numberFiles; $i++)
    {
        $currentFile = $i + 1
        $file = "$($fileName[$i].Trim()).pdf"
        $url = "$baseAdress/$file"
        $fileDestination = "$outputDirectory\$file"

        Write-Progress -Activity "Downloading files" -Status "Downloading ($currentFile of $numberFiles) - $file" -PercentComplete (($i/$numberFiles)*100)

        try {
            $webclient.DownloadFile($url, $fileDestination)
        }
        catch {
            Write-Warning "Error downloading file $file from URL: $url."
        }
    }
}
else {
    Write-Output "No sub folders with files do download."
}
