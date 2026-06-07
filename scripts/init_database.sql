/*

Create Database and Schemas

Purpose: 

	Create a new database named 'DataWarehouse' after checking if it already exists.
	If yes,  it will drop said database. After checks, it will create schemas namely:

	1) gold
	2) silver
	3) bronzw

	Warning:

	Running script will drop the whole database including its data if SQL finds that the database already exists
*/

USE master;
GO


--Drop and recreate the 'DataWarehouse' database

IF EXISTS (SELECT 1 FROM sys.databases WHERE name = 'Datawarehouse')
BEGIN
	ALTER DATABASE DataWarehouse SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
	DROP DATABASE DataWarehouse;

END;
GO

--Create the 'DataWarehouse' database

CREATE DATABASE DataWarehouse;
GO

USE DataWarehouse;	
GO

--Create Schemas

CREATE SCHEMA bronze;
GO

CREATE SCHEMA silver;
GO

CREATE SCHEMA gold;
GO
