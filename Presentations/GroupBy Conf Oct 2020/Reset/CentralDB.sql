CREATE TABLE CentralDB.dbo.Instances
(
    ConnectionString VARCHAR(255)
    ,Environment VARCHAR(10)
)


INSERT INTO CentralDB.dbo.Instances (ConnectionString, Environment)
VALUES ('localhost,14333','PROD')
     , ('localhost,1433', 'PROD')
     , ('raspberrypi.lan', 'DEV')
