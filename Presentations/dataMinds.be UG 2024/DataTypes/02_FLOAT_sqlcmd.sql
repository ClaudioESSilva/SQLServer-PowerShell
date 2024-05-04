/*
	Download from: https://learn.microsoft.com/en-us/sql/tools/sqlcmd/sqlcmd-utility
	Go to command line/PowerShell and Run
	- sqlcmd -S localhost,2022 -U <user> -P <pwd> -i "02_FLOAT_sqlcmd.sql"

	sqlcmd -S localhost,2022 -U sqladmin -P dbatools.IO -i "02_FLOAT_sqlcmd.sql"
*/
DECLARE @float1 float = 0.1
DECLARE @float2 float = 0.2

SELECT
		-- Addition of both values
		@float1 + @float2 AS AdditionBoth,

		-- some floats with values 0.1 and 0.2. Is it = 0.3?
		CASE 
			WHEN @float1 + @float2 = 0.3 THEN 'True'
			ELSE 'False'
		 END AS CaseTest
GO