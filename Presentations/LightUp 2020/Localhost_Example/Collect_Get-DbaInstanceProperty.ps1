#Central Server
Import-Module dbatools -Force

Set-DbaToolsConfig -Name 'psremoting.pssession.usessl' -Value $true
Set-DbaToolsConfig -Name 'psremoting.pssessionoption.includeportinspn' -Value $true

$centralServer = "localhost"
$centralDatabase = "dbatools"

#$ServerList = Invoke-DbaQuery -SqlInstance $centralServer -Database $centralDatabase -Query "SELECT ConnString FROM vGetInstances WHERE DOMAIN LIKE '$env:UserDomain%' ORDER BY 1" | Select-Object -ExpandProperty ConnString

$ServerList = "localhost"

function Invoke-TransposeDataTable {
    param (
        [Data.Datatable]$inputDatatable
    )

    [Data.DataTable]$outputTable = New-Object Data.DataTable

    # Add columns by looping rows

    # Header row's first column is same as in inputTable
    $null = $outputTable.Columns.Add($dt.Columns[0].ColumnName.ToString());

    # Header row's second column onwards, '$inputDatatable's first column taken
    foreach ($inRow in $inputDatatable.Rows)
    {
        [string]$newColName = $inRow["Name"].ToString();
        $null = $outputTable.Columns.Add($newColName);
    }

    [Data.DataRow] $newRow = $outputTable.NewRow();
    # First column is $inputDatatable's Header row's second column
    $newRow[0] = $inputDatatable.Rows[0][0].ToString();
    for ($cCount = 0; $cCount -le $inputDatatable.Rows.Count - 1; $cCount++)
    {
        [string]$colValue = $inputDatatable.Rows[$cCount]["Value"].ToString();
        $newRow[$cCount + 1] = $colValue;
    }
    $null = $outputTable.Rows.Add($newRow);

    return $outputTable;
}

#region InstanceProperty
[Data.Datatable]$newDataTable = New-Object Data.Datatable

$ServerList.ForEach{
    $dt = Get-DbaInstanceProperty -SqlInstance $psitem | ConvertTo-DbaDataTable
    $dt = Invoke-TransposeDataTable -inputDatatable $dt | ConvertTo-DbaDataTable

    if ($newDataTable.Columns.Count -eq 0) {
        $newDataTable = $dt.Clone()
    }
    $newDataTable.ImportRow($dt.Rows[0])
}

$newDataTable | Add-Member -MemberType NoteProperty -Name CollectionTime -Value $(Get-Date)
$newDataTable | OGV
#Write-DbaDataTable -SqlInstance $centralServer -Database $centralDatabase -Table "[InstanceProperty]" -Schema "dbo" -AutoCreateTable
#endregion




