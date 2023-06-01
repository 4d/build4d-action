//%attributes = {}
var $name : Text
var $status : Object
var $config : Object

$config:=New object:C1471()
$config.options:=New object:C1471()
$config.workingDirectory:=Folder:C1567(Folder:C1567(fk database folder:K87:14).platformPath; fk platform path:K87:2).path

var $folderTest : 4D:C1709.Folder
$folderTest:=Folder:C1567(Folder:C1567(fk resources folder:K87:11).platformPath; fk platform path:K87:2).folder("test")

$name:="ok"
$config.file:=$folderTest.folder($name).folder("Project").file($name+".4DProject")
$status:=Compile project:C1760($config.file; $config.options)
ASSERT:C1129($status.success; "must success")

$name:="ko"
$config.file:=$folderTest.folder($name).folder("Project").file($name+".4DProject")
$status:=Compile project:C1760($config.file; $config.options)
ASSERT:C1129(Not:C34($status.success); "must failed")

If ($status.errors#Null:C1517)
	var $error : Object
	For each ($error; $status.errors)
		cs:C1710.compilationError.new($error).printGithub($config)
	End for each 
End if 

$name:="warning"
$config.file:=$folderTest.folder($name).folder("Project").file($name+".4DProject")
$status:=Compile project:C1760($config.file; $config.options)
ASSERT:C1129($status.success; "must success")

If ($status.errors#Null:C1517)
	var $error : Object
	For each ($error; $status.errors)
		cs:C1710.compilationError.new($error).printGithub($config)
	End for each 
End if 
