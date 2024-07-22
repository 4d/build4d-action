#!/bin/bash

nameCertificat=$1
PathApp=$2
Entitlements=$3

function finish {
  SignFile "${nameCertificat}" "${Entitlements}" "${PathApp}" false
}
trap finish EXIT

source /Applications/4D/main/main/release/4D.app/Contents/Resources/SignApp.sh || true > /dev/null 2>&1
