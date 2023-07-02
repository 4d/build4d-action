Class constructor($config : Object)
	This:C1470.config:=$config
	
	// MARK:- build
Function build()->$status : Object
	var $config : Object
	$config:=This:C1470.config
	
	// get compilation options
	If ((Value type:C1509($config.options)=Is text:K8:3) && \
		((Length:C16($config.options)>1) && \
		(Position:C15("{"; $config.options)=1)))
		$config.options:=JSON Parse:C1218($config.options)
		$config.options:=This:C1470._checkCompilationOptions($config.options)
	Else 
		$config.options:=New object:C1471
	End if 
	
	var $dependencyFile : 4D:C1709.File
	var $temp4DZs : Collection
	$temp4DZs:=New collection:C1472
	
	// adding potential component from folder Components
	If ($config.options.components=Null:C1517)
		var $databaseFolder : 4D:C1709.Folder
		$databaseFolder:=$config.file.parent.parent
		
		//var $dependencies : Collection
		//$dependencies:=This._getDependenciesFor($databaseFolder)
		
		If ($databaseFolder.folder("Components").exists)
			Storage:C1525.github.info("...adding dependencies")
			$config.options.components:=New collection:C1472
			var $dependency : 4D:C1709.Folder
			For each ($dependency; $databaseFolder.folder("Components").folders())
				If ($dependency.file($dependency.name+".4DZ").exists)
					Storage:C1525.github.info("Dependency archive found "+$dependency.name)
					$config.options.components.push($dependency.file($dependency.name+".4DZ"))
				End if 
				If ($dependency.extension=".4dbase")
					// XXX: maybe compile too if not yet (but will not work if not done in correct order)
					
					If ($dependency.folder("Project/DerivedData/CompiledCode").exists)
						$dependencyFile:=Folder:C1567(Temporary folder:C486; fk platform path:K87:2).file($dependency.name+".4DZ")
						$status:=ZIP Create archive:C1640($dependency; $dependencyFile; ZIP Without enclosing folder:K91:7)
						Storage:C1525.github.info("Dependency folder found "+$dependency.name)
						$config.options.components.push($dependencyFile)
						$temp4DZs.push($dependencyFile)
					End if 
				End if 
			End for each 
			
			For each ($dependencyFile; $databaseFolder.folder("Components").files().filter(Formula:C1597($1.value.extension=".4DZ")))
				$config.options.components.push($dependencyFile)
			End for each 
		End if 
	End if 
	// XXX: maybe check if all dep fullfilled to warn        
	
	Storage:C1525.github.info("...launching compilation with opt: "+JSON Stringify:C1217($config.options))
	
	$status:=Compile project:C1760($config.file; $config.options)
	
	For each ($dependencyFile; $temp4DZs)
		$dependencyFile.delete()
	End for each 
	
	// report final status
	If ($status.success)
		If (($status.errors#Null:C1517) && ($status.errors.length>0) && Not:C34(Bool:C1537($config.ignoreWarnings)))
			Storage:C1525.github.warning("⚠️ Build success with warnings")
			Storage:C1525.github.addToSummary("## ⚠️ Build success with warnings")
		Else 
			Storage:C1525.github.notice("✅ Build success")
			Storage:C1525.github.addToSummary("## ✅ Build success")
		End if 
	Else 
		Storage:C1525.github.error("‼️ Build failure")
		Storage:C1525.github.addToSummary("## ‼️ Build failure")
	End if 
	
	// report errors
	If (($status.errors#Null:C1517) && ($status.errors.length>0))
		
		Storage:C1525.github.startGroup("Compilation errors")
		
		var $error : Object
		For each ($error; $status.errors)
			This:C1470._reportCompilationError($error)
		End for each 
		
		Storage:C1525.github.endGroup()
		
	End if 
	
Function _checkCompilationOptions($options : Variant) : Object
	If (Value type:C1509($options)#Is object:K8:27)
		return New object:C1471()
	End if 
	
	If ($options.generateTypingMethods#Null:C1517)
		If (Not:C34(New collection:C1472("append"; "reset").includes($options.generateTypingMethods)))
			$options.generateTypingMethods:=Null:C1517
		End if 
	End if 
	
	If ($options.generateSymbols#Null:C1517)
		$options.generateSymbols:=isTruthly($options.generateSymbols)
	End if 
	
	If ($options.typeInferences#Null:C1517)
		If (Not:C34(New collection:C1472("none"; "all"; "locals").includes($options.typeInferences)))
			$options.typeInferences:="none"
		End if 
	End if 
	
	If ((Value type:C1509($options.targets)=Is text:K8:3) && (Length:C16($options.targets)>0))
		$options.targets:=Split string:C1554($options.targets; ","; sk ignore empty strings:K86:1)
	End if 
	// XXX check values inside New collection("x86_64_generic"0"arm64_macOS_lib") ?
	
	return $options
	
	// $error content :
	//   message: Text
	//   isError: Bool
	//   code: Object
	//   - type: String
	//   - database: String
	//   - methodName: String
	//   - path: String
	//   - file: 4D.File
	//   - line: Integer
	//   - lineInFile: Integer
Function _reportCompilationError($error : Object)
	var $config : Object
	$config:=This:C1470.config
	
	var $cmd : Text
	$cmd:=Bool:C1537($error.isError) ? "error" : "warning"
	
	If (Bool:C1537($config.ignoreWarnings) && ($cmd="warning"))
		return 
	End if 
	
	var $lineContent : Text
	$lineContent:=Split string:C1554($error.code.file.getText("UTF-8"; Document with LF:K24:22); "\n")[$error.lineInFile-1]
	
	var $relativePath : Text
	$relativePath:=Replace string:C233(File:C1566($error.code.file.platformPath; fk platform path:K87:2).path; $config.workingDirectory; "")
	
	// github action cmd
	Storage:C1525.github.cmd($cmd; String:C10($error.message); Error message:K38:3; New object:C1471("file"; String:C10($relativePath); "line"; String:C10($error.lineInFile)))
	
	If (Bool:C1537($error.isError))
		SetErrorStatus("compilationError")
	End if 
	
Function _getDependenciesFor($folder : 4D:C1709.Folder)->$dependencies : Collection
	
	$dependencies:=New collection:C1472
	Case of 
		: ($folder.file("make.json").exists)
			var $data : Object
			$data:=JSON Parse:C1218($folder.file("make.json").getText())
			If (Value type:C1509($data.components)=Is collection:K8:32)
				$dependencies:=$data.components
			End if 
	End case 
	
	// MARK:- release
	
Function release()->$status : Object
	var $config : Object
	$config:=This:C1470.config
	
	var $databaseFolder : 4D:C1709.Folder
	$databaseFolder:=$config.file.parent.parent
	var $databaseName : Text
	$databaseName:=$config.file.name
	Storage:C1525.github.info("...will archive "+$databaseName)
	
	// archive and move it
	var $buildDir : 4D:C1709.Folder
	$buildDir:=Folder:C1567(Temporary folder:C486; fk platform path:K87:2).folder(Generate UUID:C1066)
	$buildDir.create()
	
	Storage:C1525.github.info("🗃 4dz creation")
	// copy all base to destination
	var $destinationBase : 4D:C1709.Folder
	$destinationBase:=$databaseFolder.copyTo($buildDir; $databaseName+".4dbase"; fk overwrite:K87:5)
	// remove all sources (could be opt if want to distribute with sources, add an option?)
	This:C1470._cleanProject($destinationBase)
	
	// zip into 4dz compilation files
	$status:=ZIP Create archive:C1640($destinationBase.folder("Project"); $destinationBase.file($databaseName+".4DZ"))
	// finally clean all
	$destinationBase.folder("Project").delete(Delete with contents:K24:24)
	// XXX could clean also logs, pref etc.. but must not be in vcs...
	If (Not:C34($status.success))
		Storage:C1525.github.error("error when creating 4z:"+String:C10($status.statusText))
	End if 
	
	If ($status.success)
		// the 4d base
		Storage:C1525.github.info("📦 final archive creation")
		var $artefact : 4D:C1709.File
		$artefact:=$buildDir.file($databaseName+".zip")
		$status:=ZIP Create archive:C1640($destinationBase; $artefact)
		If (Not:C34($status.success))
			Storage:C1525.github.error("error when creating archive:"+String:C10($status.statusText))
		End if 
	End if 
	
	If ($status.success)
		// Send to release
		Storage:C1525.github.info("🚀 send archive to release")
		var $github : Object
		$status:=Storage:C1525.github.postArtefact($artefact)
		If (Not:C34($status.success))
			Storage:C1525.github.error("error when pusing artifact to release:"+String:C10($status.statusText))
		End if 
	End if 
	
	Storage:C1525.github.info("🧹 cleaning release working directory")
	$buildDir.delete(Delete with contents:K24:24)
	
Function _cleanProject($base : 4D:C1709.Folder)
	
	var $file : 4D:C1709.File
	var $folder : 4D:C1709.Folder
	
	// sources
	For each ($file; $base.folder("Project").files(fk recursive:K87:7).query("extension=.4dm"))
		$file.delete()
	End for each 
	
	// invisible files
	For each ($file; $base.files().query("fullName=.@"))
		$file.delete()
	End for each 
	For each ($folder; $base.folders().query("fullName=.@"))
		$folder.delete(Delete with contents:K24:24)
	End for each 
	
	