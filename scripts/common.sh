#!/usr/bin/env bash

SOURCE="$0"
while [ -h "$SOURCE" ]; do
    DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
    SOURCE="$(readlink "$SOURCE")"
    [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE"
done
export script_path="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
echo "script_path: ${script_path}"


function abi_or_rust_arch() {
    local arch="$1"

    if [[ "${arch}" == "arm64" || "${arch}" == "android64-aarch64" || "${arch}" == "arm64-v8a" ]]; then
        echo "aarch64"
    elif [[ "${arch}" == "armv7s" ]]; then
        echo "armv7s"
    elif [[ "${arch}" == "armv7" || "${arch}" == "android-armeabi" || "${arch}" == "armeabi-v7a" ]]; then
        echo "armv7"
    elif [[ "${arch}" == "i386" ]]; then
        echo "i386"
    elif [[ "${arch}" == "x86_64" || "${arch}" == "android64" ]]; then
        echo "x86_64"
    elif [[ "${arch}" == "android" || "${arch}" == "armeabi" ]]; then
        echo "arm"
    elif [[ "${arch}" == "android-x86" || "${arch}" == "x86" ]]; then
        echo "i686"
    elif [[ "${arch}" == "android-mips" || "${arch}" == "mips" ]]; then
        echo "mips"
    elif [[ "${arch}" == "android-mips64" || "${arch}" == "mips64" ]]; then
        echo "mips64"
    else
        echo "unknown"
    fi
}
