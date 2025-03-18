// property config : Object

Class constructor($config : Object)
	This:C1470._setup($config)
	
Function _setup($config : Object)
	This:C1470.config:=$config
	If (This:C1470.config=Null:C1517)
		Storage:C1525.github.debug("no config")
		This:C1470.config:=New object:C1471
	End if 
	
	If (Length:C16(String:C10(This:C1470.config.errorFlag))>0)
		Use (Storage:C1525.exit)
			Storage:C1525.exit.errorFlag:=String:C10(This:C1470.config.errorFlag)
			Storage:C1525.github.debug("error flag defined to "+String:C10(This:C1470.config.errorFlag))
		End use 
	End if 
	
	Case of 
		: (This:C1470.config.debug#Null:C1517)
			This:C1470.config.debug:=isTruthly(This:C1470.config.debug)
		Else 
			This:C1470.config.debug:=isDev
	End case 
	Use (Storage:C1525.github)
		Storage:C1525.github.isDebug:=Bool:C1537(This:C1470.config.debug)
	End use 
	
	This:C1470.config.ignoreWarnings:=isTruthly(This:C1470.config.ignoreWarnings)
	This:C1470.config.failOnWarning:=isTruthly(This:C1470.config.failOnWarning)
	
	
	// check "workingDirectory"
	If (Length:C16(String:C10(This:C1470.config.workingDirectory))>0)
		
		Storage:C1525.github.debug("workingDirectory="+String:C10(This:C1470.config.workingDirectory))
		
	Else 
		// CLEAN: see env var ? any means using 4D?
		
		If (isDev)  // this base to test
			If (Is Windows:C1573)
				This:C1470.config.workingDirectory:=Folder:C1567(fk database folder:K87:14).platformPath
			Else 
				This:C1470.config.workingDirectory:=Folder:C1567(Folder:C1567(fk database folder:K87:14).platformPath; fk platform path:K87:2).path
			End if 
		End if 
		
	End if 
	
	
	// check "path"
	If (Length:C16(String:C10(This:C1470.config.path))=0)
		
		// find first file into 
		If (This:C1470.config.workingDirectory#Null:C1517)
			
			If (Is Windows:C1573)
				This:C1470.config.workingDirectoryFolder:=Folder:C1567(This:C1470.config.workingDirectory; fk platform path:K87:2)
			Else 
				This:C1470.config.workingDirectoryFolder:=Folder:C1567(This:C1470.config.workingDirectory)
			End if 
			
			This:C1470.config.path:=String:C10(This:C1470.config.workingDirectoryFolder.folder("Project").files().filter(Formula:C1597($1.value.extension=".4DProject")).first().path)
			
			Storage:C1525.github.debug("find project file "+This:C1470.config.path)
			This:C1470.config.file:=File:C1566(This:C1470.config.path)
			If (This:C1470.config.file#Null:C1517)
				This:C1470.config.file:=File:C1566(This:C1470.config.file.platformPath; fk platform path:K87:2)  // unbox if needed
			End if 
		End if 
		
	Else 
		
		Storage:C1525.github.debug("config path "+This:C1470.config.path)
		var $methodOnError : Text
		$methodOnError:=Method called on error:C704()
		ON ERR CALL:C155("noError")  // no Try (compatible with v20
		If (Is Windows:C1573)
			This:C1470.config.file:=File:C1566(Replace string:C233(This:C1470.config.path; "\\"; "/"))
		Else 
			This:C1470.config.file:=File:C1566(This:C1470.config.path)
		End if 
		ON ERR CALL:C155($methodOnError)
		
		
		If ((This:C1470.config.file=Null:C1517) || Not:C34(This:C1470.config.file.exists) || (This:C1470._baseFolder()=Null:C1517))
			
			Storage:C1525.github.debug("project file not exists as full path, look for one in working folder")
			This:C1470.config.relative:=This:C1470.config.path
			
			// ensure not a mixed path with \ and / due to window full path + posix relative path of project ie be tolerant
			If (Is Windows:C1573)
				
				This:C1470.config.relative:=Replace string:C233(This:C1470.config.workingDirectory; This:C1470.config.path; "")
				This:C1470.config.relative:=Replace string:C233(Replace string:C233(This:C1470.config.workingDirectory; "\\"; ""); This:C1470.config.path; "")  // due to issue to pass it
				This:C1470.config.relative:=Replace string:C233(This:C1470.config.relative; "/"; "\\")
				If (Position:C15("\\"; This:C1470.config.relative)=1)
					This:C1470.config.relative:=Delete string:C232(This:C1470.config.relative; 1; 1)
				End if 
				
			End if 
			
			If (Is Windows:C1573)
				This:C1470.config.workingDirectoryFolder:=Folder:C1567(This:C1470.config.workingDirectory; fk platform path:K87:2)
			Else 
				This:C1470.config.workingDirectoryFolder:=Folder:C1567(This:C1470.config.workingDirectory)
			End if 
			
			ON ERR CALL:C155("noError")  // no Try (compatible with v20
			This:C1470.config.file:=This:C1470.config.workingDirectoryFolder.file(This:C1470.config.path)
			If (Is Windows:C1573)
				If (This:C1470.config.file=Null:C1517)  // retry with relative but prefixed by workding directory without \\ due to issue to pass args
					This:C1470.config.path:=Replace string:C233(This:C1470.config.path; Replace string:C233(This:C1470.config.workingDirectory; "\\"; ""); "")
					If (Position:C15("/"; This:C1470.config.path)=1)
						This:C1470.config.path:=Delete string:C232(This:C1470.config.path; 1; 1)
					End if 
					Storage:C1525.github.debug("config path with working directory try with modifyed one "+This:C1470.config.path)
					This:C1470.config.file:=This:C1470.config.workingDirectoryFolder.file(This:C1470.config.path)
				End if 
			End if 
			ON ERR CALL:C155($methodOnError)
			If (This:C1470.config.file#Null:C1517)
				This:C1470.config.path:=This:C1470.config.file.path
				Storage:C1525.github.debug("config path with working directory "+This:C1470.config.path)
				
				This:C1470.config.file:=File:C1566(This:C1470.config.file.platformPath; fk platform path:K87:2)  // unbox if needed
			End if 
			
		End if 
		
	End if 
	
	
	// check actions
	If ((Value type:C1509(This:C1470.config.actions)=Is text:K8:3) && (Length:C16(This:C1470.config.actions)>0))
		If (This:C1470.config.actions[[1]]="[")
			This:C1470.config.actions:=JSON Parse:C1218(This:C1470.config.actions)
		Else 
			This:C1470.config.actions:=Split string:C1554(String:C10(This:C1470.config.actions); ",")
		End if 
	End if 
	
	If (Value type:C1509(This:C1470.config.actions)#Is collection:K8:32)
		This:C1470.config.actions:=New collection:C1472
	End if 
	
	If (This:C1470.config.actions.length=0)
		This:C1470.config.actions.push("build")
	End if 
	
	If ((This:C1470.config.outputDirectory#Null:C1517) && (Value type:C1509(This:C1470.config.outputDirectory)=Is text:K8:3) && (Length:C16(This:C1470.config.outputDirectory)=0))
		This:C1470.config.outputDirectory:=Null:C1517
	End if 
	
	If (This:C1470.config.actions.includes("pack") && (This:C1470.config.outputDirectory=Null:C1517))
		
		// if pack action, we need an output dir
		This:C1470.config.outputDirectory:=This:C1470._baseFolder().folder("build")  // .build?
		Storage:C1525.github.debug("Set default output directory to "+This:C1470.config.outputDirectory.path)
		
	End if 
	
	If (This:C1470.config.actions.includes("pack") && Not:C34(This:C1470.config.actions.includes("build")))
		
		This:C1470.config.actions.unshift("build")
		Storage:C1525.github.debug("Action build added, because pack action defined")
		
	End if 
	
	If (This:C1470.config.outputUseContents=Null:C1517)
		This:C1470.config.outputUseContents:=This:C1470.config.actions.includes("pack")
	End if 
	
	If (This:C1470.config.outputDirectory#Null:C1517)
		
		If (Value type:C1509(This:C1470.config.outputDirectory)=Is text:K8:3)
			If (Is Windows:C1573)
				This:C1470.config.outputDirectory:=Replace string:C233(This:C1470.config.outputDirectory; "\\"; "/")
			End if 
			This:C1470.config.outputDirectory:=Folder:C1567(This:C1470.config.outputDirectory)
		End if 
		
		ASSERT:C1129(Value type:C1509(This:C1470.config.outputDirectory)=Is object:K8:27)  // even check folders?
		
		If (Not:C34(This:C1470.config.outputDirectory.exists))
			This:C1470.config.outputDirectory.create()  // TODO: if not log error?
		End if 
		
		This:C1470.config.outputDirectory:=Folder:C1567(This:C1470.config.outputDirectory.platformPath; fk platform path:K87:2)  // unbox
		
	End if 
	
	If (Not:C34(This:C1470.config.actions.includes("sign")) && (This:C1470.config.signCertificate#Null:C1517) && (Length:C16(String:C10(This:C1470.config.signCertificate))>0))
		This:C1470.config.actions.push("sign")
		Storage:C1525.github.debug("Action sign added, because sign certificate defined")
	End if 
	
	If ((Value type:C1509(This:C1470.config.signFiles)=Is text:K8:3) && (Length:C16(This:C1470.config.signFiles)>0))
		If (This:C1470.config.signFiles[[1]]="[")
			This:C1470.config.signFiles:=JSON Parse:C1218(This:C1470.config.signFiles)
		Else 
			This:C1470.config.signFiles:=Split string:C1554(String:C10(This:C1470.config.signFiles); ",")
		End if 
	End if 
	
	
	// MARK:- build
Function build()->$status : Object
	
	// get compilation options
	Case of 
		: ((Value type:C1509(This:C1470.config.options)=Is text:K8:3) && \
			((Length:C16(This:C1470.config.options)>1) && \
			(Position:C15("{"; This:C1470.config.options)=1)))
			This:C1470.config.options:=JSON Parse:C1218(This:C1470.config.options)
			This:C1470.config.options:=This:C1470._checkCompilationOptions(This:C1470.config.options)
		: (Value type:C1509(This:C1470.config.options)=Is object:K8:27)
			This:C1470.config.options:=This:C1470._checkCompilationOptions(This:C1470.config.options)
		Else 
			This:C1470.config.options:=This:C1470._checkCompilationOptions(New object:C1471)
	End case 
	
	var $dependencyFile : 4D:C1709.File
	var $temp4DZs : Collection
	$temp4DZs:=New collection:C1472
	
	
	// adding potential component from folder Components
	If (This:C1470.config.options.components=Null:C1517)
		$temp4DZs:=This:C1470._fillComponents()
	End if 
	
	Storage:C1525.github.info("...launching compilation with opt: "+JSON Stringify:C1217(This:C1470.config.options))
	
	If (This:C1470.config.outputDirectory#Null:C1517)
		
		var $baseFolder; $outputDir; $tmpFolder : 4D:C1709.Folder
		var $tmpFile : 4D:C1709.File
		$baseFolder:=This:C1470._baseFolder()
		$outputDir:=This:C1470.config.outputDirectory.folder(This:C1470.config.file.name+".4dbase")
		If ($outputDir.exists)
			If (Not:C34($outputDir.delete(fk recursive:K87:7)))
				
				Storage:C1525.error("Failed to clean output directory")
				$status:=New object:C1471("success"; False:C215; "errors"; New collection:C1472("Failed to clean output directory"))
				return $status
			End if 
		End if 
		
		If (Bool:C1537(This:C1470.config.outputUseContents))
			$outputDir:=$outputDir.folder("Contents")
		End if 
		
		If (Not:C34($outputDir.exists))
			$outputDir.create()
		End if 
		
		For each ($tmpFile; $baseFolder.files())
			If (("tool4d.tar.xz"#$tmpFile.fullName)\
				 && (".DS_Store"#$tmpFile.fullName))
				$tmpFile.copyTo($outputDir)
			End if 
		End for each 
		
		For each ($tmpFolder; $baseFolder.folders())
			If (($outputDir.parent.path#$tmpFolder.path)\
				 && ($tmpFolder.fullName#"Components")\
				 && (Position:C15("userPreferences."; $tmpFolder.fullName)#1)\
				 && (Position:C15(".git"; $tmpFolder.fullName)#1)\
				 && ($tmpFolder.fullName#"tool4d.app")\
				 && ($tmpFolder.fullName#"tool4d"))
				$tmpFolder.copyTo($outputDir)
			End if 
		End for each 
		
		This:C1470.config.file:=$outputDir.folder("Project").file(This:C1470.config.file.fullName)
		
	End if 
	
	If (This:C1470.config.file=Null:C1517)  // check it or the current base will be compiled instead
		Storage:C1525.github.error("‼️ Build failure: cannot get file to compile")
		$status.success:=False:C215
		return $status
	End if 
	If (Not:C34(This:C1470.config.file.exists))  // check it or the current base will be compiled instead
		Storage:C1525.github.error("‼️ Build failure: file to compile do not exists")
		$status.success:=False:C215
		return $status
	End if 
	
	$status:=Compile project:C1760(This:C1470.config.file; This:C1470.config.options)
	
	For each ($dependencyFile; $temp4DZs)
		$dependencyFile.delete()
	End for each 
	
	// report final status
	Case of 
		: (Not:C34($status.success))
			Storage:C1525.github.error("‼️ Build failure")
			Storage:C1525.github.addToSummary("## ‼️ Build failure")
			
		: (($status.errors#Null:C1517) && ($status.errors.length>0) && Bool:C1537(This:C1470.config.failOnWarning))
			Storage:C1525.github.error("‼️ Build failure due to warnings")
			Storage:C1525.github.addToSummary("## ‼️ Build failure due to warnings")
			$status.success:=False:C215
			
		: (($status.errors#Null:C1517) && ($status.errors.length>0) && Not:C34(Bool:C1537(This:C1470.config.ignoreWarnings)))
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
	
	If ((This:C1470.config.outputDirectory#Null:C1517) && ($options.targets=Null:C1517))  // if an output we want to build something
		$options.targets:=Is Windows:C1573 ? "current" : "all"
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
		: ($object.value="available")
			$object.result:=Is macOS:C1572 ? New collection:C1472("arm64_macOS_lib"; "x86_64_generic") : New collection:C1472("x86_64_generic")
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
	var $cmd : Text
	$cmd:=Bool:C1537($error.isError) ? "error" : "warning"
	
	If (Bool:C1537(This:C1470.config.ignoreWarnings) && ($cmd="warning"))
		return 
	End if 
	
	var $metadata : Object
	//var $lineContent : Text
	//$lineContent:=Split string($error.code.file.getText("UTF-8"; Document with LF); "\n")[$error.lineInFile-1]
	If ($error.code#Null:C1517)
		var $relativePath : Text
		$relativePath:=Replace string:C233(File:C1566($error.code.file.platformPath; fk platform path:K87:2).path; This:C1470.config.workingDirectory; "")
		$metadata:=New object:C1471("file"; String:C10($relativePath); "line"; String:C10($error.lineInFile))
	End if 
	
	// github action cmd
	Storage:C1525.github.cmd($cmd; String:C10($error.message); Error message:K38:3; $metadata)
	
	If (Bool:C1537($error.isError) || Bool:C1537(This:C1470.config.failOnWarning))
		Storage:C1525.exit.setErrorStatus("compilationError")
	End if 
	
Function _getDependenciesFor($folder : 4D:C1709.Folder)->$dependencies : Collection
	
	var $data : Object
	$dependencies:=New collection:C1472
	Case of 
		: ($folder=Null:C1517)
			// ignore
		: ($folder.file("make.json").exists)
			$data:=JSON Parse:C1218($folder.file("make.json").getText())
			If (Value type:C1509($data.components)=Is collection:K8:32)
				$dependencies:=$data.components
			End if 
		: ($folder.file("Project/Sources/dependencies.json").exists)
			
			$data:=JSON Parse:C1218($folder.file("Project/Sources/dependencies.json").getText())
			$dependencies:=OB Keys:C1719($data.dependencies)
			
	End case 
	
Function _fillComponents()->$temp4DZs : Collection
	var $baseFolder : 4D:C1709.Folder
	var $componentsFolder : 4D:C1709.Folder
	var $componentsFolders : Collection
	$temp4DZs:=New collection:C1472
	If (This:C1470.config.file=Null:C1517)
		Storage:C1525.github.debug("No file passed to fill components")
		return $temp4DZs
	End if 
	$baseFolder:=This:C1470._baseFolder()
	If ($baseFolder=Null:C1517)
		Storage:C1525.github.debug("No base folder for path "+This:C1470.config.file.path+". File exists?"+String:C10(This:C1470.config.file.exists))
		
		return $temp4DZs
	End if 
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
	This:C1470.config.options.components:=New collection:C1472
	
	For each ($componentsFolder; $componentsFolders)
		This:C1470._addDepFromFolder($componentsFolder; This:C1470.config.options; $temp4DZs)
	End for each 
	
	//check if all dep fullfilled to warn if not
	If (($dependencies.length>0) && ($dependencies.length#This:C1470.config.options.components.length))
		Storage:C1525.github.warning("Maybe missing dependencies: defined "+JSON Stringify:C1217($dependencies)+" but found in Components only "+String:C10(This:C1470.config.options.components.length))
	End if 
	
Function _addDepFromFolder($componentsFolder : 4D:C1709.Folder; $options : Object; $temp4DZs : Collection)
	If (Not:C34($componentsFolder.exists))
		return 
	End if 
	
	var $dependency : 4D:C1709.Folder
	var $dependencyFile; $4dz : 4D:C1709.File
	var $status : Object
	
	If ($options.components=Null:C1517)
		$options.components:=New collection:C1472()
	End if 
	
	// MARK: add 4dbase
	For each ($dependency; $componentsFolder.folders().filter(Formula:C1597($1.value.extension=".4dbase")))
		
		$4dz:=$dependency.file($dependency.name+".4DZ")
		If (Not:C34($4dz.exists))
			$4dz:=$dependency.folder("Contents").file($dependency.name+".4DZ")
		End if 
		
		Case of 
			: ($4dz.exists)  // archive exists
				
				Storage:C1525.github.info("Dependency archive found "+$dependency.name)
				$options.components.push($4dz)
				
			: ($dependency.folder("Project").exists)  // maybe compiled or just have source but no archive yet
				
				This:C1470._checkCompile($dependency; $temp4DZs)  // seems needed even for check syntax
				
				$dependencyFile:=Folder:C1567(Temporary folder:C486; fk platform path:K87:2).file(This:C1470._not4DName($dependency.name)+".4DZ")
				$status:=ZIP Create archive:C1640($dependency.folder("Project"); $dependencyFile)
				Storage:C1525.github.info("Dependency folder found "+$dependency.name)
				$options.components.push($dependencyFile)
				$temp4DZs.push($dependencyFile)
				
		End case 
		
	End for each 
	
	// MARK: add 4dz
	For each ($dependencyFile; $componentsFolder.files().filter(Formula:C1597($1.value.extension=".4DZ")))
		$options.components.push($dependencyFile)
	End for each 
	
Function _checkCompile($base : 4D:C1709.Folder; $temp4DZs : Collection)->$status : Object
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
	
	This:C1470._addDepFromFolder($base.folder("Components"); $options; $temp4DZs)
	
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
	
	// MARK:- pack
	
Function pack() : Object
	var $status : Object
	$status:=New object:C1471("success"; True:C214)
	
	If (This:C1470.config.outputDirectory=Null:C1517)
		$status.success:=False:C215
		Storage:C1525.github.error("Must have defined an output directory")
		$status.errors:=New collection:C1472("Must have defined an output directory")
		return $status
	End if 
	
	If (This:C1470.config.cleanSources=Null:C1517)
		This:C1470.config.cleanSources:=True:C214
	End if 
	
	
	var $packFile : 4D:C1709.File
	$packFile:=This:C1470._baseFolder().file(This:C1470.config.file.name+".4DZ")
	
	var $projectFolder : 4D:C1709.Folder
	$projectFolder:=This:C1470.config.file.parent
	
	If (This:C1470.config.cleanSources)
		This:C1470._cleanProjectSources($projectFolder)
	End if 
	
	$status:=ZIP Create archive:C1640($projectFolder; $packFile)
	
	If ($status.success)
		$projectFolder.delete(fk recursive:K87:7)
	End if 
	
	return $status
	
	
Function _cleanProjectSources($projectFolder : 4D:C1709.Folder)
	
	var $folder : 4D:C1709.Folder
	$folder:=$projectFolder.folder("Trash")
	
	If ($folder.exists)
		
		Storage:C1525.github.debug("Removing trash folder")
		$folder.delete(Delete with contents:K24:24)
		
	End if 
	
	var $sourcesFolder : 4D:C1709.Folder
	$sourcesFolder:=$projectFolder.folder("Sources")
	
	
	If ($sourcesFolder.file("folders.json").exists)
		
		Storage:C1525.github.debug("Removing private file")
		$sourcesFolder.file("folders.json").delete()
		
	End if 
	
	Storage:C1525.github.debug("Removing method source files")
	var $file : 4D:C1709.File
	For each ($file; $sourcesFolder.files(fk recursive:K87:7).query("extension=.4dm"))
		
		$file.delete()
		
	End for each 
	
	// Delete 'Methods', 'Triggers', 'DatabaseMethods', 'Classes' folders if empty
	var $folderName : Text
	For each ($folderName; New collection:C1472("Classes"; "Methods"; "Triggers"; "DatabaseMethods"))
		
		$folder:=$sourcesFolder.folder($folderName)
		
		If ($folder.exists)
			
			If ($folder.files().length=0)\
				 & ($folder.folders().length=0)
				
				$folder.delete()
				
			End if 
		End if 
	End for each 
	
	// Delete form objects folders
	For each ($folder; $sourcesFolder.folder("Forms").folders(fk recursive:K87:7).query("fullName=ObjectMethods"))
		
		If ($folder.files().length=0)\
			 & ($folder.folders().length=0)
			
			$folder.delete()
			
		End if 
		
	End for each 
	
	
	
	
	// MARK:- sign
	
Function _baseFolder() : 4D:C1709.Folder
	If (This:C1470.config.file=Null:C1517)
		return Null:C1517
	End if 
	If (This:C1470.config.file.parent=Null:C1517)
		return Null:C1517
	End if 
	return This:C1470.config.file.parent.parent
	
Function sign() : Object
	
	var $baseFolder : 4D:C1709.Folder
	$baseFolder:=This:C1470._baseFolder()
	
	If (Not:C34(Is macOS:C1572))
		Storage:C1525.github.warning("Signature ignored on this OS")
		return New object:C1471("success"; True:C214)
	End if 
	
	var $signScriptFile : 4D:C1709.File
	$signScriptFile:=Folder:C1567(Application file:C491; fk platform path:K87:2).file("Contents/Resources/SignApp.sh")
	
	If (Not:C34($signScriptFile.exists))
		Storage:C1525.github.error("No SignApp.sh script")
		return New object:C1471("success"; False:C215; "errors"; New collection:C1472("No SignApp.sh script"))
	End if 
	
	var $entitlementsFile : 4D:C1709.File
	
	If ((Value type:C1509(This:C1470.config.entitlementsFile)=Is text:K8:3) && (Length:C16(This:C1470.config.entitlementsFile)>0))
		
		$entitlementsFile:=File:C1566(Replace string:C233(This:C1470.config.entitlementsFile; "\\"; "/"))
		
		If (Not:C34($entitlementsFile.exists))
			Storage:C1525.github.debug("absolute not exists:"+$entitlementsFile.path)
			$entitlementsFile:=This:C1470.config.workingDirectory.file(Replace string:C233(This:C1470.config.entitlementsFile; "\\"; "/"))
			Storage:C1525.github.debug("try with relative to working dir:"+$entitlementsFile.path)
		End if 
		
		If (Not:C34($entitlementsFile.exists))
			Storage:C1525.github.error("defined entitlements file seems to not exists")
			return New object:C1471("success"; False:C215; "errors"; New collection:C1472("No entitlements files"))
		End if 
	Else 
		
		$entitlementsFile:=Folder:C1567(fk resources folder:K87:11).file("default.entitlements")
		
	End if 
	
	
	If (Not:C34($entitlementsFile.exists))
		Storage:C1525.github.error("No entitlements files")
		return New object:C1471("success"; False:C215; "errors"; New collection:C1472("No entitlements files"))
	End if 
	
	$entitlementsFile:=File:C1566($entitlementsFile.platformPath; fk platform path:K87:2)
	
	// customize by config?
	
	var $certificateName : Text
	$certificateName:=String:C10(This:C1470.config.signCertificate)
	If (Length:C16($certificateName)=0)
		Storage:C1525.github.error("No certificate name specified")
		return New object:C1471("success"; False:C215; "errors"; New collection:C1472("No certificate name specified"))
	End if 
	
	var $cmdPrefix; $cmdSuffix; $cmd : Text
	$cmdPrefix:="\""+$signScriptFile.path+"\" \""+$certificateName+"\" "
	$cmdSuffix:=" \""+$entitlementsFile.path+"\""
	
	// Sign base
	
	var $status : Object
	$status:=New object:C1471("success"; True:C214)
	
	If ((This:C1470.config.signFiles#Null:C1517) && (Value type:C1509(This:C1470.config.signFiles)=Is collection:K8:32))
		
		Storage:C1525.github.notice("Sign defined files")
		
		var $signFileScriptFile : 4D:C1709.File
		
		$signFileScriptFile:=File:C1566(Folder:C1567(fk resources folder:K87:11).file("SignFile.sh").platformPath; fk platform path:K87:2)
		$cmdPrefix:="\""+$signFileScriptFile.path+"\" \""+$certificateName+"\" "
		
		var $signFile : 4D:C1709.File
		var $signFilePath : Text
		For each ($signFilePath; This:C1470.config.signFiles)
			
			Storage:C1525.github.notice("Sign "+$signFilePath)
			
			$signFile:=$baseFolder.file($signFilePath)
			Storage:C1525.github.debug("File "+$signFile.path+" exists?"+String:C10($signFile.exists))
			
			$cmd:=$cmdPrefix+"\""+$signFile.path+"\""+$cmdSuffix
			Storage:C1525.github.debug($cmd)
			$worker:=4D:C1709.SystemWorker.new($cmd).wait()
			
			If (($worker.response#Null:C1517) && (Length:C16($worker.response)>0))
				Storage:C1525.github.info($worker.response)
			End if 
			If (($worker.responseError#Null:C1517) && (Length:C16($worker.responseError)>0))
				Storage:C1525.github.warning($worker.responseError)
			End if 
			
			var $statusFile : Object
			$statusFile:=New object:C1471("success"; $worker.exitCode=0; "errors"; $worker.errors; "exitCode"; $worker.exitCode)
			Storage:C1525.github.debug(JSON Stringify:C1217($statusFile))
			
			This:C1470._mergeResult($status; $statusFile)
			
		End for each 
	End if 
	
	Storage:C1525.github.notice("Sign "+$baseFolder.path)
	$cmd:=$cmdPrefix+"\""+$baseFolder.path+"\""+$cmdSuffix
	
	Storage:C1525.github.debug($cmd)
	var $worker : 4D:C1709.SystemWorker
	$worker:=4D:C1709.SystemWorker.new($cmd).wait()
	
	If (($worker.response#Null:C1517) && (Length:C16($worker.response)>0))
		Storage:C1525.github.info($worker.response)
	End if 
	If (($worker.responseError#Null:C1517) && (Length:C16($worker.responseError)>0))
		Storage:C1525.github.warning($worker.responseError)
	End if 
	
	$statusFile:=New object:C1471("success"; $worker.exitCode=0; "errors"; $worker.errors; "exitCode"; $worker.exitCode)
	Storage:C1525.github.debug(JSON Stringify:C1217($statusFile))
	
	This:C1470._mergeResult($status; $statusFile)
	
	return $status
	
Function _mergeResult($to : Object; $from : Object)
	
	If ($from.errors#Null:C1517)
		If ($to.errors=Null:C1517)
			$to.errors:=New collection:C1472
		End if 
		$to.errors.combine($from.errors)
	End if 
	$to.success:=$to.success && $from.success
	
	// MARK:- archive
	
Function archiveName() : Text
	If ((Value type:C1509(This:C1470.config.archiveName)=Is text:K8:3) && (Length:C16(This:C1470.config.archiveName)>0))
		return This:C1470.config.archiveName
	End if 
	
	return Replace string:C233(This:C1470.config.file.name; " "; "-")+".zip"
	
Function archive() : Object
	var $baseFolder : 4D:C1709.Folder
	$baseFolder:=This:C1470._baseFolder()
	
	This:C1470._cleanDatabase($baseFolder)
	var $status : Object
	
	Storage:C1525.github.debug("Action build added, because pack action defined")
	
	var $archiveFile : 4D:C1709.File
	$archiveFile:=$baseFolder.parent.file(This:C1470.archiveName())
	
	If (Is macOS:C1572)
		var $cmd : Text
		
		$cmd:="ditto -c -k --rsrc --sequesterRsrc --keepParent \""+$baseFolder.path+"\" \""+$archiveFile.path+"\""
		
		var $worker : 4D:C1709.SystemWorker
		$worker:=4D:C1709.SystemWorker.new($cmd).wait()
		
		If (($worker.response#Null:C1517) && (Length:C16($worker.response)>0))
			Storage:C1525.github.info($worker.response)
		End if 
		If (($worker.responseError#Null:C1517) && (Length:C16($worker.responseError)>0))
			Storage:C1525.github.warning($worker.responseError)
		End if 
		
		$status:=New object:C1471("success"; $worker.exitCode=0; "errors"; $worker.errors)
		
	Else 
		
		$status:=ZIP Create archive:C1640($baseFolder; $archiveFile)
		
	End if 
	
	If (Bool:C1537($status.success))
		Storage:C1525.github.info("Archive created at path "+$archiveFile.path)
	Else 
		Storage:C1525.github.error("Failed to archive "+$baseFolder.path)
	End if 
	Storage:C1525.github.debug(JSON Stringify:C1217($status))
	
	return $status
	
Function _cleanDatabase($base : 4D:C1709.Folder)
	
	var $file : 4D:C1709.File
	var $folder : 4D:C1709.Folder
	
	If (This:C1470.config.cleanInvisible=Null:C1517)
		This:C1470.config.cleanInvisible:=True:C214
	End if 
	If (This:C1470.config.cleanData=Null:C1517)
		This:C1470.config.cleanData:=True:C214
	End if 
	
	// invisible files
	If (This:C1470.config.cleanInvisible)
		For each ($file; $base.files().query("fullName=.@"))
			$file.delete()
		End for each 
		
		For each ($folder; $base.folders().query("fullName=.@"))
			$folder.delete(Delete with contents:K24:24)
		End for each 
	End if 
	
	
	// Delete the Logs folder
	$folder:=$base.folder("Logs")
	
	If ($folder.exists)
		
		Storage:C1525.github.debug("Removing logs folder")
		$folder.delete(Delete with contents:K24:24)
		
	End if 
	
	// Delete the Preferences folder
	$folder:=$base.folder("Preferences")
	
	If ($folder.exists)
		
		Storage:C1525.github.debug("Removing Preferences folder")
		$folder.delete(Delete with contents:K24:24)
		
	End if 
	
	// Delete the Settings folder
	$folder:=$base.folder("Settings")
	
	If ($folder.exists)
		
		Storage:C1525.github.debug("Removing Settings folder")
		$folder.delete(Delete with contents:K24:24)
		
	End if 
	
	// Delete the user pref
	For each ($folder; $base.folders().query("fullName=userPreferences.@"))
		
		Storage:C1525.github.debug("Removing preferences folder "+$folder.path)
		$folder.delete(Delete with contents:K24:24)
		
	End for each 
	
	// Delete some other unused files 
	If (This:C1470.config.cleanData)
		For each ($file; $folder.files().query("extension=.4DD OR extension=.Match"))
			
			Storage:C1525.github.debug("Removing data file "+$file.path)
			$file.delete()
			
		End for each 
	End if 
	
	
	// MARK:- run
	
Function run() : Object
	var $status : Object
	$status:=New object:C1471("success"; True:C214)
	
	Case of 
		: (Length:C16(String:C10(This:C1470.config.path))=0)
			
			Storage:C1525.github.error("no correct project file path provided")
			$status.errors:=New collection:C1472("no correct project file path provided")
			$status.success:=False:C215
			
		: (FileSafe(This:C1470.config.path)=Null:C1517)  // just because it failed with mixed / and \ TODO: clean path
			
			Storage:C1525.github.error("project file "+This:C1470.config.path+" cannot be parsed")
			$status.errors:=New collection:C1472("project file "+This:C1470.config.path+" cannot be parsed")
			$status.success:=False:C215
			
		: (Not:C34(FileSafe(This:C1470.config.path).exists))
			
			Storage:C1525.github.error("project file "+This:C1470.config.path+" do not exists")
			$status.errors:=New collection:C1472("project file "+This:C1470.config.path+" do not exists")
			$status.success:=False:C215
			
		Else 
			
			Storage:C1525.github.debug("path="+String:C10(This:C1470.config.path))
			
			Storage:C1525.github.debug("...will execute actions: "+This:C1470.config.actions.join(","))
			
			This:C1470.config.actions:=This:C1470._sortActions(This:C1470.config.actions)
			
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
	
Function _sortActions($actions : Collection) : Collection
	
	var $sortedAction : Collection
	$sortedAction:=New collection:C1472()
	
	var $action : Text
	For each ($action; New collection:C1472("clean"; "build"; "sign"; "pack"; "archive"))
		
		If ($actions.includes($action))
			$sortedAction.push($action)
		End if 
		
	End for each 
	
	return $sortedAction