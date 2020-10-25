USE Northwind
GO

SELECT ISNULL(OBJECT_NAME(major_id),'') [Objects], USER_NAME(grantee_principal_id) as [UserName], permission_name as [PermissionName]
FROM sys.database_permissions p
WHERE grantee_principal_id>0
ORDER BY OBJECT_NAME(major_id), permission_name, USER_NAME(grantee_principal_id)

USE master
GO
SELECT pr.principal_id, pr.name, pr.type_desc,   
    pe.state_desc, pe.permission_name   
FROM sys.server_principals AS pr   
JOIN sys.server_permissions AS pe   
    ON pe.grantee_principal_id = pr.principal_id
WHERE pr.name IN ('storageuser', 'storageuserColleague'); 