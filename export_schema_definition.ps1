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
# 20260131 jens heine: encoding set to utf to enable git diff
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
$be_verbose = $false

#$export_views = $true
#$export_tables = $false
#$export_functions = $false
#$export_db_triggers = $false
#$export_table_triggers = $false
#$export_stored_procedures = $false
#
###############################################################################

$global:exported_views_list = New-Object -TypeName System.Collections.ArrayList
$global:exported_tables_list = New-Object -TypeName System.Collections.ArrayList
$global:exported_functions_list = New-Object -TypeName System.Collections.ArrayList
$global:exported_db_triggers_list = New-Object -TypeName System.Collections.ArrayList
$global:exported_table_triggers_list = New-Object -TypeName System.Collections.ArrayList
$global:exported_stored_procedures_list = New-Object -TypeName System.Collections.ArrayList



function generate_db_script([Microsoft.SqlServer.Management.Common.ServerConnection]$serverName, [string]$dbname, [string]$schema_name, [string]$scriptpath)
#function generate_db_script()
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
	$options.Encoding = [System.Text.Encoding]::UTF8
	
	# Set options for SMO.Scripter
	$scr.Options = $options
	
	if ($export_tables) {
		Write-host ">>> Searching tables to process..."
		$options.FileName = $scriptpath + "\$($dbname)_$($schema_name)_tables.sql"
		#Write-host "--"$options.FileName
		New-Item $options.FileName -Type File -force | Out-Null
		Foreach ($tb in $db.Tables)
		{
			$object_name = $tb.Schema + "." + $tb.Name
			if ($be_verbose) { Write-host     "Checking table   :" $object_name }
			If ($tb.Schema -eq $schema_name -And $tb.IsSystemObject -eq $FALSE)
			{
				if ($be_verbose) { Write-host "Processing table :"  $object_name }
				$smoObjects = New-Object Microsoft.SqlServer.Management.Smo.UrnCollection
				$smoObjects.Add($tb.Urn)	
				$scr.Script($smoObjects)
				$exported_tables_list.Add($object_name) | out-null
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
			if ($be_verbose) { Write-host     "Checking view   :" $object_name }
			If ($view -ne $null -And $view.Schema -eq $schema_name -And $view.IsSystemObject -eq $FALSE)
			{
				if ($be_verbose) { Write-host "Processing view :" $object_name }
				$scr.Script($view)
				$global:exported_views_list.Add($object_name) | out-null
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
			if ($be_verbose) { Write-host     "Checking stored procedure   :" $object_name }
			if ($stored_procedure -ne $null -And $stored_procedure.Schema -eq $schema_name -And $stored_procedure.IsSystemObject -eq $FALSE)
			{   
				if ($be_verbose) { Write-host "Processing stored procedure :" $object_name }
				$scr.Script($stored_procedure)
				$exported_stored_procedures_list.Add($object_name) | out-null
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
			if ($be_verbose) { Write-host     "Checking function   :" $object_name }
			if ($function -ne $null -And $function.Schema -eq $schema_name -And $function.IsSystemObject -eq $FALSE)
			{
				if ($be_verbose) { Write-host "Processing function :" $object_name }
				$scr.Script($function)
				$exported_functions_list.Add($object_name) | out-null
			}
		} 
	}
		
	if ($export_db_triggers) {
		Write-host ">>> Searching triggers to process..."
		$options.FileName = $scriptpath + "\$($dbname)_$($schema_name)_db_triggers.sql"
		$db_triggers = $db.Triggers
		# Write-host $db_triggers
		New-Item $options.FileName -type file -force | Out-Null
		foreach ($trigger in $db.triggers)
		{
			$object_name = $trigger.Schema + "." + $trigger.Name
			if ($be_verbose) { Write-host     "Checking trigger   :" $object_name }
			if ($trigger -ne $null -And $trigger.Schema -eq $schema_name -And $trigger.IsSystemObject -eq $FALSE)
			{
				if ($be_verbose) { Write-host "Processing trigger :" $object_name }
				$scr.Script($trigger)
				$exported_db_triggers_list.Add($object_name) | out-null
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
			if ($be_verbose) { Write-host         "Checking table for trigger :" $object_name }
			if($tb.Schema -eq $schema_name -And $tb.IsSystemObject -eq $FALSE -And $tb.triggers -ne $null)
			{
				foreach ($trigger in $tb.triggers)
				{
					$object_name = $tb.Schema + "." + $tb.Name + "." + $trigger.Name
					if ($be_verbose) { Write-host "Processing table trigger   :" $object_name }
					$scr.Script($trigger)
					$global:exported_table_triggers_list.Add($object_name) | out-null
				}
			}
		} 
	}
}


function show_export_stats() {
	Write-Host
	Write-host "<<< Export statistics >>>"
	Write-host
	Write-host "---Exported tables---" 
	Write-host
	$global:exported_tables_list
	Write-host
	Write-host "---Exported views---" 
	Write-host
	$global:exported_views_list
	Write-host
	Write-host "---Exported functions---" 
	Write-host
	$global:exported_functions_list
	Write-host
	Write-host "---Exported db triggers---" 
	Write-host
	$global:exported_db_triggers_list
	Write-host
	Write-host "---Exported table triggers---" 
	Write-host
	$global:exported_table_triggers_list
	Write-host
	Write-host "---Exported stored procedures---" 
	Write-host
	$global:exported_stored_procedures_list
	Write-host
	Write-host "<<< Export statistics summary >>>"
	Write-host
	Write-host "Server                     :" $target_db_server
	Write-host "Database                   :" $target_db_name
	Write-host "Schema                     :" $target_schema_name 
	Write-host "Target folder              :" $target_export_path
	Write-host "Exported tables            :" $global:exported_tables_list.Count
	Write-host "Exported views             :" $global:exported_views_list.Count
	Write-host "Exported functions         :" $global:exported_functions_list.Count
	Write-host "Exported db triggers       :" $global:exported_db_triggers_list.Count
	Write-host "Exported table triggers    :" $global:exported_table_triggers_list.Count
	Write-host "Exported stored procedures :" $global:exported_stored_procedures_list.Count
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
if ($args[0] -And $args[1] -And $args[2] -And $args[3]) 
{
	$target_db_server = $args[0]
	$target_db_name = $args[1]
	$target_schema_name = $args[2]
	$target_export_path = resolve-path $args[3]
} else {
	Write-host "Written 2025 by jens heine <binbash@gmx.net>"
	Write-host
	Write-host "Usage   : export_schema_definition.ps1 MSSQLSERVER_NAME DB_NAME SCHEMA_NAME EXPORT_PATH"
	Write-host "Notes   : Run this tool in an administrator powershell."
	Write-host "          You can exclude/include the objects to export in the top of the script."
	Write-host "Example : export_schema_definition.ps1 sql-server my_database dbo c:\temp"
	exit 1
}

# Create database connection object
$conn = New-Object Microsoft.SqlServer.Management.Common.ServerConnection
$conn.ConnectionString = "Data Source=$($target_db_server);Initial Catalog=$($target_db_name);Integrated Security=True"

# Call Main function
Write-host ">>> Started at" $(Get-Date)
generate_db_script $conn $target_db_name $target_schema_name $target_export_path
Write-host ">>> Finished at" $(Get-Date)

if ($be_verbose) { show_export_directory }

show_export_stats

$end_date= Get-Date
$time_diff= New-TimeSpan -Start $start_date -End $end_date
Write-Output "Script runtime is: $time_diff"



