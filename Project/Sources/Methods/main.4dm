//%attributes = {}

_initSingleton

ON ERR CALL:C155("onError")  // ignore all, do not want to block CI

var $r : Real
var $startupParam : Text
$r:=Get database parameter:C643(User param value:K37:94; $startupParam)

If (Length:C16($startupParam)=0)
	If (Structure file:C489(*)=Structure file:C489())  // dev
		$startupParam:="{}"
	Else 
		Storage:C1525.github.error("No parameters passed to database")
		return 
	End if 
End if 

Storage:C1525.github.info("...parsing parameters")

var $config : Object
$config:=JSON Parse:C1218($startupParam)
If (Length:C16(String:C10($config.errorFlag))>0)
	Use (Storage:C1525.exit)
		Storage:C1525.exit.errorFlag:=String:C10($config.errorFlag)
		Storage:C1525.github.debug("error flag defined to "+String:C10($config.errorFlag))
	End use 
End if 

var $actions : cs:C1710.actions
$actions:=cs:C1710.actions.new($config)

$actions.run()

Storage:C1525.github.debug("it's over")
