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
		// {type:projectMethod,name:onServerStart,line:2,database:Compilator}
		$metadata.file:=Folder:C1567(Folder:C1567(fk database folder:K87:14).platformPath; fk platform path:K87:2).file("Project/Sources/Method/"+$caller.name+".4dm").path
	: ($caller.type="classFunction")
		$metadata.file:=Folder:C1567(Folder:C1567(fk database folder:K87:14).platformPath; fk platform path:K87:2).file("Project/Sources/Classes/"+Substring:C12($caller.name; 1; Position:C15("."; $caller.name)-1)+".4dm").path
	Else 
		// TODO: not yet implemented (like db method, form method)
End case 

$metadata.line:=String:C10($caller.line)  // is it line in file or line in code???

SetErrorStatus()

var $logger : cs:C1710.logger
$logger:=cs:C1710.logger.new()

var $i : Integer
For ($i; 1; Size of array:C274($textArray); 1)
	$logger.error($textArray{$i}; $metadata)
End for 
