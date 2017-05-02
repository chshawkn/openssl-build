#!/usr/bin/env bash

set -e

: "${LIB_NAME:=openssl-1.1.0e}"

echo "building ${LIB_NAME}"

source common.sh
#export script_path="${script_path}/scripts"

source ${script_path}/package.sh

# build-openssl-darwin.sh
if [ -z "${AND_ARCHS}" ] && [ -z "${IOS_ARCHS}" ]; then
    brew tap chshawkn/homebrew-brew-tap
    brew install chshawkn/brew-tap/openssl@1.1.0.e

    if [ -d ../target/${LIB_NAME}-darwin64-x86_64 ]; then rm -rf ../target/${LIB_NAME}-darwin64-x86_64; fi
    mkdir -p ../target/${LIB_NAME}-darwin64-x86_64
    cp -r /usr/local/Cellar/openssl@1.1.0.e/1.1.0e/* ../target/${LIB_NAME}-darwin64-x86_64/

    rm -f "../target/${LIB_NAME}-darwin64-x86_64.tar.gz"
    tar czf "../target/${LIB_NAME}-darwin64-x86_64.tar.gz" -C "../target" "${LIB_NAME}-darwin64-x86_64"
fi

if [[ ! -v AND_ARCHS ]]; then
    : "${AND_ARCHS:=android android-armeabi android-mips android-x86 android64 android64-aarch64}"
fi
if [[ ! -v IOS_ARCHS ]]; then
    : "${IOS_ARCHS:=arm64 armv7 armv7s i386 x86_64}"
fi
: "${IOS_SDK_VERSION:=10.3}"

#IOS_ARCHS_ARRAY=(${IOS_ARCHS})
#echo "IOS_ARCHS_ARRAY ${#IOS_ARCHS_ARRAY[@]} ${IOS_ARCHS_ARRAY[@]}"
#AND_ARCHS_ARRAY=(${AND_ARCHS})
#echo "AND_ARCHS_ARRAY ${#AND_ARCHS_ARRAY[@]} ${AND_ARCHS_ARRAY[@]}"
#
#source ${script_path}/build-openssl-ios.sh
#source ${script_path}/build-openssl-android.sh
#
#UNIVERSAL_LIB_DIR="${script_path}/../target/${LIB_NAME}-ios-universal"
#if [[ $# -eq 0 && ${#IOS_ARCHS_ARRAY[@]} -gt 1 ]]; then
#    rm -rf "${UNIVERSAL_LIB_DIR}"
#    mkdir "${UNIVERSAL_LIB_DIR}";
#    create_universal_lib "libcrypto.a" "${UNIVERSAL_LIB_DIR}/libcrypto.a"
#    create_universal_lib "libssl.a" "${UNIVERSAL_LIB_DIR}/libssl.a"
#fi

#(cd ../target; package "." "${LIB_NAME}"; ls -l .;)
