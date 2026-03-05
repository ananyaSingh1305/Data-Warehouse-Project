/*
=============================================================
Create Database and Schemas
=============================================================
Script Purpose:
    This script creates a new database named 'DataWarehouse' after checking if it already exists. 
    If the database exists, it is dropped and recreated.
	
WARNING:
    Running this script will drop the entire 'DataWarehouse' database if it exists. 
    All data in the database will be permanently deleted. Proceed with caution 
    and ensure you have proper backups before running this script.
*/

-- Drop the 'DataWarehouse' database if exists
DROP DATABASE IF EXISTS DataWarehouse;

-- Create the 'DataWarehouse' database and select it as current database
CREATE DATABASE DataWarehouse;
USE DataWarehouse;

