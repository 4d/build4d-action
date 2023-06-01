
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
Class constructor($error : Object)
	// copy
	var $key : Text
	For each ($key; $error)
		This:C1470[$key]:=$error[$key]
	End for each 
	
Function printGithub($config : Object)
	var $cmd : Text
	$cmd:=Choose:C955(Bool:C1537(This:C1470.isError); "error"; "warning")
	
	var $lineContent : Text
	$lineContent:=Split string:C1554(This:C1470.code.file.getText("UTF-8"; Document with LF:K24:22); "\n")[This:C1470.lineInFile-1]
	
	var $relativePath : Text
	$relativePath:=Replace string:C233(File:C1566(This:C1470.code.file.platformPath; fk platform path:K87:2).path; $config.workingDirectory; "")
	
	// github action cmd
	print("::"+$cmd+" file="+String:C10($relativePath)+",line="+String:C10(This:C1470.lineInFile)+"::"+String:C10(This:C1470.message))
	// simple print too with code line
	print(""+$cmd+" file="+String:C10($relativePath)+", line="+String:C10(This:C1470.lineInFile)+": "+$lineContent)
	
	