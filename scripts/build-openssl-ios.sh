#!/usr/bin/env bash

set -u

#https://www.openssl.org/source/openssl-1.1.0c.tar.gz
#: "${LIB_NAME:=openssl-1.0.2k}"
: "${LIB_NAME:=openssl-1.1.0c}"
#https://github.com/openssl/openssl/archive/OpenSSL_1_1_0c.tar.gz
#LIB_NAME="OpenSSL_1_1_0c"
ARCHIVE="${LIB_NAME}.tar.gz"
ARCHIVE_URL="https://www.openssl.org/source/${ARCHIVE}"
#ARCHIVE_URL="https://github.com/openssl/openssl/archive/${ARCHIVE}"
#[ -f "${LIB_NAME}.tar.gz" ] || wget ${ARCHIVE_URL};
[ -f "${ARCHIVE}" ] || aria2c --file-allocation=none -c -x 10 -s 10 -m 0 --console-log-level=notice --log-level=notice --summary-interval=0 -d "$(pwd)" -o "${ARCHIVE}" "${ARCHIVE_URL}"

source ./common.sh
# Setup architectures, library name and other vars
IOS_RUST_STYLE_ARCHS=("aarch64" "armv7s" "armv7" "i386" "x86_64")
IOS_ARCHS=("arm64" "armv7s" "armv7" "i386" "x86_64")
IOS_SDKS=("iphoneos" "iphoneos" "iphoneos" "iphonesimulator" "iphonesimulator")
IOS_PLATFORMS=("iPhoneOS" "iPhoneOS" "iPhoneOS" "iPhoneSimulator" "iPhoneSimulator")
IOS_SDK_VERSION=""10.3""
DEVELOPER_DIR="/Applications/Xcode.app/Contents/Developer"
UNIVERSAL_LIB_DIR="${script_path}/../target/${LIB_NAME}-ios-universal"
FILTER="${script_path}/filter"

#DEVELOPER_COMMAND_LINE_TOOLS=`xcode-select -print-path`
#if [ ! -f ${DEVELOPER_COMMAND_LINE_TOOLS}/usr/bin/xcrun ]; then
#    xcode-select --install
#fi

# Unarchive library, then configure and make for specified architectures
function  configure_make() {
    local ARCH=$1
    local ABI_OR_RUST_ARCH=$2;
    local SDK=$3
    local PLATFORM=$4

    if [ -d "${LIB_NAME}" ]; then rm -rf "${LIB_NAME}"; fi
    mkdir -p "${LIB_NAME}"
    tar xzf "${LIB_NAME}.tar.gz" --strip-components=1 -C "${LIB_NAME}"
    pushd .; cd "${LIB_NAME}";

    if [[ "${ARCH}" == "i386" || "${ARCH}" == "x86_64" ]]; then
        echo ""
    else
        sed -ie "s!static volatile sig_atomic_t intr_signal;!static volatile intr_signal;!" "crypto/ui/ui_openssl.c"
    fi

    export CROSS_TOP="${DEVELOPER_DIR}/Platforms/${PLATFORM}.platform/Developer"
    export CROSS_SDK="${PLATFORM}${IOS_SDK_VERSION}.sdk"
    export CC="${DEVELOPER_DIR}/usr/bin/gcc -arch ${ARCH}"

    local PREFIX_DIR="${script_path}/../target/${LIB_NAME}-ios-${ABI_OR_RUST_ARCH}"
    if [ -d "${PREFIX_DIR}" ]; then rm -fr "${PREFIX_DIR}"; fi
    mkdir -p "${PREFIX_DIR}"

    if [[ "${ARCH}" == "x86_64" ]]; then
        ./Configure darwin64-x86_64-cc --prefix="${PREFIX_DIR}" | ${FILTER}
    elif [[ "${ARCH}" == "i386" ]]; then
        ./Configure darwin-i386-cc --prefix="${PREFIX_DIR}" | ${FILTER}
    else
        ./Configure iphoneos-cross --prefix="${PREFIX_DIR}" | ${FILTER}
    fi
    if [ ! -d "${CROSS_TOP}/SDKs/${CROSS_SDK}" ]; then
        echo "error SDK ${CROSS_TOP}/SDKs/${CROSS_SDK} not found."
        exit 1
    fi
    export CFLAGS="-isysroot ${CROSS_TOP}/SDKs/${CROSS_SDK}"

    if make -j8 | ${FILTER}; then
        make install | ${FILTER}; popd;
        rm -fr "${LIB_NAME}"
    fi
}

# Combine libraries for different architectures into one
# Use .a files from the temp directory by providing relative paths
function create_universal_lib() {
    local LIB_SRC=$1;
    local LIB_DST=$2;

    LIB_PATHS=( "${IOS_RUST_STYLE_ARCHS[@]/#/${script_path}/../target/${LIB_NAME}-ios-}" )
    LIB_PATHS=( "${LIB_PATHS[@]/%//lib/${LIB_SRC}}" )
    lipo ${LIB_PATHS[@]} -create -output "${LIB_DST}"
}

for ((i=0; i < ${#IOS_ARCHS[@]}; i++))
do
    if [[ $# -eq 0 || "$1" == "${IOS_ARCHS[i]}" ]]; then
        configure_make "${IOS_ARCHS[i]}" "${IOS_RUST_STYLE_ARCHS[i]}" "${IOS_SDKS[i]}" "${IOS_PLATFORMS[i]}"
    fi
done

if [[ $# -eq 0 ]]; then
    rm -rf "${UNIVERSAL_LIB_DIR}"
    mkdir "${UNIVERSAL_LIB_DIR}";
    create_universal_lib "libcrypto.a" "${UNIVERSAL_LIB_DIR}/libcrypto.a"
    create_universal_lib "libssl.a" "${UNIVERSAL_LIB_DIR}/libssl.a"
fi
