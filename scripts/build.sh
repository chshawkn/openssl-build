#!/usr/bin/env bash

: "${LIB_NAME:=openssl-1.1.0c}"

echo "building ${LIB_NAME}"

source common.sh
#export script_path="${script_path}/scripts"

source ${script_path}/package.sh

if [[ ! -v AND_ARCHS ]]; then
    : "${AND_ARCHS:=android android-armeabi android64-aarch64 android-x86 android64 android-mips android-mips64}"
fi
if [[ ! -v IOS_ARCHS ]]; then
    : "${IOS_ARCHS:=arm64 armv7s armv7 i386 x86_64}"
fi
: "${IOS_SDK_VERSION:=10.3}"

IOS_ARCHS_ARRAY=(${IOS_ARCHS})
echo "IOS_ARCHS_ARRAY ${#IOS_ARCHS_ARRAY[@]} ${IOS_ARCHS_ARRAY[@]}"
AND_ARCHS_ARRAY=(${AND_ARCHS})
echo "AND_ARCHS_ARRAY ${#AND_ARCHS_ARRAY[@]} ${AND_ARCHS_ARRAY[@]}"

source ${script_path}/build-openssl-ios.sh
source ${script_path}/build-openssl-android.sh

UNIVERSAL_LIB_DIR="${script_path}/../target/${LIB_NAME}-ios-universal"
if [[ $# -eq 0 && ${#IOS_ARCHS_ARRAY[@]} -gt 1 ]]; then
    rm -rf "${UNIVERSAL_LIB_DIR}"
    mkdir "${UNIVERSAL_LIB_DIR}";
    create_universal_lib "libcrypto.a" "${UNIVERSAL_LIB_DIR}/libcrypto.a"
    create_universal_lib "libssl.a" "${UNIVERSAL_LIB_DIR}/libssl.a"
fi

(cd target; package "." "${LIB_NAME}")
