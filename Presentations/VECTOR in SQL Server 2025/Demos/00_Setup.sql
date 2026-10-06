THROW 81920, 'Hey! Just don''t run everything!', 1
GO

/*
    Restore the AdventureWorks2025 database from a backup file
    Disconnect all users from the database before restore
*/
ALTER DATABASE [AdventureWorksLT] SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
GO

USE [master];
GO

RESTORE DATABASE [AdventureWorksLT]
FROM DISK = '/var/opt/mssql/backups/AdventureWorks2025_FULL.bak'
WITH
    MOVE 'AdventureWorksLT2022_Data' TO '/var/opt/mssql/data/AdventureWorksLT_Data.mdf',
    MOVE 'AdventureWorksLT2022_Log' TO '/var/opt/mssql/data/AdventureWorksLT_log.ldf',
    FILE = 1,
    NOUNLOAD,
    STATS = 5,
    REPLACE;
GO


/*
    What is our environment?
*/
SELECT @@VERSION
GO

/*
    I'm relying on the Docker containers done by Anthony Nocentino

    You can check it here: 
        https://github.com/nocentino/ollama-sql-faststart

    Also, some of the demos you will see here are from this same repo
        https://github.com/nocentino/ollama-sql-faststart/blob/main/vector-demos.sql

    This image doesn't have FTS installed. For that you need to run:
        docker exec -u 0 -it ollama-sql-faststart-sql1-1 /bin/bash
        apt-get update
        apt-get install -yq curl apt-transport-https gnupg
        curl https://packages.microsoft.com/keys/microsoft.asc | apt-key add -
        curl https://packages.microsoft.com/config/ubuntu/22.04/mssql-server-2025.list | tee /etc/apt/sources.list.d/mssql-server-2025.list 
        
        curl -fL -o libldap-2.5-0_2.5.20+dfsg-0ubuntu0.22.04.1_amd64.deb https://security.ubuntu.com/ubuntu/pool/main/o/openldap/libldap-2.5-0_2.5.20+dfsg-0ubuntu0.22.04.1_amd64.deb
        apt-get install ./libldap-2.5-0_2.5.20+dfsg-0ubuntu0.22.04.1_amd64.deb
        
        apt-get update
        apt-get install -y mssql-server-fts
        apt-get clean && rm -rf /var/lib/apt/lists/* && rm -rf /*.deb

        systemctl restart mssql-server
*/