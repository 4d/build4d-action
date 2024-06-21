//%attributes = {}

_initSingleton

ON ERR CALL:C155("onError")  // ignore all, do not want to block CI

var $r : Real
var $startupParam : Text
$r:=Get database parameter:C643(User param value:K37:94; $startupParam)

If (Length:C16($startupParam)=0)
	$startupParam:="{}"
Else 
	Use (Storage:C1525.exit)
		Storage:C1525.exit.isDev:=False:C215
	End use 
End if 

Storage:C1525.github.info("...parsing parameters")

var $config : Object
$config:=JSON Parse:C1218($startupParam)

var $actions : cs:C1710.actions
$actions:=cs:C1710.actions.new($config)

Storage:C1525.github.info("...running actions")

var $status : Object
$status:=$actions.run()

Storage:C1525.github.debug("it's over")
