//%attributes = {}
ON ERR CALL:C155("onError")  // ignore all, do not want to block CI

var $r : Real
var $startupParam : Text
$r:=Get database parameter:C643(User param value:K37:94; $startupParam)
Case of 
	: (Length:C16($startupParam)=0)
		
		print("::error ::No parameters passed to database")
		
	Else 
		
		print("...parsing parameters")
		
		var $config : Object
		$config:=JSON Parse:C1218($startupParam)
		
		Case of 
			: (Length:C16(String:C10($config.path))=0)
				
				print("::error ::correct project file path")
				
			: (Not:C34(File:C1566($config.path).exists))
				
				print("::error ::project file "+$config.path+" do not exists")
				
			Else 
				
				$config.file:=File:C1566($config.path)
				$config.workingDirectory:=Folder:C1567($config.workingDirectory).path  // ensure trailing /
				
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
							print("error:: Unknown action "+$action)
					End case 
				End for each 
				
		End case 
		
End case 

If (Not:C34(Shift down:C543))
	QUIT 4D:C291()
End if 