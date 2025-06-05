/*
	DBCC TRACEON (3604);
	GO
	
	The traceflag is to make the output of DBCC PAGE go to the console, rather than to the error log.



	DBCC PAGE (pagesplittest, 1, 143, 3);

	dbcc page ( {‘dbname’ | dbid}, filenum, pagenum [, printopt={0|1|2|3} ])

	0 – print just the page header
	1 – page header plus per-row hex dumps and a dump of the page slot array (unless its a page that doesn’t have one, like allocation bitmaps)
	2 – page header plus whole page hex dump
	3 – page header plus detailed per-row interpretation
*/