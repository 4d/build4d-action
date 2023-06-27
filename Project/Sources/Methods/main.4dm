//%attributes = {}
ON ERR CALL:C155("onError")  // ignore all, do not want to block CI

var $r : Real
var $startupParam : Text
$r:=Get database parameter:C643(User param value:K37:94; $startupParam)

var $logger : cs:C1710.logger
$logger:=cs:C1710.logger.new()

If (Length:C16($startupParam)=0)
	If (Structure file:C489(*)=Structure file:C489())  // dev
		$startupParam:="{}"
	Else 
		$logger.error("No parameters passed to database")
		return 
	End if 
End if 

$logger.info("...parsing parameters")

var $config : Object
$config:=JSON Parse:C1218($startupParam)

$config.logger:=$logger
$config.logger.debug:=Bool:C1537($config.debug)

// check "workingDirectory"
If (Length:C16(String:C10($config.workingDirectory))>0)
	
	$config.logger.info("- workingDirectory: "+String:C10($config.workingDirectory))
	
Else 
	// CLEAN: see env var ? any means using 4D?
	
	If (Structure file:C489(*)=Structure file:C489())  // this base to test
		$config.workingDirectory:=Folder:C1567(Folder:C1567(fk database folder:K87:14).platformPath; fk platform path:K87:2).path
	End if 
	
End if 

// check "path"
If (Length:C16(String:C10($config.path))=0)
	
	// find first file into 
	If ($config.workingDirectory#Null:C1517)
		
		If (Is Windows:C1573)
			$config.workingDirectoryFolder:=Folder:C1567($config.workingDirectory; fk platform path:K87:2)
		Else 
			$config.workingDirectoryFolder:=Folder:C1567($config.workingDirectory)
		End if 
		
		$config.path:=String:C10($config.workingDirectoryFolder.folder("Project").files().filter(Formula:C1597($1.value.extension=".4DProject")).first().path)
		
	End if 
	
Else 
	
	// ensure not a mixed path with \ and / due to window full path + posix relative path of project ie be tolerant
	If (Is Windows:C1573)
		
		$config.relative:=Replace string:C233($config.workingDirectory; $config.path; "")
		$config.relative:=Replace string:C233($config.relative; "/"; "\\")
		If (Position:C15("\\"; $config.relative)=1)
			$config.relative:=Delete string:C232($config.relative; 1; 1)
		End if 
		
		$config.path:=Folder:C1567($config.workingDirectory).file($config.relative).path
		
	End if 
	
End if 

// check actions
If (Value type:C1509($config.actions)=Is text:K8:3)
	$config.actions:=Split string:C1554(String:C10($config.actions); ",")
End if 
If (Value type:C1509($config.actions)#Is collection:K8:32)
	$config.actions:=New collection:C1472
End if 
If ($config.actions.length=0)
	$config.actions.push("build")
End if 
/*If (Bool(Num(String(cs.github.new()["RELEASE"]))))
$config.actions.push("release")
End if */

// run
Case of 
	: (Length:C16(String:C10($config.path))=0)
		
		$config.logger.error("no correct project file path provided")
		
	: (Not:C34(File:C1566($config.path).exists))
		
		$config.logger.error("project file "+$config.path+" do not exists")
		
	Else 
		
		$config.logger.info("- path: "+String:C10($config.path))
		
		$config.file:=File:C1566($config.path)  // used to get parents directory (for instance to get components)
		
		$config.logger.info("...will execute actions: "+$config.actions.join(","))
		
		var $actions : cs:C1710.actions
		$actions:=cs:C1710.actions.new($config)
		
		var $status : Object
		$status:=New object:C1471("success"; True:C214)
		
		var $action : Text
		For each ($action; $config.actions) Until (Not:C34($status.success))
			If ((OB Instance of:C1731($actions[$action]; 4D:C1709.Function)) && (Position:C15("_"; $action)#1))
				$status:=$actions[$action].call($actions)
			Else 
				$config.logger.error("Unknown action "+$action)
				$status.success:=False:C215
			End if 
		End for each 
		
End case 
