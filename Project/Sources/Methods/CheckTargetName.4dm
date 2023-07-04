//%attributes = {}
#DECLARE($object : Object)

Case of 
	: (New collection:C1472("x86_64_generic"; "arm64_macOS_lib").includes($object.value))
		$object.result:=$object.value
	: (Not:C34(Value type:C1509($object.value)=Is text:K8:3))
		$object.result:=Null:C1517
	: ($object.value="current")
		$object.result:=(String:C10(Get system info:C1571().processor)="Apple@") ? "arm64_macOS_lib" : "x86_64_generic"
	: (($object.value="x86_64") || ($object.value="x86-64") || ($object.value="x64") || ($object.value="AMD64") || ($object.value="Intel 64"))
		$object.result:="x86_64_generic"
	: ($object.value="arm64")
		$object.result:="arm64_macOS_lib"
	Else 
		Storage:C1525.github.warning("Unknown target "+String:C10($object.value))
		$object.result:=Null:C1517
End case 