//%attributes = {}
_initSingleton

var $config : Object
var $status : Object
var $actions : cs:C1710.actions

// MARK:- test on self without option
$config:=New object:C1471
$actions:=cs:C1710.actions.new($config)
$status:=$actions.run()
ASSERT:C1129($status.success; JSON Stringify:C1217($status))


// MARK:- test on self without option
$config:=New object:C1471("options"; New object:C1471("targets"; "all"))
$actions:=cs:C1710.actions.new($config)
$status:=$actions.run()
If (Is Windows:C1573)
	// must failed on window with target all (no clang etc..?)
	ASSERT:C1129(Not:C34($status.success); JSON Stringify:C1217($status))
Else 
	ASSERT:C1129($status.success; JSON Stringify:C1217($status))
End if 