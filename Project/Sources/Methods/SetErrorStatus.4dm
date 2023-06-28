//%attributes = {}

// to replace exit process status we create a file
var $text : Text
$text:=Method called on error:C704

ON ERR CALL:C155("")
If (Not:C34(Bool:C1537(Storage:C1525.exit.failure)))
	Use (Storage:C1525.exit)
		Storage:C1525.exit.failure:=True:C214
	End use 
	If (File:C1566(Storage:C1525.exit.errorFlag).isWritable)  // Issue if readonly paths
		File:C1566(Storage:C1525.exit.errorFlag).setText("")
	Else 
		Storage:C1525.github.warning("Cannot write to error flag file")
	End if 
	
End if 

ON ERR CALL:C155($text)