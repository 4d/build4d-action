//%attributes = {}
#DECLARE($from : Text)
// to replace exit process status we create a file

If (Not:C34(Bool:C1537(Storage:C1525.exit.failure)))
	Use (Storage:C1525.exit)
		Storage:C1525.exit.failure:=True:C214
	End use 
	
	var $text : Text
	$text:=Method called on error:C704
	ON ERR CALL:C155("onFlagError")
	File:C1566(Storage:C1525.exit.errorFlag).setText($from)
	ON ERR CALL:C155($text)
	
End if 
