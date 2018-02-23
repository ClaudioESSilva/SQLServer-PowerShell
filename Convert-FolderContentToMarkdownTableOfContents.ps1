function Convert-FolderContentToMarkdownTableOfContents{
<#
.SYNOPSIS
Create a Table of Contents in markdown

.DESCRIPTION
This function can be used to generate a markdown file that contains a Table of Contents based on the contents of a folder

.PARAMETER BaseFolder
It’s the folder’s location on the disk

.PARAMETER BaseURL
to build the URL for each file. This will be added as a link

.PARAMETER FiletypeFilter
to filter the files on the folder

.EXAMPLE
Convert-FolderContentToMarkdownTableOfContents -BaseFolder "D:\Github\<module folder>" -BaseURL "https://github.com/<user>/<repository>/tree/master" -FiletypeFilter "*.md"

.NOTES
https://claudioessilva.eu/2017/09/18/generate-markdown-table-of-contents-based-on-files-within-a-folder-with-powershell/
#>    
    
    param (
        [string]$BaseFolder,
        [string]$BaseURL,
        [string]$FiletypeFilter
    )
 
    $nl = [System.Environment]::NewLine
    $TOC = "## Index$nl"
 
    $repoFolderStructure = Get-ChildItem -Path $BaseFolder -Directory | Where-Object Name -NotMatch "\.github|\.git"
 
    foreach ($dir in ($repoFolderStructure | Sort-Object -Property Name)) {
        $repoStructure = Get-ChildItem -Path $dir.FullName -Filter $FiletypeFilter
 
        $TOC += "* $($dir.Name) $nl"
 
        foreach ($md in ($repoStructure | Sort-Object -Property Name)) {
            $suffix = $($md.Directory.ToString().Replace($BaseFolder, [string]::Empty)).Replace("\", "/")
            $fileName = $md.Name -replace $md.Extension
            $TOC += "  * [$fileName]($([uri]::EscapeUriString(""$baseURL$suffix/$($md.Name)"")))$nl"
        }
    }
 
    return $TOC
}
