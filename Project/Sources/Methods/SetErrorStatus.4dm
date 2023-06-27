//%attributes = {}

// to replace exit process status we create a file
var $text : Text
$text:=Method called on error:C704

Folder:C1567(fk database folder:K87:14).file("error").setText("")  // FIXME: Issue if readonly path

ON ERR CALL:C155($text)