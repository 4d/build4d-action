//%attributes = {"invisible":true}
#DECLARE($value : Variant) : Variant

Case of 
	: (Value type:C1509($value)=Is boolean:K8:9)
		return $value
	: (Value type:C1509($value)=Is text:K8:3)
		If (Length:C16($value)=0)
			return Null:C1517
		End if 
		return (($value="true") || ($value="yes") || ($value="1"))
	: (Value type:C1509($value)=Is real:K8:4)
		return $value=1
	: (Value type:C1509($value)=Is integer:K8:5)
		return $value=1
	: (Value type:C1509($value)=Is integer 64 bits:K8:25)
		return $value=1
	Else 
		return Null:C1517
End case 
