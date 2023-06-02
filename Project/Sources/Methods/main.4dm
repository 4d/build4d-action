//%attributes = {}
ON ERR CALL:C155("onError")  // ignore all, do not want to block CI

var $r : Real
var $startupParam : Text
$r:=Get database parameter:C643(User param value:K37:94; $startupParam)


If ((Length:C16($startupParam)=0) && (Structure file:C489(*)=Structure file:C489()))
	$startupParam:="{}"
End if 

Case of 
	: (Length:C16($startupParam)=0)
		
		print("::error ::No parameters passed to database")
		
	Else 
		
		print("...parsing parameters")
		
		var $config : Object
		$config:=JSON Parse:C1218($startupParam)
		
		// check "workingDirectory"
		If (Length:C16(String:C10($config.workingDirectory))>0)
			
			
			print("- workingDirectory: "+String:C10($config.workingDirectory))
			
			$config.workingDirectory:=Folder:C1567(String:C10($config.workingDirectory)).path  // ensure trailing /
			
		Else 
			// see env ? any means using 4D?
			
			If (Structure file:C489(*)=Structure file:C489())  // this base to test
				$config.workingDirectory:=Folder:C1567(Folder:C1567(fk database folder:K87:14).platformPath; fk platform path:K87:2).path
			End if 
			
		End if 
		
		// check "path"
		If (Length:C16(String:C10($config.path))=0)
			
			// find first file into 
			If ($config.workingDirectory#Null:C1517)
				
				$config.path:=Folder:C1567($config.workingDirectory).folder("Project").files().filter(Formula:C1597($1.value.extension=".4DProject")).first().path
				
			End if 
			
		Else 
			
			// ensure not a mixed path with \ and / due to window full path + posix relative path of project ie be tolerant
			If (Is Windows:C1573)
				
				$config.relative:=Replace string:C233($config.workingDirectory; $config.path; "")
				$config.relative:=Replace string:C233($config.relative; "/"; "\\")
				
				$config.path:=Folder:C1567($config.workingDirectory).file($config.relative).path
				
			End if 
			
		End if 
		
		// run
		Case of 
			: (Length:C16(String:C10($config.path))=0)
				
				print("::error ::correct project file path")
				
			: (Not:C34(File:C1566($config.path).exists))
				
				print("::error ::project file "+$config.path+" do not exists")
				
			Else 
				
				print("- path: "+String:C10($config.path))
				
				$config.file:=File:C1566($config.path)
				
				var $actions : Collection
				$actions:=Split string:C1554(String:C10($config.actions); ",")
				If ($actions.length=0)
					$actions.push("build")
				End if 
				If (Bool:C1537(Num:C11(String:C10(cs:C1710.github.new()["RELEASE"]))))
					$actions.push("release")
				End if 
				print("...will execute actions: "+$actions.join(","))
				
				var $status : Object
				$status:=New object:C1471("success"; True:C214)
				var $action : Text
				For each ($action; $actions) Until (Not:C34($status.success))
					Case of 
						: ($action="build")
							$status:=Compile($config)
						: ($action="release")
							$status:=Release($config)
						Else 
							print("::error :: Unknown action "+$action)
					End case 
				End for each 
				
		End case 
		
End case 