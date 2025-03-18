// property errorFlag : Text
// property failure : Boolean
// property isDev : Boolean

Class constructor($github : Object)
	This:C1470.errorFlag:=$github.temporaryFolder().file("error_flag").path
	This:C1470.failure:=False:C215
	This:C1470.isDev:=True:C214
	
Function setErrorStatus($from : Text)
	// to replace exit process status we create a file
	
	If (Not:C34(Bool:C1537(This:C1470.failure)))
		Use (This:C1470)
			This:C1470.failure:=True:C214
		End use 
		
		var $text : Text
		$text:=Method called on error:C704
		ON ERR CALL:C155("onFlagError")
		File:C1566(Replace string:C233(This:C1470.errorFlag; "\\"; "/")).setText($from)
		ON ERR CALL:C155($text)
		
	End if 
	