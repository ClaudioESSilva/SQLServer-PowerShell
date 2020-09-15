Return 'Cláudio, come on, you are giving a presentation..do not try to run the whole script! :) '


# Install module (If you don't have administratives rights you should use Install-Module dbatools -Scope CurrentUser)
Install-Module -Name dbatools

# If you don't have internet access on the server, download the module from a PC with internet acess
# After that you need to copy to your server and put it on the modules' folder
Save-Module -Name dbatools -Path D:\temp

# Update module from gallery
Update-Module -Name dbatools

# Check if dbatools is loaded into memory
Get-Module -Name dbatools

# List all dbatools versions you have installed
Get-Module -Name dbatools -ListAvailable

# Explicitly import the module
Import-Module dbatools -force

# If you already have a version in memory you need to remove it before import new one
Remove-Module dbatools


# Exploring the module
# Which commands do we have?
Get-Command -Module dbatools

# How many?
(Get-Command -Module dbatools | Where-Object CommandType -eq 'Function').Count

# How do we find commands? (this method is handy when we don't have internet access to search on https://docs.dbatools.io)
Find-DbaCommand -Tag Backup
Find-DbaCommand -Author claudio
Find-DbaCommand -Pattern Compression

# Using commands

# ALWAYS (I'm serious), use Get-Help
Get-Help Test-DbaLinkedServerConnection -Full

# -ShowWindow allows to use a GUI and has a search box
Get-Help Find-DbaStoredProcedure -ShowWindow




# Some times I will be using splatting - Code will become shorter and easier to read
# Example without splatting:
Get-DbaDatabase -SqlInstance $docker1, $docker2 -SqlCredential $sqlCredential | Select-Object SqlInstance, Name

# with splatting
$splatGetDatabase = @{
    SqlInstance = $docker1, $docker2
    SqlCredential = $sqlCredential
}
Get-DbaDatabase @splatGetDatabase | Select-Object SqlInstance, Name
