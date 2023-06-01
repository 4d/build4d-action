//%attributes = {}
#DECLARE($config : Object)->$status : Object

If ($config.options=Null:C1517)
	$config.options:=New object:C1471()
End if 

// adding potential component from folder Components
If ($config.options.components=Null:C1517)
	var $databaseFolder : 4D:C1709.Folder
	$databaseFolder:=$config.file.parent.parent
	If ($databaseFolder.folder("Components").exists)
		print("...adding dependencies")
		$config.options.components:=New collection:C1472
		var $dependency : 4D:C1709.Folder
		For each ($dependency; $databaseFolder.folder("Components").folders())
			If ($dependency.file($dependency.name+".4DZ").exists)
				$config.options.components.push($dependency.file($dependency.name+".4DZ"))
			End if 
		End for each 
	End if 
End if 

print("...launching compilation with opt: "+JSON Stringify:C1217($config.options))
$status:=Compile project:C1760($config.file; $config.options)

If ($status.success)
	If ($status.errors#Null:C1517)
		If ($status.errors.length>0)
			print("⚠️ Build success with warnings")
		Else 
			print("✅ Build success")
		End if 
	Else 
		print("✅ Build success")
	End if 
Else 
	print("‼️ Build failure")  // Into system standard error ??
End if 
If ($status.errors#Null:C1517)
	If ($status.errors.length>0)
		print("::group::Compilation errors")
		var $error : Object
		For each ($error; $status.errors)
			cs:C1710.compilationError.new($error).printGithub($config)
		End for each 
		print("::endgroup::")
	End if 
End if 

