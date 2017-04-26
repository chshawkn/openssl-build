#!/usr/bin/env bash

SOURCE="$0"
while [ -h "$SOURCE" ]; do
    DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
    SOURCE="$(readlink "$SOURCE")"
    [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE"
done
export script_path="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
echo "script_path: ${script_path}"
