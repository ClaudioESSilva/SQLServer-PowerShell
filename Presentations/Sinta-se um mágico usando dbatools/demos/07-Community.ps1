# Who doesn't use sp_whoIsActive from Adam Machanic?
# If you don't have internet access you can specify the "-LocalFile" parameter to do the deploy

$splatWhoIsActive = @{
    SqlInstance = $docker1, $docker2 
    SqlCredential = $sqlCredential 
    Database = "master" 
    Verbose = $true
}
Install-DbaWhoIsActive @splatWhoIsActive


# You can also use dbatools to invoke the procedure
Invoke-DbaWhoIsActive -SqlInstance $docker1 -SqlCredential $sqlCredential -ShowSleepingSpids 2 | Out-GridView


# What about Brent's Ozar First Respoder Kit? Download, extracts and install
Install-DbaFirstResponderKit

# Maintenance solution by Ola Hallengren? We got you covered =)
# EX: Installing just IndexOptimize
Install-DbaMaintenanceSolution -SqlIntance $sql2016 -SqlCredential $sqlCredential -Solution IndexOptimize