function Convert-FolderContentToMarkdownTableOfContents{
    param (
        [string]$BaseFolder,
        [string]$BaseURL,
        [string]$FiletypeFilter
    )
 
    $nl = [System.Environment]::NewLine
    $TOC = "## Index$nl"
 
    $repoFolderStructure = Get-ChildItem -Path $BaseFolder -Directory | Where-Object Name -NotLike "*.github*"
 
    foreach ($dir in ($repoFolderStructure | Sort-Object -Property Name)) {
        $repoStructure = Get-ChildItem -Path $dir.FullName -Filter $FiletypeFilter
 
        $TOC += "* $($dir.Name) $nl"
 
        foreach ($md in ($repoStructure | Sort-Object -Property Name)) {
            $suffix = $($md.Directory.ToString().Replace($BaseFolder, [string]::Empty)).Replace("\", "/")
            $fileName = $($md.Name.TrimEnd($md.Extension))
            $TOC += "  * [$fileName]($baseURL$suffix/$($md.Name))$nl"
        }
    }
 
    return $TOC
}
 
Convert-FolderContentToMarkdownTableOfContents -BaseFolder "D:\Github\<module folder>" -BaseURL "https://github.com/<user>/<repository>/tree/master" -FiletypeFilter "*.md"
