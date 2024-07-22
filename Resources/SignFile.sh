#!/bin/bash

sourceFile=$1
nameCertificat=$2
PathApp=$3
Entitlements=$4

function finish {
  SignFile "${nameCertificat}" "${Entitlements}" "${PathApp}" false
}
trap finish EXIT

source "$sourceFile" || true > /dev/null 2>&1
