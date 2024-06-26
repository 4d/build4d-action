//%attributes = {}
_initSingleton

var $config : Object
var $status : Object
var $actions : cs:C1710.actions

var $doLast : Boolean
$doLast:=Shift down:C543  // shift to do only last test

// MARK:- test on self without option
$config:=New object:C1471
$actions:=cs:C1710.actions.new($config)
$status:=($doLast) ? New object:C1471("success"; True:C214) : $actions.run()
ASSERT:C1129($status.success; JSON Stringify:C1217($status))

// MARK:- test on self with failOnWarning (this base has two warning)
$config:=New object:C1471("failOnWarning"; True:C214)
$actions:=cs:C1710.actions.new($config)
$status:=$actions.run()
ASSERT:C1129(Not:C34($status.success); JSON Stringify:C1217($status))

// MARK:- test on self with compile target option to all
$config:=New object:C1471("options"; New object:C1471("targets"; "all"))
$actions:=cs:C1710.actions.new($config)
$status:=($doLast) ? New object:C1471("success"; True:C214) : $actions.run()
If (Is Windows:C1573)
	// must failed on window with target all (no clang etc..?)
	ASSERT:C1129(Not:C34($status.success); JSON Stringify:C1217($status))
Else 
	ASSERT:C1129($status.success; JSON Stringify:C1217($status))
End if 

// MARK:- test on self with output dir
$config:=New object:C1471("outputDirectory"; Folder:C1567(fk database folder:K87:14).folder("build").path)
$actions:=cs:C1710.actions.new($config)
$status:=($doLast) ? New object:C1471("success"; True:C214) : $actions.run()
ASSERT:C1129($status.success; JSON Stringify:C1217($status))

// MARK:- test on self with action pack
$config:=New object:C1471("actions"; "pack")
$actions:=cs:C1710.actions.new($config)
$status:=($doLast) ? New object:C1471("success"; True:C214) : $actions.run()
ASSERT:C1129($status.success; JSON Stringify:C1217($status))

// MARK:- test on self with action pack and sign
If (Is macOS:C1572)
	$config:=New object:C1471("actions"; "pack"; "signCertificate"; "Developer ID")
	$actions:=cs:C1710.actions.new($config)
	$status:=($doLast) ? New object:C1471("success"; True:C214) : $actions.run()
	ASSERT:C1129($status.success; JSON Stringify:C1217($status))
End if 

// MARK:- test on self with action pack and archive
If (Is macOS:C1572)
	$config:=New object:C1471("actions"; "pack,archive"; "signCertificate"; "Developer ID")
	$actions:=cs:C1710.actions.new($config)
	$status:=$actions.run()
	ASSERT:C1129($status.success; JSON Stringify:C1217($status))
End if 