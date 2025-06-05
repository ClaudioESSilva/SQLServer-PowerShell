/*
	Before you go fire queries on your systems, be aware of the following:

	What happens when we drop a column on a SQL Server table? Where's my space?
		https://claudioessilva.eu/2024/05/29/What-happens-when-we-drop-a-column-on-a-SQL-Server-table-Wheres-my-space/

	Identify Tables With Dropped Columns
		https://claudioessilva.eu/2024/07/09/Identify-Tables-With-Dropped-Columns/

	How much Space can I expect to recover from a rebuild after dropping a column?
		https://claudioessilva.eu/2024/08/05/How-much-space-can-I-expect-to-recover-from-a-rebuild-after-dropping-a-column/	

	"Calculate the Space Used to Store Data in the Leaf Level"
		https://learn.microsoft.com/en-us/sql/relational-databases/databases/estimate-the-size-of-a-clustered-index?view=sql-server-ver16#step-1-calculate-the-space-used-to-store-data-in-the-leaf-level

	"Use caution with sys.dm_db_database_page_allocations in SQL Server" by Aaron Bertrand
		https://www.mssqltips.com/sqlservertip/6309/use-caution-with-sysdmdbdatabasepageallocations-in-sql-server/

	Pages and extents architecture guide
		https://learn.microsoft.com/en-us/sql/relational-databases/pages-and-extents-architecture-guide?view=sql-server-ver16

	Locks and ALTER TABLE
		https://learn.microsoft.com/en-us/sql/t-sql/statements/alter-table-transact-sql?view=sql-server-ver15#locks-and-alter-table

	Add NOT NULL columns as an online operation
		https://learn.microsoft.com/en-us/sql/t-sql/statements/alter-table-transact-sql?view=sql-server-ver15#adding-not-null-columns-as-an-online-operation


	
*/


