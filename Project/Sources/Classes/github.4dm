// property isDebug : Boolean
// property isDev : Boolean

Class constructor
	This:C1470.isDebug:=False:C215
	This:C1470.isDev:=isDev
	
	// MARK:-  log
Function info($message : Text)
	LOG EVENT:C667(Into system standard outputs:K38:9; $message+"\n"; Information message:K38:1)
	If (This:C1470.isDev)
		LOG EVENT:C667(Into 4D debug message:K38:5; $message+"\n"; Information message:K38:1)
	End if 
	
Function notice($message : Text; $parameters : Object)
	This:C1470.cmd("notice"; $message+"\n"; Information message:K38:1; $parameters)
	
Function error($message : Text; $parameters : Object)
	This:C1470.cmd("error"; $message+"\n"; Error message:K38:3; $parameters)
	Storage:C1525.exit.setErrorStatus("errorLog")
	
Function warning($message : Text; $parameters : Object)
	This:C1470.cmd("warning"; $message+"\n"; Information message:K38:1/*Warning message, to test*/; $parameters)
	
Function debug($message : Text; $parameters : Object)
	If (This:C1470.isDebug)
		This:C1470.cmd("debug"; $message+"\n"; Information message:K38:1; $parameters)
	End if 
	
	// MARK:-  variable
	
Function exportVariable($name : Text; $val : Text)
	This:C1470.cmd("set-env"; $val; 0; New object:C1471("name"; $name))
	
Function setSecret($secret : Text)
	This:C1470.cmd("add-mask"; $secret)
	
	// MARK:- group
Function startGroup($name : Text)
	This:C1470.cmd("group"; $name)
	
Function endGroup()
	This:C1470.cmd("endgroup"; "")
	
Function group($name : Text; $formula : 4D:C1709.Function)
	This:C1470.startGroup($name)
	$formula.call()  // waiting promise will be cool...
	This:C1470.endGroup()
	
	// MARK:- command
	// https://docs.github.com/en/actions/using-workflows/workflow-commands-for-github-actions
Function cmd($cmd : Text; $message : Text; $level : Integer/*0 default = info*/; $parameters : Object)
	var $finalMessage : Text
	$finalMessage:="::"+$cmd
	If (($parameters#Null:C1517) && Not:C34(OB Is empty:C1297($parameters)))
		$finalMessage+=" "+OB Entries:C1720($parameters).map(Formula:C1597($1.value.key+"="+String:C10($1.value.value))).join(",")
	End if 
	$finalMessage+="::"+String:C10($message)+"\n"
	LOG EVENT:C667(Into system standard outputs:K38:9; $finalMessage; $level)
	
	// MARK:- process
	
Function temporaryFolder() : 4D:C1709.Folder
	var $tempPath : Text
	$tempPath:=String:C10(This:C1470._parseEnv()["RUNNER_TEMP"])  // maybe extract parse env
	If (Length:C16($tempPath)>0)
		return Is Windows:C1573 ? Folder:C1567($tempPath; fk platform path:K87:2) : Folder:C1567($tempPath)
	Else 
		return Folder:C1567(Temporary folder:C486; fk platform path:K87:2)
	End if 
	
Function _parseEnv()->$env : Object
/*If (This._envCache#Null)
return This._envCache
End if */
	
	$env:=New object:C1471
	var $pos : Integer
	var $line : Text
	var $in; $out; $err : Text
	
	If (Is Windows:C1573)
		SET ENVIRONMENT VARIABLE:C812("_4D_OPTION_HIDE_CONSOLE"; "true")
	End if 
	
	LAUNCH EXTERNAL PROCESS:C811((Is Windows:C1573) ? "cmd /C SET" : "/usr/bin/env"; $in; $out; $err)
	
	For each ($line; Split string:C1554($out; ((Is Windows:C1573) ? Char:C90(Carriage return:K15:38) : "")+Char:C90(Line feed:K15:40); sk ignore empty strings:K86:1))
		$pos:=Position:C15("="; $line)
		If ($pos>0)
			$env[Substring:C12($line; 1; $pos-1)]:=Substring:C12($line; $pos+1)
			If (Is Windows:C1573 && (Length:C16($line)>0) && ($line[[1]]="'") && ($line[[Length:C16($line)]]="'"))  //  if window, remove  leading and trailig quote '
				$env[Substring:C12($line; 1; $pos-1)]:=Substring:C12($line; $pos+2; Length:C16($line)-$pos-2)
			End if 
		Else 
			$env[$line]:=""
		End if 
	End for each 
	
	
	If ($env["GITHUB_EVENT_PATH"]#Null:C1517)
		var $eventFile : 4D:C1709.File
		$eventFile:=(Is Windows:C1573) ? File:C1566(String:C10($env["GITHUB_EVENT_PATH"]); fk platform path:K87:2) : File:C1566(String:C10($env["GITHUB_EVENT_PATH"]))
		$env.event:=JSON Parse:C1218($eventFile.getText())
	End if 
	
/*Use (This)
This._envCache:=OB Copy($env; ck shared)
End use */
	
	
	// MARK:- file
Function addEnv($key : Text; $value : Text)
	This:C1470._write("GITHUB_ENV"; $key+"="+$value)
	
Function addOutput($key : Text; $value : Text)
	This:C1470._write("GITHUB_OUTPUT"; $key+"="+$value)
	
Function addToPath($path : Text)
	This:C1470._write("GITHUB_PATH"; $path)
	
Function addToSummary($markdown : Text)
	This:C1470._write("GITHUB_STEP_SUMMARY"; $markdown)
	
Function setSummary($markdown : Text)
	This:C1470._write("GITHUB_STEP_SUMMARY"; $markdown; True:C214)
	
Function _write($key : Text; $value : Text; $replace : Boolean)
	var $env : Object
	$env:=This:C1470._parseEnv()
	
	var $filePath : Text
	var $file : 4D:C1709.File
	var $handle : 4D:C1709.FileHandle
	
	$filePath:=String:C10($env[$key])
	
	If (Length:C16($filePath)>0)
		$file:=(Is Windows:C1573) ? File:C1566($filePath; fk platform path:K87:2) : File:C1566($filePath)
		
		If (Bool:C1537($replace))
			$file.setText($value)
		Else 
			$handle:=$file.open("append")
			$handle.writeLine($value)
			// $handle.close()
		End if 
		
	Else 
		
		This:C1470.warning("env var "+$key+" not defined (as file path to write)")
		
	End if 
	
	
	// MARK:- artefact
	
Function isRelease() : Boolean
	var $env : Object
	$env:=This:C1470._parseEnv()
	return (String:C10($env["GITHUB_EVENT_NAME"])="release")
	
Function postArtefactToRelease($artefact : 4D:C1709.File)->$result : Object
	var $env : Object
	$env:=This:C1470._parseEnv()
	
	Case of 
		: (String:C10($env["GITHUB_EVENT_NAME"])#"release")
			$result:=New object:C1471("success"; False:C215; "statusText"; "Not corrected event type "+String:C10($env["GITHUB_EVENT_NAME"])+". expected release.")
		: (Length:C16(String:C10($env["GITHUB_TOKEN"]))=0)
			$result:=New object:C1471("success"; False:C215; "statusText"; "No token to upload release.")
		: (Length:C16(String:C10($env["GITHUB_REPOSITORY"]))=0)
			$result:=New object:C1471("success"; False:C215; "statusText"; "No GITHUB_REPOSITORY defined.")
		: ($env.event=Null:C1517)
			$result:=New object:C1471("success"; False:C215; "statusText"; "No github event data to extract release id.")
		: (Length:C16(String:C10($env.event.release.id))=0)
			$result:=New object:C1471("success"; False:C215; "statusText"; "No release id in event.")
		Else 
			
			var $uploadURL : Text
			$uploadURL:="https://uploads.github.com/repos/"+String:C10($env["GITHUB_REPOSITORY"])+"/releases/"+String:C10($env.event.release.id)+"/assets?name="+String:C10($artefact.fullName)
			This:C1470.debug("using url="+$uploadURL)
			
			ARRAY TEXT:C222($headerNames; 5)
			ARRAY TEXT:C222($headerValues; 5)
			$headerNames{1}:="Authorization"
			$headerValues{1}:="Bearer "+String:C10($env["GITHUB_TOKEN"])
			This:C1470.debug("token="+$env["GITHUB_TOKEN"])
			$headerNames{2}:="Content-Length"
			$headerValues{2}:=String:C10($artefact.size)
			$headerNames{3}:="Content-Type"
			$headerValues{3}:="application/octet-stream"
			$headerNames{4}:="Accept"
			$headerValues{4}:="application/vnd.github+json"
			$headerNames{5}:="X-GitHub-Api-Version"
			$headerValues{5}:="2022-11-28"
			
			var $response : Object
			var $httpStatus : Integer
			var $content : Blob
			$content:=$artefact.getContent()
			$httpStatus:=HTTP Request:C1158(HTTP POST method:K71:2; $uploadURL; $content; $response; $headerNames; $headerValues)
			
			$result:=New object:C1471("response"; $response)
			$result.success:=$httpStatus<300
			$result.httpStatus:=$httpStatus
			$result.statusText:=JSON Stringify:C1217($response)
			
	End case 