# mssql_generate_schema_scripts
Generate a complete set of SQL scripts for a Microsoft SQL Server database/schema.
The generated scripts include table, view, function, trigger and stored procedure definitions. Also indices, column store table stuff, ... are included.

```
Written 2025 by jens heine <binbash@gmx.net>

Usage   : export_schema_definition.ps1 MSSQLSERVER_NAME DB_NAME SCHEMA_NAME EXPORT_PATH
Notes   : Run this tool in an administrator powershell.
          The export path does not allow spaces.
          You can exclude/include the object types to export in the top of the script.
Example : .\export_schema_definition.ps1 sql-server my_database dbo c:\temp
```
