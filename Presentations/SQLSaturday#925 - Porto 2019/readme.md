# Before you start
For a better expirience you should use Azure Data Studio and take advantage of the SQL/PowerShell notebooks. Use the [dbatoolsAndPowerBI.ipynb](dbatoolsAndPowerBI.ipynb) notebook.

# Pre-requirements
1. [dbatools](https://www.powershellgallery.com/packages/dbatools) PowerShell module.
2. [PoshRSJob](https://www.powershellgallery.com/packages/PoshRSJob) PowerShell module by Boe Prox. (enable us to use multi-threading and throttling)
3. [Power BI Desktop](https://www.microsoft.com/pt-pt/download/details.aspx?id=45331) (is free)

# Code
The PowerShell scripts that uses dbatools and PoshRSJob modules are within DataCollection folder.
They contain for example the function that does the transpose of the datatable.

# Instructions
1. Create an empty database
2. Run the existing SQL Scripts on [Tables](./dbatools%20database/Tables) and [Views](./dbatools%20database/Views) folders.
 2.1 Adjust the code of the view if needed.
3. Configure your SQL Server agent jobs (you can use the scripts on [dbatools database](./dbatools%20database/AgentJobs) folder
    3.1 Don't forget to change the path used on each step to your [DataCollection](./DataCollection) folder.
4. Open the Power BI file dbatools.pbix and change the 2 parameters (`InstanceName` & `DatabaseName`)
    4.1 "Home" tab -> "Edit Queries" -> "Edit Parameters"
    4.2 Apply the changes and accept the queries by select "Run" for each of them.


Note: If you have any question, drop me a message or open an issue.
