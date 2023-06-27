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
	End if 
	
	If (Value type:C1509($config.options)#Is object:K8:27)
		$config.options:=New object:C1471()
	End if 
	
	// adding potential component from folder Components
	If ($config.options.components=Null:C1517)
		var $databaseFolder : 4D:C1709.Folder
		$databaseFolder:=$config.file.parent.parent
		If ($databaseFolder.folder("Components").exists)
			$config.logger.info("...adding dependencies")
			$config.options.components:=New collection:C1472
			var $dependency : 4D:C1709.Folder
			For each ($dependency; $databaseFolder.folder("Components").folders())
				If ($dependency.file($dependency.name+".4DZ").exists)
					$config.options.components.push($dependency.file($dependency.name+".4DZ"))
				End if 
			End for each 
		End if 
	End if 
	
	$config.logger.info("...launching compilation with opt: "+JSON Stringify:C1217($config.options))
	
	$status:=Compile project:C1760($config.file; $config.options)
	
	// report final status
	If ($status.success)
		If (($status.errors#Null:C1517) && ($status.errors.length>0))
			$config.logger.warning("⚠️ Build success with warnings")
		Else 
			$config.logger.info("✅ Build success")
		End if 
	Else 
		$config.logger.error("‼️ Build failure")
	End if 
	
	// report errors
	If (($status.errors#Null:C1517) && ($status.errors.length>0))
		
		var $handle : 4D:C1709.FileHandle
		$handle:=Folder:C1567(fk database folder:K87:14).file("error").open("write")
		
		$config.logger.cmd("group"; "Compilation errors")
		
		var $error : Object
		For each ($error; $status.errors)
			This:C1470._reportCompilationError($error)
		End for each 
		
		$config.logger.cmd("endgroup"; "")
		
	End if 
	
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
	$cmd:=Choose:C955(Bool:C1537($error.isError); "error"; "warning")
	
	var $lineContent : Text
	$lineContent:=Split string:C1554($error.code.file.getText("UTF-8"; Document with LF:K24:22); "\n")[$error.lineInFile-1]
	
	var $relativePath : Text
	$relativePath:=Replace string:C233(File:C1566($error.code.file.platformPath; fk platform path:K87:2).path; $config.workingDirectory; "")
	
	// github action cmd
	$config.logger.cmd($cmd; String:C10($error.message); New object:C1471("file"; String:C10($relativePath); "line"; String:C10($error.lineInFile)))
	
	// MARK:- release
	
Function release()->$status : Object
	var $config : Object
	$config:=This:C1470.config
	
	var $databaseFolder : 4D:C1709.Folder
	$databaseFolder:=$config.file.parent.parent
	var $databaseName : Text
	$databaseName:=$config.file.name
	$config.logger.info("...will archive "+$databaseName)
	
	// archive and move it
	var $buildDir : 4D:C1709.Folder
	$buildDir:=Folder:C1567(Temporary folder:C486; fk platform path:K87:2).folder(Generate UUID:C1066)
	$buildDir.create()
	
	$config.logger.info("🗃 4dz creation")
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
		$config.logger.error("error when creating 4z:"+String:C10($status.statusText))
	End if 
	
	If ($status.success)
		// the 4d base
		$config.logger.info("📦 final archive creation")
		var $artefact : 4D:C1709.File
		$artefact:=$buildDir.file($databaseName+".zip")
		$status:=ZIP Create archive:C1640($destinationBase; $artefact)
		If (Not:C34($status.success))
			$config.logger.error("error when creating archive:"+String:C10($status.statusText))
		End if 
	End if 
	
	If ($status.success)
		// Send to release
		$config.logger.info("🚀 send archive to release")
		var $github : Object
		$github:=cs:C1710.github.new($config.logger)
		$status:=$github.postArtefact($artefact)
		If (Not:C34($status.success))
			$config.logger.error("error when pusing artifact to release:"+String:C10($status.statusText))
		End if 
	End if 
	
	$config.logger.info("🧹 cleaning release working directory")
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
	
	