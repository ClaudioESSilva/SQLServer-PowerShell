/*
	Source: https://www.sqlskills.com/blogs/paul/inside-the-storage-engine-anatomy-of-a-page/


	Page has 8KB - 8192 bytes
	96 byte header
	Leaving 8096 for data

	A record can't have more than 8060 bytes on a page


	Header
		The page header is 96 bytes long. What I’d like to do in this section is take an example page header dump from DBCC PAGE and explain what all the fields mean. I’m using the database from the page split post and I’ve snipped off the rest of the DBCC PAGE output.


		Dump a page:
			DBCC TRACEON (3604);
			DBCC PAGE (N'pagesplittest', 1, 143, 1);
			GO

		RESULT: 
			m_pageId = (1:143)                   m_headerVersion = 1                  m_type = 1
			m_typeFlagBits = 0x4                 m_level = 0                          m_flagBits = 0x200
			m_objId (AllocUnitId.idObj) = 68     m_indexId (AllocUnitId.idInd) = 256
			Metadata: AllocUnitId = 72057594042384384
			Metadata: PartitionId = 72057594038386688                                 Metadata: IndexId = 1
			Metadata: ObjectId = 2073058421      m_prevPage = (0:0)                   m_nextPage = (1:154)
			pminlen = 8                          m_slotCnt = 4                        m_freeCnt = 4420
			m_freeData = 4681                    m_reservedCnt = 0                    m_lsn = (18:116:25)
			m_xactReserved = 0                   m_xdesId = (0:0)                     m_ghostRecCnt = 0
			m_tornBits = 1333613242
		
	   



	m_pageId
		This identifies the file number the page is part of and the position within the file. In this example, (1:143) means page 143 in file 1.

	m_headerVersion
		This is the page header version. Since version 7.0 this value has always been 1.

	m_type
		This is the page type. The values you’re likely to see are:
		1 – data page. This holds data records in a heap or clustered index leaf-level.
		2 – index page. This holds index records in the upper levels of a clustered index and all levels of non-clustered indexes.
		3 – text mix page. A text page that holds small chunks of LOB values plus internal parts of text tree. These can be shared between LOB values in the same partition of an index or heap.
		4 – text tree page. A text page that holds large chunks of LOB values from a single column value.
		7 – sort page. A page that stores intermediate results during a sort operation.
		8 – GAM page. Holds global allocation information about extents in a GAM interval (every data file is split into 4GB chunks – the number of extents that can be represented in a bitmap on a single database page). Basically whether an extent is allocated or not. GAM = Global Allocation Map. The first one is page 2 in each file. More on these in this post.
		9 – SGAM page. Holds global allocation information about extents in a GAM interval. Basically whether an extent is available for allocating mixed-pages. SGAM = Shared GAM. the first one is page 3 in each file. More on these in this post.
		10 – IAM page. Holds allocation information about which extents within a GAM interval are allocated to an allocation unit (portion of a table or index). IAM = Index Allocation Map. More on these in this post.
		11 – PFS page. Holds allocation and free space information about pages within a PFS interval (every data file is also split into approx 64MB chunks – the number of pages that can be represented in a byte-map on a single database page. PFS = Page Free Space. The first one is page 1 in each file. More on these in this post.
		13 – boot page. Holds information about the database. There’s only one of these in the database. It’s page 9 in file 1.
		15 – file header page. Holds information about the file. There’s one per file and it’s page 0 in the file.
		16 – diff map page. Holds information about which extents in a GAM interval have changed since the last full or differential backup. The first one is page 6 in each file.
		17 – ML map page. Holds information about which extents in a GAM interval have changed while in bulk-logged mode since the last backup. This is what allows you to switch to bulk-logged mode for bulk-loads and index rebuilds without worrying about breaking a backup chain. The first one is page 7 in each file.
		18 – a page that’s be deallocated by DBCC CHECKDB during a repair operation.
		19 – the temporary page that ALTER INDEX … REORGANIZE (or DBCC INDEXDEFRAG) uses when working on an index.
		20 – a page pre-allocated as part of a bulk load operation, which will eventually be formatted as a ‘real’ page.

	m_typeFlagBits
		This stores a few values about the page. For data and index pages, if the field is 4, that means all the rows on the page are the same fixed size. If a PFS page has m_typeFlagBits of 1, that means that at least one of the pages in the PFS interval mapped by the PFS page has at least one ghost record.

	m_level
		This is the level that the page is part of in the b-tree.
		Levels are numbered from 0 at the leaf-level and increase to the single-page root level (i.e. the top of the b-tree).
		In SQL Server 2000, the leaf level of a clustered index (with data pages) was level 0, and the next level up (with index pages) was also level 0. The level then increased to the root. So to determine whether a page was truly at the leaf level in SQL Server 2000, you need to look at the m_type as well as the m_level.
		For all page types apart from index pages, the level is always 0.

	m_flagBits
		This stores a number of different flags that describe the page. For example, 0x200 means that the page has a page checksum on it (as our example page does) and 0x100 means the page has torn-page protection on it.
		Some bits are no longer used from SQL Server 2005 onward.

	m_objId
	m_indexId
		In SQL Server 2000, these identified the actual relational object and index IDs to which the page is allocated. In SQL Server 2005 this is no longer the case. The allocation metadata totally changed so these instead identify what’s called the allocation unit that the page belongs to. This post explains how an allocation unit ID is calculated. Note that for databases upgraded from SQL Server 2000, they will still be the the actual object ID and index ID. Also for databases on all versions, many system tables still have these be the actual object and index IDs.

	m_prevPage
	m_nextPage
		These are pointers to the previous and next pages at this level of the b-tree and store 6-byte page IDs.
		The pages in each level of an index are joined in a doubly-linked list according to the logical order (as defined by the index keys) of the index. The pointers do not necessarily point to the immediately adjacent physical pages in the file (because of fragmentation).
		The pages on the left-hand side of a b-tree level will have the m_prevPage pointer be NULL, and those on the right-hand side will have the m_nextPage be NULL.
		In a heap, or if an index only has a single page, these pointers will both be NULL for all pages. There’s a special case when they won’t be NULL – if the heap is rebuilt using ALTER TABLE … REBUILD. This uses the index rebuild code to build the leaf-level of a clustered index, but the linkages aren’t actually used for anything. See here for more details.

	pminlen
		This is the size of the fixed-length portion of the records on the page.

	m_slotCnt
		This is the count of records on the page.
	
	m_freeCnt
		This is the number of bytes of free space in the page.

	m_freeData
		This is the offset from the start of the page to the first byte after the end of the last record on the page. It doesn’t matter if there is free space nearer to the start of the page.

	m_reservedCnt
		This is the number of bytes of free space that has been reserved by active transactions that freed up space on the page. It prevents the free space from being used up and allows the transactions to roll-back correctly. There’s a very complicated algorithm for changing this value.

	m_lsn
		This is the Log Sequence Number of the last log record that changed the page.

	m_xactReserved
		This is the amount that was last added to the m_reservedCnt field.

	m_xdesId
		This is the internal ID of the most recent transaction that added to the m_reservedCnt field.
	
	m_ghostRecCnt
		The is the count of ghost records on the page.
	
	m_tornBits
		This holds either the page checksum or the bits that were displaced by the torn-page protection bits – depending on what form of page protection is turned on for the database.
*/

/*
	The 8060 bytes is the maximum size of one record, not the amount of data space on the page – 8096 bytes.

	For a maximum-sized record of 8060 bytes, add two bytes for the slot array entry, 10 bytes for a possible heap forwarded-record backpointer, 14-bytes for a 
	possible versioning tag, and that’s 26 bytes used. The other 10 bytes are for possible future use.

	If there are more than one record on the page, all 8096 bytes of data space can be used.
*/