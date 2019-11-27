SELECT * FROM sys.certificates

DROP CERTIFICATE AGCertificate


CREATE CERTIFICATE AGCertificate2019_2020 WITH SUBJECT = 'AGCertificate2019_2020';

BACKUP CERTIFICATE AGCertificate2019_2020
TO FILE = '/usr/certificate/AGCertificate2019_2020.cer'
WITH PRIVATE KEY (
        FILE = '/usr/certificate/AGCertificate2019_2020.pvk',
        ENCRYPTION BY PASSWORD = 'Pa$$w0rd_dbatools.IO'
    );
GO


CREATE CERTIFICATE AGCertificate2019_2020   
    FROM FILE = '/usr/certificate/AGCertificate2019_2020.cer'   
    WITH PRIVATE KEY (FILE = '/usr/certificate/AGCertificate2019_2020.pvk',   
    DECRYPTION BY PASSWORD = 'Pa$$w0rd_dbatools.IO');  
GO   


ALTER ENDPOINT [hadr_endpoint] 
	STATE=STARTED
	AS TCP (LISTENER_PORT = 5022, LISTENER_IP = ALL)
	FOR DATA_MIRRORING (ROLE = ALL, AUTHENTICATION = CERTIFICATE [AGCertificate2019_2020]
, ENCRYPTION = REQUIRED ALGORITHM AES)
GO

DROP CERTIFICATE AGCertificate
