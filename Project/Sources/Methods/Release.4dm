//%attributes = {}
#DECLARE($config : Object)->$status : Object

var $databaseFolder : 4D:C1709.Folder
$databaseFolder:=$config.file.parent.parent
var $databaseName : Text
$databaseName:=$config.file.name
print("...will archive "+$databaseName)

// archive and move it
var $buildDir : 4D:C1709.File
$buildDir:=Folder:C1567(Temporary folder:C486; fk platform path:K87:2).folder(Generate UUID:C1066)
$buildDir.create()

print("🗃 4dz creation")
// copy all base to destination
var $destinationBase : 4D:C1709.File
$destinationBase:=$databaseFolder.copyTo($buildDir; $databaseName+".4dbase"; fk overwrite:K87:5)
// remove all sources (could be opt if want to distribute with sources, add an option?)
cleanProject($destinationBase)

// zip into 4dz compilation files
$status:=ZIP Create archive:C1640($destinationBase.folder("Project"); $destinationBase.file($databaseName+".4DZ"))
// finally clean all
$destinationBase.folder("Project").delete(Delete with contents:K24:24)
// XXX could clean also logs, pref etc.. but must not be in vcs...
If (Not:C34($status.success))
	print("error when creating 4z:"+String:C10($status.statusText))
End if 

If ($status.success)
	// the 4d base
	print("📦 final archive creation")
	var $artefact : 4D:C1709.File
	$artefact:=$buildDir.file($databaseName+".zip")
	$status:=ZIP Create archive:C1640($destinationBase; $artefact)
	If (Not:C34($status.success))
		print("error when creating archive:"+String:C10($status.statusText))
	End if 
End if 

If ($status.success)
	// Send to release
	print("🚀 send archive to release")
	var $github : Object
	$github:=cs:C1710.github.new()
	$status:=$github.postArtefact($artefact)
	If (Not:C34($status.success))
		print("error when pusing artifact to release:"+String:C10($status.statusText))
	End if 
	
End if 

print("🧹 cleaning release working directory")
$buildDir.delete(Delete with contents:K24:24)