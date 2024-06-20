Class constructor($config : Object)
	This:C1470._setup($config)
	
Function _setup($config : Object)
	This:C1470.config:=$config
	If (This:C1470.config=Null:C1517)
		This:C1470.config:=New object:C1471
	End if 
	
	If (Length:C16(String:C10($config.errorFlag))>0)
		Use (Storage:C1525.exit)
			Storage:C1525.exit.errorFlag:=String:C10($config.errorFlag)
			Storage:C1525.github.debug("error flag defined to "+String:C10($config.errorFlag))
		End use 
	End if 
	
	Case of 
		: ($config.debug#Null:C1517)
			$config.debug:=isTruthly($config.debug)
		Else 
			$config.debug:=(Structure file:C489(*)=Structure file:C489())
	End case 
	Use (Storage:C1525.github)
		Storage:C1525.github.isDebug:=Bool:C1537($config.debug)
	End use 
	
	$config.ignoreWarnings:=isTruthly($config.ignoreWarnings)
	$config.failOnWarning:=isTruthly($config.failOnWarning)
	
	
	// check "workingDirectory"
	If (Length:C16(String:C10($config.workingDirectory))>0)
		
		Storage:C1525.github.debug("workingDirectory="+String:C10($config.workingDirectory))
		
	Else 
		// CLEAN: see env var ? any means using 4D?
		
		If (Structure file:C489(*)=Structure file:C489())  // this base to test
			If (Is Windows:C1573)
				$config.workingDirectory:=Folder:C1567(fk database folder:K87:14).platformPath
			Else 
				$config.workingDirectory:=Folder:C1567(Folder:C1567(fk database folder:K87:14).platformPath; fk platform path:K87:2).path
			End if 
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
	If ((Value type:C1509($config.actions)=Is text:K8:3) && (Length:C16($config.actions)>0))
		If ($config.actions[[1]]="[")
			$config.actions:=JSON Parse:C1218($config.actions)
		Else 
			$config.actions:=Split string:C1554(String:C10($config.actions); ",")
		End if 
	End if 
	If (Value type:C1509($config.actions)#Is collection:K8:32)
		$config.actions:=New collection:C1472
	End if 
	If ($config.actions.length=0)
		$config.actions.push("build")
		If (Bool:C1537(Num:C11(String:C10(Storage:C1525.github._parseEnv()["RELEASE"]))))
			$config.actions.push("release")
		End if 
	End if 
	
	
	
	// MARK:- build
Function build()->$status : Object
	var $config : Object
	$config:=This:C1470.config
	
	// get compilation options
	Case of 
		: ((Value type:C1509($config.options)=Is text:K8:3) && \
			((Length:C16($config.options)>1) && \
			(Position:C15("{"; $config.options)=1)))
			$config.options:=JSON Parse:C1218($config.options)
			$config.options:=This:C1470._checkCompilationOptions($config.options)
		: (Value type:C1509($config.options)=Is object:K8:27)
			$config.options:=This:C1470._checkCompilationOptions($config.options)
		Else 
			$config.options:=New object:C1471
	End case 
	
	var $dependencyFile : 4D:C1709.File
	var $temp4DZs : Collection
	$temp4DZs:=New collection:C1472
	
	// adding potential component from folder Components
	If ($config.options.components=Null:C1517)
		$temp4DZs:=This:C1470._fillComponents($config)
	End if 
	
	Storage:C1525.github.info("...launching compilation with opt: "+JSON Stringify:C1217($config.options))
	
	$status:=Compile project:C1760($config.file; $config.options)
	
	For each ($dependencyFile; $temp4DZs)
		$dependencyFile.delete()
	End for each 
	
	// report final status
	Case of 
		: (Not:C34($status.success))
			Storage:C1525.github.error("‼️ Build failure")
			Storage:C1525.github.addToSummary("## ‼️ Build failure")
			
		: (($status.errors#Null:C1517) && ($status.errors.length>0) && Bool:C1537($config.failOnWarning))
			Storage:C1525.github.warning("‼️ Build failure due to warnings")
			Storage:C1525.github.addToSummary("## ‼️ Build failure due to warnings")
			
		: (($status.errors#Null:C1517) && ($status.errors.length>0) && Not:C34(Bool:C1537($config.ignoreWarnings)))
			Storage:C1525.github.warning("⚠️ Build success with warnings")
			Storage:C1525.github.addToSummary("## ⚠️ Build success with warnings")
			
		Else 
			Storage:C1525.github.notice("✅ Build success")
			Storage:C1525.github.addToSummary("## ✅ Build success")
			
	End case 
	
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
	
	If (This:C1470.config.actions.includes("release") && ($options.targets=Null:C1517))
		$options.targets:="all"
	End if 
	
	If ((Value type:C1509($options.targets)=Is text:K8:3) && (Length:C16($options.targets)>0))
		$options.targets:=Split string:C1554($options.targets; ","; sk ignore empty strings:K86:1)
	End if 
	If (Value type:C1509($options.targets)=Is collection:K8:32)
		$options.targets:=$options.targets.flatMap(This:C1470._fCheckTargetName).filter(Formula:C1597($1.value#Null:C1517))
	End if 
	
	return $options
	
Function _fCheckTargetName($object : Object)
	
	Case of 
		: (New collection:C1472("x86_64_generic"; "arm64_macOS_lib").includes($object.value))
			$object.result:=$object.value
		: (Not:C34(Value type:C1509($object.value)=Is text:K8:3))
			$object.result:=Null:C1517
		: ($object.value="current")
			$object.result:=(String:C10(Get system info:C1571().processor)="Apple@") ? "arm64_macOS_lib" : "x86_64_generic"
		: (($object.value="x86_64") || ($object.value="x86-64") || ($object.value="x64") || ($object.value="AMD64") || ($object.value="Intel 64"))
			$object.result:="x86_64_generic"
		: ($object.value="arm64")
			$object.result:="arm64_macOS_lib"
		: ($object.value="all")
			$object.result:=New collection:C1472("arm64_macOS_lib"; "x86_64_generic")
		Else 
			Storage:C1525.github.warning("Unknown target "+String:C10($object.value))
			$object.result:=Null:C1517
	End case 
	
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
	
	var $metadata : Object
	//var $lineContent : Text
	//$lineContent:=Split string($error.code.file.getText("UTF-8"; Document with LF); "\n")[$error.lineInFile-1]
	If ($error.code#Null:C1517)
		var $relativePath : Text
		$relativePath:=Replace string:C233(File:C1566($error.code.file.platformPath; fk platform path:K87:2).path; $config.workingDirectory; "")
		$metadata:=New object:C1471("file"; String:C10($relativePath); "line"; String:C10($error.lineInFile))
	End if 
	
	// github action cmd
	Storage:C1525.github.cmd($cmd; String:C10($error.message); Error message:K38:3; $metadata)
	
	If (Bool:C1537($error.isError) || Bool:C1537($config.failOnWarning))
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
	
Function _fillComponents($config : Object)->$temp4DZs : Collection
	var $baseFolder : 4D:C1709.Folder
	var $componentsFolder : 4D:C1709.Folder
	var $componentsFolders : Collection
	$temp4DZs:=New collection:C1472
	
	$baseFolder:=$config.file.parent.parent
	$componentsFolders:=New collection:C1472($baseFolder.folder("Components"); $baseFolder.folder("Build/Components"))
	
	var $dependencies : Collection
	$dependencies:=This:C1470._getDependenciesFor($baseFolder)
	
	Storage:C1525.github.debug("base folder "+$baseFolder.path)
	
	If ($dependencies.length>0)
		Storage:C1525.github.debug("expecting dependencies length "+String:C10($dependencies.length))
		If (Not:C34($componentsFolders.reduce(Formula:C1597($1.accumulator:=$1.accumulator || $1.value.exists); False:C215)))
			Storage:C1525.github.warning("No Components folder found for dependencies")
		End if 
	End if 
	
	Storage:C1525.github.info("...adding dependencies")
	$config.options.components:=New collection:C1472
	
	For each ($componentsFolder; $componentsFolders)
		This:C1470._addDepFromFolder($componentsFolder; $temp4DZs)
	End for each 
	
	//check if all dep fullfilled to warn if not
	If (($dependencies.length>0) && ($dependencies.length#$config.options.components.length))
		Storage:C1525.github.warning("Maybe missing dependencies: defined "+JSON Stringify:C1217($dependencies)+" but found in Components only "+String:C10($config.options.components.length))
	End if 
	
Function _addDepFromFolder($componentsFolder : 4D:C1709.Folder; $temp4DZs : Collection)
	If (Not:C34($componentsFolder.exists))
		return 
	End if 
	
	var $dependency : 4D:C1709.Folder
	var $dependencyFile : 4D:C1709.File
	var $status : Object
	var $config : Object
	$config:=This:C1470.config
	
	// MARK: add 4dbase
	For each ($dependency; $componentsFolder.folders().filter(Formula:C1597($1.value.extension=".4dbase")))
		
		Case of 
			: ($dependency.file($dependency.name+".4DZ").exists)  // archive exists
				
				Storage:C1525.github.info("Dependency archive found "+$dependency.name)
				$config.options.components.push($dependency.file($dependency.name+".4DZ"))
				
			: ($dependency.folder("Project").exists)  // maybe compiled or just have source but no archive yet
				
				This:C1470._checkCompile($dependency)  // seems needed even for check syntax
				
				$dependencyFile:=Folder:C1567(Temporary folder:C486; fk platform path:K87:2).file(This:C1470._not4DName($dependency.name)+".4DZ")
				$status:=ZIP Create archive:C1640($dependency; $dependencyFile; ZIP Without enclosing folder:K91:7)
				Storage:C1525.github.info("Dependency folder found "+$dependency.name)
				$config.options.components.push($dependencyFile)
				$temp4DZs.push($dependencyFile)
				
		End case 
		
	End for each 
	
	// MARK: add 4dz
	For each ($dependencyFile; $componentsFolder.files().filter(Formula:C1597($1.value.extension=".4DZ")))
		$config.options.components.push($dependencyFile)
	End for each 
	
Function _checkCompile($base : 4D:C1709.Folder)->$status : Object
	var $compiledCodeFolder : 4D:C1709.Folder
	$compiledCodeFolder:=$base.folder("Project/DerivedData/CompiledCode")
	If (($compiledCodeFolder.exists) && (($compiledCodeFolder.files().length+$compiledCodeFolder.folders().length)#0))  // XXX suppose already compiled, maybe do according to target check if there is arm lib etc...
		Storage:C1525.github.debug("Already compiled "+$base.path)
		return New object:C1471("success"; True:C214)
	End if 
	
	var $projectFile; $projectFileTmp : 4D:C1709.File
	$projectFile:=$base.folder("Project").files().filter(Formula:C1597($1.value.extension=".4DProject")).first()
	If ($projectFile=Null:C1517)
		Storage:C1525.github.warning("Try to compile "+$base.path+" but no 4DProject file found")
		return New object:C1471("success"; False:C215)
	End if 
	If (Position:C15("4D"; $projectFile.name)=1)
		$projectFileTmp:=$projectFile.copyTo($projectFile.parent; This:C1470._not4DName($projectFile.name)+$projectFile.extension; fk overwrite:K87:5)
		$projectFile.delete()  // CI things, if test locally maybe not
		Storage:C1525.github.debug("Renaming project file from '"+$projectFile.path+"' to '"+$projectFileTmp.path+"'("+String:C10(Bool:C1537($projectFileTmp.exists)))
		$projectFile:=$projectFileTmp
	End if 
	
	var $options : Object
	$options:=New object:C1471("targets"; New collection:C1472(String:C10(Get system info:C1571().processor)="Apple@") ? "arm64_macOS_lib" : "x86_64_generic")
	Storage:C1525.github.debug("compiling project file from '"+$projectFile.path+"' with option "+JSON Stringify:C1217($options))
	$status:=Compile project:C1760($projectFile; $options)
	
	// report errors
	If (($status.errors#Null:C1517) && ($status.errors.length>0))
		
		Storage:C1525.github.startGroup("Compilation errors - "+String:C10($projectFile.name))
		
		var $error : Object
		For each ($error; $status.errors)
			This:C1470._reportCompilationError($error)
		End for each 
		
		Storage:C1525.github.endGroup()
		
	End if 
	
Function _not4DName($text : Text) : Text
	var $to : Text
	For each ($to; New collection:C1472("4D "; "4D "; "4D-"; "4D_"; "4D"))
		$text:=Replace string:C233($text; $to; "")
	End for each 
	return $text
	
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
			Storage:C1525.github.error("error when pushing artifact to release:"+String:C10($status.statusText))
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
	
	// user pref
	For each ($folder; $base.folders().query("fullName=userPreferences.@"))
		$folder.delete(Delete with contents:K24:24)
	End for each 
	
	// tool4d (try to do bette later, ie. binary not inside current working dir)
	If ($base.file("tool4d.tar.xz").exists)
		$base.file("tool4d.tar.xz").delete()
	End if 
	If ($base.file("action.yml").exists)
		$base.file("action.yml").delete()
	End if 
	Case of 
		: (Is macOS:C1572)
			If ($base.folder("tool4d.app").exists)
				$base.folder("tool4d.app").delete(fk recursive:K87:7)
			End if 
		: (Is Windows:C1573)
			If ($base.folder("tool4d").exists)
				$base.folder("tool4d").delete(fk recursive:K87:7)
			End if 
		Else 
			If ($base.file("bin/tool4d").exists)
				$base.file("bin/tool4d").delete()
				If ($base.folder("bin/Resources").exists)
					$base.folder("bin/Resources").delete(fk recursive:K87:7)
				End if 
				If (($base.folder("bin").files().length+$base.folder("bin").folders().length)=0)
					$base.folder("bin").delete(fk recursive:K87:7)
				End if 
			End if 
	End case 
	
	// MARK:- run
	
Function run() : Object
	var $status : Object
	$status:=New object:C1471("success"; True:C214)
	
	Case of 
		: (Length:C16(String:C10(This:C1470.config.path))=0)
			
			Storage:C1525.github.error("no correct project file path provided")
			$status.errors:=New collection:C1472("no correct project file path provided")
			$status.success:=False:C215
			
		: (Not:C34(File:C1566(This:C1470.config.path).exists))
			
			Storage:C1525.github.error("project file "+This:C1470.config.path+" do not exists")
			$status.errors:=New collection:C1472("project file "+This:C1470.config.path+" do not exists")
			$status.success:=False:C215
			
		Else 
			
			Storage:C1525.github.debug("path="+String:C10(This:C1470.config.path))
			
			This:C1470.config.file:=File:C1566(This:C1470.config.path)  // used to get parents directory (for instance to get components)
			
			Storage:C1525.github.debug("...will execute actions: "+This:C1470.config.actions.join(","))
			
			var $action : Text
			For each ($action; This:C1470.config.actions) Until (Not:C34($status.success))
				If ((OB Instance of:C1731(This:C1470[$action]; 4D:C1709.Function)) && (Position:C15("_"; $action)#1) && ($action#"run"))
					Storage:C1525.github.notice("action "+$action)
					$status[$action]:=This:C1470[$action].call(This:C1470)
					$status.success:=$status.success & Bool:C1537($status[$action].success)
				Else 
					Storage:C1525.github.error("Unknown action "+$action)
					$status.success:=False:C215
				End if 
			End for each 
			
	End case 
	
	return $status
	
	