Return 'Cláudio, come on, you are giving a presentation..do not try to run the whole script! :) '

# Test commands make possible to check specific configurations

# Get all existing Test-* commands
Get-Command -Module dbatools -Name Test*

#Test connection to instances
Test-DbaConnection -SqlInstance $docker1, $docker2, $sql2016 -SqlCredential $sqlCredential | Format-Table -AutoSize

# Some instance and databases validations
# Let's see how many memory is set for each instance
$allInstances | Test-DbaMaxMemory -SqlCredential $sqlCredential | Format-Table

# Verify which ones does not have the Recommended value
$allInstances | Test-DbaMaxMemory -SqlCredential $sqlCredential | Where-Object { $_.MaxValue -gt $_.Total } | Format-Table

# Fix that! Note: You can use Set-DbaMaxMemory with or without -MaxMb parameter - Take a look on the help ;-)
$allInstances | Test-DbaMaxMemory -SqlCredential $sqlCredential | Where-Object { $_.MaxValue -gt $_.Total } | Set-DbaMaxMemory


# What about the MaxDOP (max degree of paralelism)
Test-DbaMaxDop -SqlInstance $sql2016 | Format-Table


# Check Database owner
Test-DbaDbOwner -SqlInstance $allInstances -SqlCredential $sqlCredential -TargetLogin "sa" | Format-Table

Test-DbaDbOwner -SqlInstance $allInstances -SqlCredential $sqlCredential -TargetLogin "sa" | Format-Table


# Are we up-to-date? Do we need to patch?
Test-DbaBuild -SqlInstance $allInstances -SqlCredential $sqlCredential -Latest

# What if we decide that we are when we are only 1CU behind?
Test-DbaBuild -SqlInstance $allInstances -SqlCredential $sqlCredential -MaxBehind 1CU



