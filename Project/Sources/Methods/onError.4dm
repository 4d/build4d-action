//%attributes = {}
ARRAY INTEGER:C220($codesArray; 0)
ARRAY TEXT:C222($intCompArray; 0)
ARRAY TEXT:C222($textArray; 0)
GET LAST ERROR STACK:C1015($codesArray; $intCompArray; $textArray)

var $caller : Object
$caller:=Get call chain:C1662[1]  // 0 is current method

var $metadata : Object
$metadata:=New object:C1471
Case of 
	: ($caller.type="projectMethod")
		$metadata.file:=Folder:C1567(Folder:C1567(fk database folder:K87:14).platformPath; fk platform path:K87:2).file("Project/Sources/Method/"+$caller.name+".4dm").path
	: ($caller.type="databaseMethod")
		$caller.name:=Replace string:C233($caller.name; " "; "")
		$caller.name:=Lowercase:C14($caller.name[[1]])+Substring:C12($caller.name; 2)
		$metadata.file:=Folder:C1567(Folder:C1567(fk database folder:K87:14).platformPath; fk platform path:K87:2).file("Project/Sources/DatabaseMethods/"+$caller.name+".4dm").path
	: ($caller.type="classFunction")
		$metadata.file:=Folder:C1567(Folder:C1567(fk database folder:K87:14).platformPath; fk platform path:K87:2).file("Project/Sources/Classes/"+Substring:C12($caller.name; 1; Position:C15("."; $caller.name)-1)+".4dm").path
	: ($caller.type="formObjectMethod")
		If (Position:C15("."; $caller.name)>0)
			$metadata.file:=Folder:C1567(Folder:C1567(fk database folder:K87:14).platformPath; fk platform path:K87:2).file("Project/Sources/Forms/"+Replace string:C233($caller.name; "."; "ObjectMethods")+".4dm").path
		Else 
			$metadata.file:=Folder:C1567(Folder:C1567(fk database folder:K87:14).platformPath; fk platform path:K87:2).file("Project/Sources/Forms/"+$caller.name+"/method.4dm").path
		End if 
	Else 
		Storage:C1525.github.debug("Not managed type for caller file log error "+String:C10($caller.type))
End case 

$metadata.line:=String:C10($caller.line)  // is it line in file or line in code???

Storage:C1525.github.debug(JSON Stringify:C1217($metadata))

var $i : Integer
For ($i; 1; Size of array:C274($textArray); 1)
	Storage:C1525.github.error($textArray{$i}; $metadata)
End for 

Storage:C1525.exit.setErrorStatus("onError")

If (isDev)
	TRACE:C157
Else 
	QUIT 4D:C291
End if 