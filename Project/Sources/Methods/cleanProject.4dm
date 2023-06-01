//%attributes = {}
#DECLARE($base : 4D:C1709.Folder)

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
