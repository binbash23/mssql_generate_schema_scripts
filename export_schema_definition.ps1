#
# 20250311 by jens heine <binbash@gmx.net>
#
# Export object definitions from a database and schema to *.sql file(s)
#
# Thanks to https://gist.github.com/cheynewallace. I used his 
# project https://gist.github.com/cheynewallace/9558179 as a template.
#
# NOTE: run this tool in an administrator powershell 
#

###############################################################################
# Set Target variables 
###############################################################################
# Select object types to export
$export_views = $true
$export_tables = $true
$export_functions = $true
$export_db_triggers = $true
$export_table_triggers = $true
$export_stored_procedures = $true
#
###############################################################################

$exported_views = 0
$exported_tables = 0
$exported_functions = 0
$exported_db_triggers = 0
$exported_table_triggers = 0
$exported_stored_procedures = 0


function generate_db_script([Microsoft.SqlServer.Management.Common.ServerConnection]$serverName, [string]$dbname, [string]$schema_name, [string]$scriptpath)
{
	Write-host ">>> Exporting object definitions from" $target_db_server"database:"  $dbname", schema:" $schema_name "to folder"  $scriptpath
	Write-host ">>> Using:" $serverName
	[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.SMO") | Out-Null
	[System.Reflection.Assembly]::LoadWithPartialName("System.Data") | Out-Null
	$srv = new-object "Microsoft.SqlServer.Management.SMO.Server" $serverName
	#$srv.SetDefaultInitFields([Microsoft.SqlServer.Management.SMO.View], "IsSystemObject")
	$db = New-Object "Microsoft.SqlServer.Management.SMO.Database"
	$db = $srv.Databases[$dbname]
	$scr = New-Object "Microsoft.SqlServer.Management.Smo.Scripter"
	$deptype = New-Object "Microsoft.SqlServer.Management.Smo.DependencyType"
	$scr.Server = $srv
	$options = New-Object "Microsoft.SqlServer.Management.SMO.ScriptingOptions"
	$options.AllowSystemObjects = $false
	$options.IncludeDatabaseContext = $true
	$options.IncludeIfNotExists = $false
	$options.ClusteredIndexes = $true
	$options.Default = $true
	$options.DriAll = $true
	$options.Indexes = $true
	$options.NonClusteredIndexes = $true
	$options.IncludeHeaders = $false
	$options.ToFileOnly = $true
	$options.AppendToFile = $true
	$options.ScriptDrops = $false 
	
	# Set options for SMO.Scripter
	$scr.Options = $options
	
	if ($export_tables) {
		Write-host ">>> Searching tables to process..."
		$options.FileName = $scriptpath + "\$($dbname)_$($schema_name)_tables.sql"
		New-Item $options.FileName -type file -force | Out-Null
		Foreach ($tb in $db.Tables)
		{
			$object_name = $tb.Schema + "." + $tb.Name
			Write-host     "Checking table   :" $object_name
			If ($tb.Schema -eq $schema_name -And $tb.IsSystemObject -eq $FALSE)
			{
				Write-host "Processing table :"  $object_name
				$smoObjects = New-Object Microsoft.SqlServer.Management.Smo.UrnCollection
				$smoObjects.Add($tb.Urn)	
				$scr.Script($smoObjects)
				$script:exported_tables++
			} 
		}
	}

	if ($export_views) {
		Write-host ">>> Searching views to process..."
		$options.FileName = $scriptpath + "\$($dbname)_$($schema_name)_views.sql"
		New-Item $options.FileName -type file -force | Out-Null
		$views = $db.Views 
		Foreach ($view in $views)
		{
			$object_name = $view.Schema + "." + $view.Name
			Write-host     "Checking view   :" $object_name
			#if ($views -ne $null)
			If ($view -ne $null -And $view.Schema -eq $schema_name -And $view.IsSystemObject -eq $FALSE)
			{
				Write-host "Processing view :" $object_name
				$scr.Script($view)
				$script:exported_views++
			}
		}
	}

	if ($export_stored_procedures) {
		Write-host ">>> Searching stored procedures to process..."
		$options.FileName = $scriptpath + "\$($dbname)_$($schema_name)_stored_procedures.sql"
		#$stored_procedures = $db.stored_procedures | where {$_.IsSystemObject -eq $false}
		$stored_procedures = $db.StoredProcedures  
		New-Item $options.FileName -type file -force | Out-Null
		Foreach ($stored_procedure in $stored_procedures)
		{
			$object_name = $stored_procedure.Schema + "." + $stored_procedure.Name
			Write-host     "Checking stored procedure   :" $object_name
			if ($stored_procedure -ne $null -And $stored_procedure.Schema -eq $schema_name -And $stored_procedure.IsSystemObject -eq $FALSE)
			{   
				Write-host "Processing stored procedure :" $object_name
				$scr.Script($stored_procedure)
				$script:exported_stored_procedures++
			}
		} 
	}
		
	if ($export_functions) {
		Write-host ">>> Searching functions to process..."
		$options.FileName = $scriptpath + "\$($dbname)_$($schema_name)_functions.sql"
		$user_defined_functions = $db.UserDefinedFunctions #| where {$_.IsSystemObject -eq $false}
		New-Item $options.FileName -type file -force | Out-Null
		Foreach ($function in $user_defined_functions)
		{
			$object_name = $function.Schema + "." + $function.Name
			Write-host     "Checking function   :" $object_name
			if ($function -ne $null -And $function.Schema -eq $schema_name -And $function.IsSystemObject -eq $FALSE)
			{
				Write-host "Processing function :" $object_name
				$scr.Script($function)
				$script:exported_functions++
			}
		} 
	}
		
	if ($export_db_triggers) {
		Write-host ">>> Searching triggers to process..."
		$options.FileName = $scriptpath + "\$($dbname)_$($schema_name)_db_triggers.sql"
		$db_triggers = $db.Triggers
		Write-host $db_triggers
		New-Item $options.FileName -type file -force | Out-Null
		foreach ($trigger in $db.triggers)
		{
			$object_name = $trigger.Schema + "." + $trigger.Name
			Write-host     "Checking trigger   :" $object_name
			if ($trigger -ne $null -And $trigger.Schema -eq $schema_name -And $trigger.IsSystemObject -eq $FALSE)
			{
				Write-host "Processing trigger :" $object_name
				$scr.Script($trigger)
				$script:exported_db_triggers++
			}
		}
	}			

	if ($export_table_triggers) {
		Write-host ">>> Searching table triggers to process..."
		$options.FileName = $scriptpath + "\$($dbname)_$($schema_name)_table_triggers.sql"
		New-Item $options.FileName -type file -force | Out-Null
		Foreach ($tb in $db.Tables)
		{     
			$object_name = $tb.Schema + "." + $tb.Name
			Write-host         "Checking table for trigger :" $object_name
			if($tb.Schema -eq $schema_name -And $tb.IsSystemObject -eq $FALSE -And $tb.triggers -ne $null)
			{
				foreach ($trigger in $tb.triggers)
				{
					$object_name = $tb.Schema + "." + $tb.Name + "." + $trigger.Name
					Write-host "Processing table trigger   :" $object_name
					$scr.Script($trigger)
					$script:exported_table_triggers++
				}
			}
		} 
	}
}


function write_export_stats() {
	Write-Host
	Write-host ">>> Export statistics"
	Write-host "Exported tables            :" $exported_tables
	Write-host "Exported views             :" $exported_views
	Write-host "Exported functions         :" $exported_functions
	Write-host "Exported db triggers       :" $exported_db_triggers
	Write-host "Exported table triggers    :" $exported_table_triggers
	Write-host "Exported stored procedures :" $exported_stored_procedures
	Write-Host
}

function show_export_directory() {
	Write-Host
	Write-host ">>> Export directory contents: $target_export_path"
	dir "$target_export_path"
	Write-Host
}


#
# Main
#
$start_date = Get-Date

# Load assemblies
#[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.Smo") #| Out-Null
#[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.SqlEnum") #| Out-Null
[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.ConnectionInfo") | Out-Null
###[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.Dmf.Common") | Out-Null

# Process script arguments if set
if ($args[0] -And $args[1] -And $args[2]) 
{
	$target_db_server = $args[0]
	$target_db_name = $args[1]
	$target_schema_name = $args[2]
	$target_export_path = $args[3]
} else {
	Write-host "Written 2025 by jens heine <binbash@gmx.net>"
	Write-host "Usage   : export_schema_definition.ps1 MSSQLSERVER_NAME DB_NAME SCHEMA_NAME EXPORT_PATH"
	Write-host "Notes   : Run this tool in an administrator powershell."
	Write-host "          The export path does not allow spaces."
	Write-host "          You can exclude/include the objects to export in the top of the script."
	Write-host "Example : .\export_schema_definition.ps1 sql-server my_database dbo c:\temp"
	exit 1
}

# Create database connection object
$conn = New-Object Microsoft.SqlServer.Management.Common.ServerConnection
$conn.ConnectionString = "Data Source=$($target_db_server);Initial Catalog=$($target_db_name);Integrated Security=True"

# Call Main function
generate_db_script $conn $target_db_name $target_schema_name $target_export_path

show_export_directory

write_export_stats

$end_date= Get-Date
$time_diff= New-TimeSpan -Start $start_date -End $end_date
Write-Output "Script runtime is: $time_diff"



