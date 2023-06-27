//%attributes = {}

// to replace exit process status we create a file
var $text : Text
$text:=Method called on error:C704

ON ERR CALL:C155("")
If (Not:C34(Bool:C1537(Storage:C1525.exit.failure)))
	Use (Storage:C1525)
		Storage:C1525.exit:=New shared object:C1526("failure"; True:C214)
	End use 
	If (Folder:C1567(fk database folder:K87:14).file("error").isWritable)
		Folder:C1567(fk database folder:K87:14).file("error").setText("")  // FIXME: Issue if readonly path
	Else 
		Storage:C1525.github.warning("Cannot write to error flag file")
	End if 
	
End if 

ON ERR CALL:C155($text)