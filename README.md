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


If you only want to generate scripts for stored procedures i.e. and no other objects, edit the header variables in the script and set them to $true or $false:

```
...
# Select object types to export
$export_views = $true
$export_tables = $true
$export_functions = $true
$export_db_triggers = $true
$export_table_triggers = $true
$export_stored_procedures = $true
...
```

Please post comments, feature requests and/or bugs.

Best regards, Jens
