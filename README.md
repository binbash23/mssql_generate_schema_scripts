# mssql_generate_schema_scripts
Generate a complete set of SQL scripts for a Microsoft SQL Server database/schema.

Written 2025 by jens heine <binbash@gmx.net>
Usage: export_schema_definition.ps1 MSSQLSERVER_NAME DB_NAME SCHEMA_NAME EXPORT_PATH
Note that the export path does not allow spaces.
Example: export_schema_definition.ps1 sql-server my_database dbo "c:\temp"
