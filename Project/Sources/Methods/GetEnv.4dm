//%attributes = {"invisible":true}
#DECLARE() : Object

var $in; $out; $err : Text

If (Is Windows:C1573)
	SET ENVIRONMENT VARIABLE:C812("_4D_OPTION_HIDE_CONSOLE"; "true")
	LAUNCH EXTERNAL PROCESS:C811("cmd /C SET"; $in; $out; $err)  // TODO test
Else 
	LAUNCH EXTERNAL PROCESS:C811("/usr/bin/env"; $in; $out; $err)
End if 

var $result : Object
$result:=New object:C1471()
var $pos : Integer
var $line : Text
For each ($line; Split string:C1554($out; ((Is Windows:C1573) ? Char:C90(Carriage return:K15:38) : "")+Char:C90(Line feed:K15:40); sk ignore empty strings:K86:1))
	$pos:=Position:C15("="; $line)
	If ($pos>0)
		$result[Substring:C12($line; 1; $pos-1)]:=Substring:C12($line; $pos+1)
	Else 
		$result[$line]:=""
	End if 
End for each 

return $result