//%attributes = {}

Use (Storage:C1525)
	Storage:C1525.github:=OB Copy:C1225(cs:C1710.github.new(); ck shared:K85:29)
	Storage:C1525.exit:=New shared object:C1526("errorFlag"; Folder:C1567(Temporary folder:C486; fk platform path:K87:2).file("error_flag").path)
End use 

ON ERR CALL:C155("onError")  // ignore all, do not want to block CI

var $r : Real
var $startupParam : Text
$r:=Get database parameter:C643(User param value:K37:94; $startupParam)

If (Length:C16($startupParam)=0)
	If (Structure file:C489(*)=Structure file:C489())  // dev
		$startupParam:="{}"
	Else 
		Storage:C1525.github.error("No parameters passed to database")
		return 
	End if 
End if 

Storage:C1525.github.info("...parsing parameters")

var $config : Object
$config:=JSON Parse:C1218($startupParam)
If (Length:C16(String:C10($config.errorFlag))>0)
	Use (Storage:C1525.exit)
		Storage:C1525.exit.errorFlag:=String:C10($config.errorFlag)
	End use 
End if 

If ($config.debug#Null:C1517)
	$config.debug:=isTruthly($config.debug)
End if 
If (Structure file:C489(*)=Structure file:C489())  // this base to test
	$config.debug:=True:C214
End if 

$config.ignoreWarnings:=isTruthly($config.ignoreWarnings)

Use (Storage:C1525.github)
	Storage:C1525.github.isDebug:=Bool:C1537($config.debug)
End use 

// check "workingDirectory"
If (Length:C16(String:C10($config.workingDirectory))>0)
	
	Storage:C1525.github.debug("workingDirectory="+String:C10($config.workingDirectory))
	
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
	
	If (Not:C34(File:C1566($config.path).exists))
		
		$config.relative:=$config.path
		
		// ensure not a mixed path with \ and / due to window full path + posix relative path of project ie be tolerant
		If (Is Windows:C1573)
			
			$config.relative:=Replace string:C233($config.workingDirectory; $config.path; "")
			$config.relative:=Replace string:C233($config.relative; "/"; "\\")
			If (Position:C15("\\"; $config.relative)=1)
				$config.relative:=Delete string:C232($config.relative; 1; 1)
			End if 
			
		End if 
		
		If (Is Windows:C1573)
			$config.workingDirectoryFolder:=Folder:C1567($config.workingDirectory; fk platform path:K87:2)
		Else 
			$config.workingDirectoryFolder:=Folder:C1567($config.workingDirectory)
		End if 
		
		$config.file:=$config.workingDirectoryFolder.file($config.path)
		If ($config.file#Null:C1517)
			$config.path:=$config.file.path
		End if 
		
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
		
		Storage:C1525.github.error("no correct project file path provided")
		
	: (Not:C34(File:C1566($config.path).exists))
		
		Storage:C1525.github.error("project file "+$config.path+" do not exists")
		
	Else 
		
		Storage:C1525.github.debug("path="+String:C10($config.path))
		
		$config.file:=File:C1566($config.path)  // used to get parents directory (for instance to get components)
		
		Storage:C1525.github.debug("...will execute actions: "+$config.actions.join(","))
		
		var $actions : cs:C1710.actions
		$actions:=cs:C1710.actions.new($config)
		
		var $status : Object
		$status:=New object:C1471("success"; True:C214)
		
		var $action : Text
		For each ($action; $config.actions) Until (Not:C34($status.success))
			If ((OB Instance of:C1731($actions[$action]; 4D:C1709.Function)) && (Position:C15("_"; $action)#1))
				Storage:C1525.github.notice("action "+$action)
				$status:=$actions[$action].call($actions)
			Else 
				Storage:C1525.github.error("Unknown action "+$action)
				$status.success:=False:C215
			End if 
		End for each 
		
End case 

Storage:C1525.github.debug("it's over")
