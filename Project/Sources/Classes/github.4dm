Class constructor
	This:C1470._parseEnv()
	
Function _parseEnv()
	var $in; $out; $err : Text
	LAUNCH EXTERNAL PROCESS:C811("/usr/bin/env"; $in; $out; $err)
	var $pos : Integer
	var $line : Text
	For each ($line; Split string:C1554($out; Char:C90(Line feed:K15:40); sk ignore empty strings:K86:1))
		$pos:=Position:C15("="; $line)
		If ($pos>0)
			This:C1470[Substring:C12($line; 1; $pos-1)]:=Substring:C12($line; $pos+1)
		Else 
			This:C1470[$line]:=""
		End if 
	End for each 
	
	If (This:C1470["GITHUB_EVENT_PATH"]#Null:C1517)
		var $eventFile : 4D:C1709.File
		$eventFile:=File:C1566(String:C10(This:C1470["GITHUB_EVENT_PATH"]))
		This:C1470.event:=JSON Parse:C1218($eventFile.getText())
	End if 
	
Function postArtefact($artefact : 4D:C1709.File)->$result : Object
	Case of 
		: (String:C10(This:C1470["GITHUB_EVENT_NAME"])#"release")
			$result:=New object:C1471("success"; False:C215; "statusText"; "Not corrected event type "+String:C10(This:C1470["GITHUB_EVENT_NAME"])+". expected release.")
		: (Length:C16(String:C10(This:C1470["GITHUB_TOKEN"]))=0)
			$result:=New object:C1471("success"; False:C215; "statusText"; "No token to upload release.")
		: (Length:C16(String:C10(This:C1470["GITHUB_REPOSITORY"]))=0)
			$result:=New object:C1471("success"; False:C215; "statusText"; "No GITHUB_REPOSITORY defined.")
		: (This:C1470.event=Null:C1517)
			$result:=New object:C1471("success"; False:C215; "statusText"; "No github event data to extract release id.")
		: (Length:C16(String:C10(This:C1470.event.release.id))=0)
			$result:=New object:C1471("success"; False:C215; "statusText"; "No release id in event.")
		Else 
			var $uploadURL : Text
			$uploadURL:="https://uploads.github.com/repos/"+String:C10(This:C1470["GITHUB_REPOSITORY"])+"/releases/"+String:C10(This:C1470.event.release.id)+"/assets?name="+String:C10($artefact.fullName)
			print("...using url "+$uploadURL)
			
			ARRAY TEXT:C222($headerNames; 3)
			ARRAY TEXT:C222($headerValues; 3)
			$headerNames{1}:="Authorization"
			$headerValues{1}:="token "+String:C10(This:C1470["GITHUB_TOKEN"])
			$headerNames{2}:="Content-Length"
			$headerValues{2}:=String:C10($artefact.size)
			$headerNames{3}:="Content-Type"
			$headerValues{3}:="application/json"
			
			var $response : Object
			var $httpStatus : Integer
			$httpStatus:=HTTP Request:C1158(HTTP POST method:K71:2; $uploadURL; $artefact.getContent(); $response; $headerNames; $headerValues)
			
			$result:=New object:C1471("response"; $response)
			$result.success:=$httpStatus<300
			$result.httpStatus:=$httpStatus
	End case 