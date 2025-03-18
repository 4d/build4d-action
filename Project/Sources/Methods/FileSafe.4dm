//%attributes = {}
#DECLARE($path : Text) : 4D:C1709.File
var $methodOnError : Text
$methodOnError:=Method called on error:C704()
var $f : 4D:C1709.File
ON ERR CALL:C155("noError")
$f:=File:C1566($path)
ON ERR CALL:C155($methodOnError)

return $f