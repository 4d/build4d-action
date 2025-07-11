#!/bin/bash

if [ -f "../tool4d-action/download.sh" ]; then

    source ../tool4d-action/download.sh
    echo $tool4d_bin

else
    # maybe be check std path or clone the other repo
    echo "clone 4d/tool4d-action into parent folder"
    exit 1
fi

options=""
export WORKINK_DIRECTORY=$(pwd)
export ERROR_FLAG=$WORKINK_DIRECTORY/error_flag
projectToCompile="$WORKINK_DIRECTORY/../tool4d-action-test/Project/tool4d-action-test.4DProject"

[ -f "$ERROR_FLAG" ] && rm "$ERROR_FLAG"

project="Project/actions.4DProject"
export RUNNER_DEBUG=1

../tool4d-action/run.sh "$project" "main" "$ERROR_FLAG" "$tool4d_bin" "{\"path\": \"$projectToCompile\", \"workingDirectory\": \"$WORKINK_DIRECTORY\", \"options\": \"$options\" , \"debug\": 1, \"errorFlag\": \"$ERROR_FLAG\" }" 
status=$?

[ -f "$ERROR_FLAG" ] && rm "$ERROR_FLAG"

if [[ "$status" -eq 0 ]]; then
    echo "✅ test ok"
else
    >&2 echo "❌ test ko $status"
fi