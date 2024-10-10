#!/bin/bash

nameCertificat=$1
PathApp=$2
Entitlements=$3
keyChain=$4

function SignFile ()
{
    local CertifName="$1"
    local Entitlements="$2"
    local file="$3"
    local keyChain="$4"
    local force="$5"

    if [ ! -L "$file" ]
        then

        if [ ! -z "$keyChain" ]
        then
            keyChain=" --keychain \"$keyChain\" " 
        fi
        if [ "$force" = true ]
            then
            codesign -f --sign "$CertifName" $keyChain --verbose --timestamp --options runtime --entitlements "$Entitlements" "$file" 2>&1
            let FlagError=$?
        else
            v=$(eval "codesign --sign '$CertifName' $keyChain --verbose --timestamp --options runtime --entitlements '$Entitlements' '$file' 2>&1")
            let FlagError=$?
            output=$v
            if [ "$FlagError" -eq "1" ]
			then
				local v=$(codesign -dvvv --verbose "$file" 2>&1)
				if [[ "$v" == *"Signature=adhoc"* ]]
				then
					if [[ "$1" == "-" ]]
					then
						let FlagError=0
					else
						v=$(eval "codesign -f --sign '$CertifName' $keyChain --verbose --timestamp --options runtime --entitlements '$Entitlements' '$file' 2>&1")
						let FlagError=$?

                        output=$v
                    fi
                elif [[ "$v" == *"Authority="* ]] #Check if already signed
                then
                    let FlagError=0
                fi
            fi
            echo $output 2>&1
        fi
    fi
    return $FlagError
}

SignFile "$nameCertificat" "$Entitlements" "$PathApp" "$keyChain" false

boolError=$?
exit $boolError