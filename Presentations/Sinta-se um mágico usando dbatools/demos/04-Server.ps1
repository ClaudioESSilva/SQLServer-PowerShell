Return 'Cláudio, come on, you are giving a presentation..do not try to run the whole script! :) '

# Server level

# Get-DbaService
Get-DbaService -ComputerName "localhost" | Format-Table -AutoSize

$allInstances = $docker1, $docker2, $sql2016

<#
    Do you know in which port is your instance listening?
    How do you get the TCP port? Get-DbaTcpPort for the rescue :-)
    NOTE: Will not work on non-windows instalations
#>
Get-DbaTcpPort -SqlInstance $allInstances | Format-Table

#Startup Parameters? Which ones? - We have a command to set them if you want :-)
Get-DbaStartupParameter -SqlInstance $allInstances

# Want to know specific version?
# If you receive the message saying "the index is stale" run
Get-DbaBuildReference -Update

$allInstances | Get-DbaBuildReference -SqlCredential $sqlCredential | Format-Table



# We can also get information from disk space
Get-DbaDiskSpace -ComputerName $sql2016 | Format-Table -AutoSize


