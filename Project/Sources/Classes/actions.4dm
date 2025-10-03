// property config : Object
// property _envCache : Object

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
	This:C1470.config.stripTests:=isTruthly(This:C1470.config.stripTests)
	
	
	// check "workingDirectory"
	If (Length:C16(String:C10(This:C1470.config.workingDirectory))>0)
		
		Storage:C1525.github.debug("📁 Working directory provided: "+String:C10(This:C1470.config.workingDirectory))
		
	Else 
		// CLEAN: see env var ? any means using 4D?
		
		Storage:C1525.github.debug("📁 No working directory provided, attempting auto-detection")
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
			
			Storage:C1525.github.debug("🔍 Auto-discovered project file: "+This:C1470.config.path)
			This:C1470.config.file:=File:C1566(This:C1470.config.path)
			If (This:C1470.config.file#Null:C1517)
				This:C1470.config.file:=File:C1566(This:C1470.config.file.platformPath; fk platform path:K87:2)  // unbox if needed
			End if 
		End if 
		
	Else 
		
		Storage:C1525.github.debug("🔗 Project path provided: "+This:C1470.config.path)
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
	
	
	// MARK: check actions
	If ((Value type:C1509(This:C1470.config.actions)=Is text:K8:3) && (Length:C16(This:C1470.config.actions)>0))
		//%W-533.1
		If (This:C1470.config.actions[[1]]="[")
			//%W+533.1
			This:C1470.config.actions:=JSON Parse:C1218(This:C1470.config.actions)
		Else 
			This:C1470.config.actions:=Split string:C1554(String:C10(This:C1470.config.actions); ",")
		End if 
	End if 
	
	If (Value type:C1509(This:C1470.config.actions)#Is collection:K8:32)
		This:C1470.config.actions:=New collection:C1472
	End if 
	
	If (This:C1470.config.actions.length=0)
		If (Storage:C1525.github.isRelease())
			This:C1470.config.actions.push("release")
		Else 
			This:C1470.config.actions.push("build")
		End if 
	End if 
	
	If (This:C1470.config.actions.includes("pack") && Not:C34(This:C1470.config.actions.includes("build")))
		
		This:C1470.config.actions.unshift("build")
		Storage:C1525.github.debug("Action build added, because pack action defined")
		
	End if 
	
	If (Not:C34(This:C1470.config.actions.includes("sign")) && (This:C1470.config.signCertificate#Null:C1517) && (Length:C16(String:C10(This:C1470.config.signCertificate))>0))
		This:C1470.config.actions.push("sign")
		Storage:C1525.github.debug("Action sign added, because sign certificate defined")
	End if 
	
	This:C1470.config.actions:=This:C1470._checkActions(This:C1470.config.actions)
	
	If (This:C1470.config.outputUseContents=Null:C1517)
		This:C1470.config.outputUseContents:=This:C1470.config.actions.includes("pack")
	End if 
	
	If ((Value type:C1509(This:C1470.config.signFiles)=Is text:K8:3) && (Length:C16(This:C1470.config.signFiles)>0))
		//%W-533.1
		If (This:C1470.config.signFiles[[1]]="[")
			//%W+533.1
			This:C1470.config.signFiles:=JSON Parse:C1218(This:C1470.config.signFiles)
		Else 
			This:C1470.config.signFiles:=Split string:C1554(String:C10(This:C1470.config.signFiles); ",")
		End if 
	End if 
	
	// Parse signAsBundle option
	Case of 
		: (This:C1470.config.signAsBundle#Null:C1517)
			This:C1470.config.signAsBundle:=isTruthly(This:C1470.config.signAsBundle)
		Else 
			This:C1470.config.signAsBundle:=False:C215
	End case 
	
	This:C1470.checkOuputDirectory()
	
Function checkOuputDirectory()
	
	If ((This:C1470.config.outputDirectory#Null:C1517) && (Value type:C1509(This:C1470.config.outputDirectory)=Is text:K8:3) && (Length:C16(This:C1470.config.outputDirectory)=0))
		This:C1470.config.outputDirectory:=Null:C1517
	End if 
	
	If (This:C1470.config.actions.includes("pack") && (This:C1470.config.outputDirectory=Null:C1517))
		
		// if pack action, we need an output dir
		This:C1470.config.outputDirectory:=This:C1470._baseFolder().folder("build")  // .build?
		Storage:C1525.github.debug("Set default output directory to "+This:C1470.config.outputDirectory.path)
		
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
	
	
	// MARK:- clean
Function clean()->$status : Object
	$status:=New object:C1471("success"; True:C214)
	
	Storage:C1525.github.debug("🧹 Starting clean process")
	
	This:C1470.checkOuputDirectory()
	
	If (This:C1470.config.outputDirectory#Null:C1517)
		Storage:C1525.github.debug("Output directory: "+String:C10(This:C1470.config.outputDirectory.path))
		
		This:C1470.config.outputDirectory.delete(Delete with contents:K24:24)
		
	Else 
		
		// TODO: clean build data on current basse
		
	End if 
	
	// MARK:- build
Function build()->$status : Object
	
	If (Storage:C1525.github.isDebug)
		Storage:C1525.github.debug("🔨 Starting build process")
		Storage:C1525.github.debug("Project file: "+String:C10(This:C1470.config.path))
		If (This:C1470.config.outputDirectory#Null:C1517)
			Storage:C1525.github.debug("Output directory: "+String:C10(This:C1470.config.outputDirectory.path))
			Storage:C1525.github.debug("Strip tests: "+String:C10(This:C1470.config.stripTests))
		End if 
	End if 
	
	// Execute before-build script/binary if defined
	If (Length:C16(String:C10(This:C1470.config.beforeBuild))>0)
		This:C1470._executeHook("beforeBuild")
	End if 
	
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
	If (Storage:C1525.github.isDebug)
		Storage:C1525.github.debug("📋 Compilation details:")
		Storage:C1525.github.debug("  - Project file: "+String:C10(This:C1470.config.file.path))
		Storage:C1525.github.debug("  - Options: "+JSON Stringify:C1217(This:C1470.config.options))
		Storage:C1525.github.debug("  - Components: "+String:C10($temp4DZs.length)+" temporary components")
	End if 
	
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
			Storage:C1525.github.debug("...into subfolder Contents: "+$outputDir.path)
		End if 
		
		If (Not:C34($outputDir.exists))
			Storage:C1525.github.debug("...create output folder")
			$outputDir.create()
		End if 
		
		var $excludeFiles : Collection
		$excludeFiles:=New collection:C1472("tool4d.tar.xz"; ".DS_Store")
		For each ($tmpFile; $baseFolder.files())
			If (Not:C34($excludeFiles.includes($tmpFile.fullName)))
				$tmpFile.copyTo($outputDir)
			End if 
		End for each 
		
		var $excludeFolders : Collection
		$excludeFolders:=New collection:C1472("Components"; "tool4d.app"; "tool4d")
		For each ($tmpFolder; $baseFolder.folders())
			If ((Position:C15($tmpFolder.path; $outputDir.path)#1)\
				 && (Position:C15("userPreferences."; $tmpFolder.fullName)#1) && (Position:C15(".git"; $tmpFolder.fullName)#1)\
				 && (Not:C34($excludeFolders.includes($tmpFolder.fullName))))
				$tmpFolder.copyTo($outputDir)
			End if 
		End for each 
		
		This:C1470.config.file:=$outputDir.folder("Project").file(This:C1470.config.file.fullName)
		
		// Strip test methods if requested (whether building to output directory or in place)
		
		This:C1470._stripTestMethods($outputDir.folder("Project"))
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
	
	Storage:C1525.github.debug("⚙️ Calling Compile project for '"+This:C1470.config.file.path+"' with option "+JSON Stringify:C1217(This:C1470.config.options)+"...")
	$status:=Compile project:C1760(This:C1470.config.file; This:C1470.config.options)
	Storage:C1525.github.debug("📊 Compilation result: success="+String:C10($status.success)+", errors="+String:C10($status.errors.length))
	
	// clean temp 4dz
	For each ($dependencyFile; $temp4DZs)
		$dependencyFile.delete()
	End for each 
	
	// clean user preferences (could be created by compile command)
	If ($outputDir#Null:C1517)
		var $folders : Collection
		$folders:=$outputDir.folders().filter(Formula:C1597(Position:C15("userPreferences."; $1.value.fullName)=1))
		For each ($tmpFolder; $folders)
			Storage:C1525.github.debug("🧹 Clean user preferences folder "+$tmpFolder.path)
			$tmpFolder.delete(fk recursive:K87:7)
		End for each 
	End if 
	
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
	
	// Execute after-build script/binary if defined
	If ((Length:C16(String:C10(This:C1470.config.afterBuild))>0)) && (($status.success) || (Bool:C1537(This:C1470.config.alwaysRunAfterBuild)))
		This:C1470._executeHook("afterBuild")
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
	
	If ((This:C1470.config.outputDirectory#Null:C1517) && (($options.targets=Null:C1517) || ((Value type:C1509($options.targets)=Is text:K8:3) && (Length:C16($options.targets)=0))))  // if an output we want to build something
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
			$object.result:=(String:C10(System info:C1571().processor)="Apple@") ? "arm64_macOS_lib" : "x86_64_generic"
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
	
	Storage:C1525.github.debug("🔧 Filling components from Components folder")
	
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
	$options:=New object:C1471("targets"; New collection:C1472(String:C10(System info:C1571().processor)="Apple@") ? "arm64_macOS_lib" : "x86_64_generic")
	
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
	
Function _stripTestMethods($projectFolder : 4D:C1709.Folder)
	
	If (Not:C34(Bool:C1537(This:C1470.config.stripTests)))
		return 
	End if 
	
	Storage:C1525.github.info("Stripping test methods (test_*.4dm) from project")
	
	var $sourcesFolder : 4D:C1709.Folder
	$sourcesFolder:=$projectFolder.folder("Sources")
	
	If (Not:C34($sourcesFolder.exists))
		Storage:C1525.github.debug("Sources folder does not exist, nothing to strip")
		return 
	End if 
	
	var $testFiles : Collection
	$testFiles:=$sourcesFolder.files(fk recursive:K87:7).query("extension=.4dm AND fullName=test_@")
	
	Storage:C1525.github.debug("Found "+String:C10($testFiles.length)+" test method files to remove")
	
	var $file : 4D:C1709.File
	For each ($file; $testFiles)
		Storage:C1525.github.debug("Removing test method: "+$file.path)
		$file.delete()
	End for each 
	
	If ($testFiles.length>0)
		Storage:C1525.github.info("Successfully removed "+String:C10($testFiles.length)+" test method files")
	End if 
	
	// MARK:- pack
	
Function pack() : Object
	var $status : Object
	$status:=New object:C1471("success"; True:C214)
	
	Storage:C1525.github.debug("📦 Starting pack process")
	Storage:C1525.github.debug("Clean sources: "+String:C10(This:C1470.config.cleanSources))
	
	If (This:C1470.config.outputDirectory=Null:C1517)
		$status.success:=False:C215
		Storage:C1525.github.error("Must have defined an output directory")
		$status.errors:=New collection:C1472("Must have defined an output directory")
		return $status
	End if 
	Storage:C1525.github.debug("Output directory: "+String:C10(This:C1470.config.outputDirectory.path))
	
	If (This:C1470.config.cleanSources=Null:C1517)
		This:C1470.config.cleanSources:=True:C214
	End if 
	
	
	var $packFile : 4D:C1709.File
	$packFile:=This:C1470._baseFolder().file(This:C1470.config.file.name+".4DZ")
	
	var $projectFolder : 4D:C1709.Folder
	$projectFolder:=This:C1470.config.file.parent
	
	If (This:C1470.config.cleanSources)
		Storage:C1525.github.debug("🧹 Cleaning project sources before packing")
		This:C1470._cleanProjectSources($projectFolder)
	End if 
	
	Storage:C1525.github.debug("📋 Creating ZIP archive: "+$packFile.path)
	$status:=ZIP Create archive:C1640($projectFolder; $packFile)
	Storage:C1525.github.debug("📦 ZIP creation result: success="+String:C10($status.success))
	
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
	
Function _getEnv() : Object
	If (This:C1470._envCache=Null:C1517)
		This:C1470._envCache:=GetEnv
	End if 
	return This:C1470._envCache
	
Function _baseFolder() : 4D:C1709.Folder
	If (This:C1470.config.file=Null:C1517)
		return Null:C1517
	End if 
	If (This:C1470.config.file.parent=Null:C1517)
		return Null:C1517
	End if 
	return This:C1470.config.file.parent.parent
	
	
	// MARK:- sign
	
Function _unlockKeychain($name : Text; $path : Text; $password : Text) : Object
	If (Length:C16($password)=0)
		return New object:C1471("success"; True:C214)  // Skip if no password
	End if 
	
	Storage:C1525.github.notice("Unlocking "+$name+" keychain")
	
	// First, add custom keychain to search list if it's not a standard keychain
	If (Position:C15("custom"; $name)=1)
		Storage:C1525.github.debug("Checking if custom keychain needs to be added to search list")
		
		// Get current keychain list
		var $listWorker : 4D:C1709.SystemWorker
		$listWorker:=4D:C1709.SystemWorker.new("security list-keychains").wait()
		
		If ($listWorker.exitCode=0)
			var $currentKeychains : Text
			$currentKeychains:=$listWorker.response
			
			// Check if custom keychain is already in the list
			If (Position:C15($path; $currentKeychains)>0)
				Storage:C1525.github.info($name+" keychain already in search list")
			Else 
				Storage:C1525.github.debug("Adding custom keychain to search list")
				
				// Clean up the output for the command
				var $cleanKeychains : Text
				$cleanKeychains:=Replace string:C233($currentKeychains; "\""; "")  // Remove quotes
				$cleanKeychains:=Replace string:C233($cleanKeychains; Char:C90(Line feed:K15:40); " ")  // Replace newlines with spaces
				
				// Add custom keychain to the front of the list
				var $addKeychainCmd : Text
				$addKeychainCmd:="security list-keychains -s \""+$path+"\" "+$cleanKeychains
				Storage:C1525.github.debug("Keychain command: "+$addKeychainCmd)
				
				var $addWorker : 4D:C1709.SystemWorker
				$addWorker:=4D:C1709.SystemWorker.new($addKeychainCmd).wait()
				
				If ($addWorker.exitCode#0)
					Storage:C1525.github.warning("Failed to add "+$name+" keychain to search list: "+String:C10($addWorker.responseError))
				Else 
					Storage:C1525.github.info($name+" keychain added to search list")
				End if 
			End if 
		Else 
			Storage:C1525.github.warning("Could not get current keychain list: "+String:C10($listWorker.responseError))
		End if 
	End if 
	
	// Then unlock the keychain
	var $unlockCmd : Text
	$unlockCmd:="security unlock-keychain -p \""+$password+"\" \""+$path+"\""
	Storage:C1525.github.debug("Executing "+$name+" keychain unlock command")
	
	var $keychainWorker : 4D:C1709.SystemWorker
	$keychainWorker:=4D:C1709.SystemWorker.new($unlockCmd).wait()
	
	If ($keychainWorker.exitCode#0)
		var $errorMsg : Text
		$errorMsg:="Failed to unlock "+$name+" keychain: "+String:C10($keychainWorker.responseError)
		Storage:C1525.github.error($errorMsg)
		return New object:C1471("success"; False:C215; "errors"; New collection:C1472($errorMsg))
	Else 
		Storage:C1525.github.info($name+" keychain unlocked successfully")
		return New object:C1471("success"; True:C214)
	End if 
	
Function sign() : Object
	
	If (Storage:C1525.github.isDebug)
		Storage:C1525.github.debug("🔐 Starting sign process")
		Storage:C1525.github.debug("Sign certificate: "+String:C10(This:C1470.config.signCertificate))
		Storage:C1525.github.debug("Sign files: "+String:C10(This:C1470.config.signFiles))
		Storage:C1525.github.debug("Sign as bundle: "+String:C10(This:C1470.config.signAsBundle))
	End if 
	
	var $baseFolder : 4D:C1709.Folder
	$baseFolder:=This:C1470._baseFolder()
	
	If (Not:C34(Is macOS:C1572))
		Storage:C1525.github.warning("Signature ignored on this OS")
		return New object:C1471("success"; True:C214)
	End if 
	
	// Check if keychain passwords are set and unlock keychains
	var $env : Object
	$env:=This:C1470._getEnv()
	
	var $keychainResult : Object
	
	// Support for login keychain
	If ($env["LOGIN_KEYCHAIN_PASSWORD"]#Null:C1517)
		$keychainResult:=This:C1470._unlockKeychain("login"; Folder:C1567(fk home folder:K87:24).path+"Library/Keychains/login.keychain-db"; String:C10($env["LOGIN_KEYCHAIN_PASSWORD"]))
		If (Not:C34($keychainResult.success))
			return $keychainResult
		End if 
	End if 
	
	// Support for system keychain
	If ($env["SYSTEM_KEYCHAIN_PASSWORD"]#Null:C1517)
		$keychainResult:=This:C1470._unlockKeychain("system"; "/Library/Keychains/System.keychain"; String:C10($env["SYSTEM_KEYCHAIN_PASSWORD"]))
		If (Not:C34($keychainResult.success))
			return $keychainResult
		End if 
	End if 
	
	// Support for custom keychain path
	If (($env["KEYCHAIN_PATH"]#Null:C1517) && ($env["KEYCHAIN_PASSWORD"]#Null:C1517))
		var $customKeychainPath : Text
		$customKeychainPath:=String:C10($env["KEYCHAIN_PATH"])
		If (Length:C16($customKeychainPath)>0)
			$keychainResult:=This:C1470._unlockKeychain("custom ("+$customKeychainPath+")"; $customKeychainPath; String:C10($env["KEYCHAIN_PASSWORD"]))
			If (Not:C34($keychainResult.success))
				return $keychainResult
			End if 
		End if 
	End if 
	
	// Debug: Show keychain search list and available certificates
	If ($env["KEYCHAIN_DEBUG"]#Null:C1517)
		var $debugWorker : 4D:C1709.SystemWorker
		Storage:C1525.github.debug("=== Keychain Debug Information ===")
		
		// Show keychain search list
		$debugWorker:=4D:C1709.SystemWorker.new("security list-keychains").wait()
		Storage:C1525.github.debug("Keychain search list: "+$debugWorker.response)
		
		// Show available signing certificates
		$debugWorker:=4D:C1709.SystemWorker.new("security find-identity -v -p codesigning").wait()
		Storage:C1525.github.debug("Available signing certificates: "+$debugWorker.response)
		Storage:C1525.github.debug("=== End Debug Information ===")
	End if 
	
	var $signScriptFile : 4D:C1709.File
	
	If (This:C1470.config.signAsBundle)
		// Use app_sign_pack_notarize.sh from tool4D.app
		$signScriptFile:=Folder:C1567(Application file:C491; fk platform path:K87:2).file("Contents/Resources/app_sign_pack_notarize.sh")
		If (Not:C34($signScriptFile.exists))
			Storage:C1525.github.error("No app_sign_pack_notarize.sh script found in tool4d.app")
			return New object:C1471("success"; False:C215; "errors"; New collection:C1472("No app_sign_pack_notarize.sh script"))
		End if 
	Else 
		// Use traditional SignApp.sh
		$signScriptFile:=Folder:C1567(Application file:C491; fk platform path:K87:2).file("Contents/Resources/SignApp.sh")
		If (Not:C34($signScriptFile.exists))
			Storage:C1525.github.error("No SignApp.sh script")
			return New object:C1471("success"; False:C215; "errors"; New collection:C1472("No SignApp.sh script"))
		End if 
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
	
	If (This:C1470.config.signAsBundle)
		// app_sign_pack_notarize.sh sign <path> <entitlements_file> <certificate>
		$cmdPrefix:="\""+$signScriptFile.path+"\" sign "
		$cmdSuffix:=" \""+$entitlementsFile.path+"\" \""+$certificateName+"\""
	Else 
		// SignApp.sh <certificate> <path> <entitlements>
		$cmdPrefix:="\""+$signScriptFile.path+"\" \""+$certificateName+"\" "
		$cmdSuffix:=" \""+$entitlementsFile.path+"\""
	End if 
	
	// Sign base
	
	var $status : Object
	$status:=New object:C1471("success"; True:C214)
	
	// Skip individual file signing when using bundle signing
	If ((This:C1470.config.signFiles#Null:C1517) && (Value type:C1509(This:C1470.config.signFiles)=Is collection:K8:32) && Not:C34(This:C1470.config.signAsBundle))
		
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
	
	// When signing as bundle, ensure we sign the .4dbase directory itself
	var $pathToSign : Text
	If (This:C1470.config.signAsBundle)
		// Sign the .4dbase directory (bundle), not its contents
		$pathToSign:=$baseFolder.parent.path
		Storage:C1525.github.notice("Sign bundle: "+$pathToSign)
		
		This:C1470._cleanDatabase($baseFolder)
		
	Else 
		// Traditional signing targets the base folder path
		$pathToSign:=$baseFolder.path
		Storage:C1525.github.notice("Sign "+$pathToSign)
	End if 
	
	$cmd:=$cmdPrefix+"\""+$pathToSign+"\""+$cmdSuffix
	
	Storage:C1525.github.debug($cmd)
	var $worker : 4D:C1709.SystemWorker
	$worker:=4D:C1709.SystemWorker.new($cmd).wait()
	
	If (($worker.response#Null:C1517) && (Length:C16($worker.response)>0))
		Storage:C1525.github.info($worker.response)
	End if 
	If (($worker.responseError#Null:C1517) && (Length:C16($worker.responseError)>0))
		Storage:C1525.github.warning($worker.responseError)  // we do not know if warning or error so warning
	End if 
	
	$statusFile:=New object:C1471("success"; $worker.exitCode=0; "errors"; $worker.errors; "exitCode"; $worker.exitCode)
	
	If (Not:C34($statusFile.success))
		
		Storage:C1525.github.error("Failed to sign")  // error will set exit status code
		
	End if 
	
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
	Storage:C1525.github.debug("📚 Starting archive process")
	Storage:C1525.github.debug("Output use contents: "+String:C10(This:C1470.config.outputUseContents))
	
	var $baseFolder : 4D:C1709.Folder
	$baseFolder:=This:C1470._baseFolder()
	
	This:C1470._cleanDatabase($baseFolder)
	var $status : Object
	
	Storage:C1525.github.debug("Action build added, because pack action defined")
	
	If (Bool:C1537(This:C1470.config.outputUseContents))
		$baseFolder:=$baseFolder.parent
	End if 
	
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
	If (Bool:C1537(This:C1470._hasClean))
		return 
	End if 
	This:C1470._hasClean:=True:C214
	
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
	
	Storage:C1525.github.debug("🚀 Starting action execution with config: "+JSON Stringify:C1217(This:C1470.config; *))
	Storage:C1525.github.debug("Actions to execute: "+This:C1470.config.actions.join(" → "))
	
	Case of 
		: (Length:C16(String:C10(This:C1470.config.path))=0)
			
			Storage:C1525.github.error("❌ Path validation failed - no project file path")
			$status.errors:=New collection:C1472("no correct project file path provided")
			$status.success:=False:C215
			
		: (FileSafe(This:C1470.config.path)=Null:C1517)  // just because it failed with mixed / and \ TODO: clean path
			
			Storage:C1525.github.error("❌ File parsing failed for: "+This:C1470.config.path)
			$status.errors:=New collection:C1472("project file "+This:C1470.config.path+" cannot be parsed")
			$status.success:=False:C215
			
		: (Not:C34(FileSafe(This:C1470.config.path).exists))
			
			Storage:C1525.github.error("❌ File existence check failed for: "+This:C1470.config.path)
			$status.errors:=New collection:C1472("project file "+This:C1470.config.path+" do not exists")
			$status.success:=False:C215
			
		Else 
			
			Storage:C1525.github.debug("path="+String:C10(This:C1470.config.path))
			
			Storage:C1525.github.debug("...will execute actions: "+This:C1470.config.actions.join(","))
			
			This:C1470.config.actions:=This:C1470._checkActions(This:C1470.config.actions)
			
			var $action : Text
			For each ($action; This:C1470.config.actions) Until (Not:C34($status.success))
				If ((OB Instance of:C1731(This:C1470[$action]; 4D:C1709.Function)) && (Position:C15("_"; $action)#1) && ($action#"run"))
					Storage:C1525.github.notice("action "+$action)
					Storage:C1525.github.debug("⚡ Executing action: "+$action)
					$status[$action]:=This:C1470[$action].call(This:C1470)
					
					If (Storage:C1525.github.isDebug)
						Storage:C1525.github.debug("✅ Action "+$action+" completed with result: "+This:C1470._debugResult($status[$action]))
					End if 
					
					$status.success:=$status.success & Bool:C1537($status[$action].success)
					If (Not:C34($status.success))
						Storage:C1525.github.debug("❌ Action "+$action+" failed, stopping execution chain")
					End if 
				Else 
					Storage:C1525.github.error("❌ Unknown action attempted: "+$action)
					$status.success:=False:C215
				End if 
			End for each 
			
	End case 
	
	If (Storage:C1525.github.isDebug)
		Storage:C1525.github.debug("🏁 Action execution completed. Final status: "+This:C1470._debugResult($status))
	End if 
	
	return $status
	
Function _filterWarnings($object : Object; $depth : Integer)
	If (($object=Null:C1517) || ($depth<=0))
		return 
	End if 
	
	var $key : Text
	For each ($key; $object)
		Case of 
			: ($key="errors") && (Value type:C1509($object[$key])=Is collection:K8:32)
				// Filter out items where isError=false
				$object[$key]:=$object[$key].query("isError = :1"; True:C214)
				
				// Recursively filter nested objects in errors
				var $error : Object
				For each ($error; $object[$key])
					This:C1470._filterWarnings($error; $depth-1)
				End for each 
				
			: (Value type:C1509($object[$key])=Is object:K8:27)
				// Recursively process nested objects
				This:C1470._filterWarnings($object[$key]; $depth-1)
				
			: (Value type:C1509($object[$key])=Is collection:K8:32)
				// Process items in collections
				var $item : Variant
				For each ($item; $object[$key])
					If (Value type:C1509($item)=Is object:K8:27)
						This:C1470._filterWarnings($item; $depth-1)
					End if 
				End for each 
				
				// Else Keep all other properties (text, boolean, integer, etc.) as-is
				
		End case 
	End for each 
	
Function _debugResult($object : Object) : Text
	If (This:C1470.config.ignoreWarnings)
		var $cleaned : Object
		$cleaned:=OB Copy:C1225($object)
		
		// Remove isError:false items from errors collections recursively
		This:C1470._filterWarnings($cleaned; 3)
		
		return JSON Stringify:C1217($cleaned)
		
	End if 
	
	return JSON Stringify:C1217($object)
	
Function _checkActions($actions : Collection) : Collection
	
	var $releaseActions : Collection
	$releaseActions:=New collection:C1472("clean"; "build"; "pack"; "sign"; "archive")
	If ($actions.includes("release"))
		return $releaseActions
	End if 
	
	// else sort and filter
	var $sortedAction : Collection
	$sortedAction:=New collection:C1472()
	
	var $action : Text
	For each ($action; $releaseActions)
		
		If ($actions.includes($action))
			$sortedAction.push($action)
		End if 
		
	End for each 
	
	return $sortedAction
	
Function _Get4DPath() : Text
	Case of 
		: (Is macOS:C1572)
			return Folder:C1567(Application file:C491; fk platform path:K87:2).folder("Contents/MacOS").files().first().path
		Else 
			// TODO: to check on other OS
			return Application file:C491
	End case 
	
Function _executeHook($label : Text)
	
	var $command : Text
	$command:=String:C10(This:C1470.config[$label])
	
	If (Length:C16($command)=0)
		return 
	End if 
	
	Storage:C1525.github.info("Executing command: "+$label)
	Storage:C1525.github.debug($command)
	
	var $worker : 4D:C1709.SystemWorker
	var $options : Object
	$options:=New object:C1471()
	
	// Set working directory if available
	If (This:C1470.config.workingDirectory#Null:C1517)
		$options.currentDirectory:=This:C1470.config.workingDirectory
	End if 
	
	// Add environment variables
	$options.variables:=This:C1470._getEnv()
	$options.variables.BUILD_OUTPUT_DIR:=This:C1470.config.outputDirectory#Null:C1517 ? String:C10(This:C1470.config.outputDirectory.path) : ""
	$options.variables.BUILD_PROJECT_PATH:=This:C1470.config.file#Null:C1517 ? String:C10(This:C1470.config.file.path) : ""
	$options.variables.BUILD_PROJECT_NAME:=This:C1470.config.file#Null:C1517 ? This:C1470.config.file.name : ""
	$options.variables.BUILD_STEP:=String:C10($label)
	
	$options.variables.FOURD_PATH:=This:C1470._Get4DPath()
	$options.variables.TOOL4D_PATH:=$options.variables.FOURD_PATH  // even if not tool we pass, must work
	
	// Execute the command
	$worker:=4D:C1709.SystemWorker.new($command; $options)
	
	// Wait for completion and get results
	If ($worker=Null:C1517)
		Storage:C1525.github.error("❌ Command cannot be launched.")
		return 
	End if 
	
	$worker.wait()
	
	// Report results
	If ($worker.terminated)
		If ($worker.exitCode=0)
			Storage:C1525.github.info("✅ Command executed successfully (exitCode: 0)")
		Else 
			Storage:C1525.github.error("❌ Command failed with exit code: "+String:C10($worker.exitCode))
		End if 
		If (Length:C16($worker.response)>0)
			Storage:C1525.github.info("Command output: "+$worker.response)
		End if 
		If (Length:C16($worker.responseError)>0)
			Storage:C1525.github.error("Command error: "+$worker.responseError)
		End if 
	Else 
		Storage:C1525.github.error("❌ Command did not complete")
	End if 
	