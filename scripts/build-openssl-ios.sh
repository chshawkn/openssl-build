#!/usr/bin/env bash

set -e
set -u

#https://www.openssl.org/source/openssl-1.1.0e.tar.gz
#: "${LIB_NAME:=openssl-1.0.2k}"
: "${LIB_NAME:=openssl-1.1.0e}"
#https://github.com/openssl/openssl/archive/OpenSSL_1_1_0c.tar.gz
#LIB_NAME="OpenSSL_1_1_0c"
ARCHIVE="${LIB_NAME}.tar.gz"
ARCHIVE_URL="https://www.openssl.org/source/${ARCHIVE}"
#ARCHIVE_URL="https://github.com/openssl/openssl/archive/${ARCHIVE}"
#[ -f "${LIB_NAME}.tar.gz" ] || wget ${ARCHIVE_URL};
[ -f "${ARCHIVE}" ] || aria2c --file-allocation=none -c -x 10 -s 10 -m 0 --console-log-level=notice --log-level=notice --summary-interval=0 -d "$(pwd)" -o "${ARCHIVE}" "${ARCHIVE_URL}"

source ./common.sh
if [[ ! -v IOS_ARCHS ]]; then
    : "${IOS_ARCHS:=arm64 armv7s armv7 i386 x86_64}"
fi
DEVELOPER_DIR="/Applications/Xcode.app/Contents/Developer"
FILTER="${SCRIPT_PATH}/filter"

#DEVELOPER_COMMAND_LINE_TOOLS=`xcode-select -print-path`
#if [ ! -f ${DEVELOPER_COMMAND_LINE_TOOLS}/usr/bin/xcrun ]; then
#    xcode-select --install
#fi

xcode_major=$(xcodebuild -version|egrep '^Xcode '|cut -d' ' -f2|cut -d. -f1)
if [ $xcode_major -ge 8 ]; then
  #export IOS_SIMULATOR_VERSION_MIN=${IOS_SIMULATOR_VERSION_MIN-"6.0.0"}
  export IOS_SIMULATOR_VERSION_MIN=${IOS_SIMULATOR_VERSION_MIN-"7.0.0"}
  #export IOS_VERSION_MIN=${IOS_VERSION_MIN-"6.0.0"}
  export IOS_VERSION_MIN=${IOS_VERSION_MIN-"7.0.0"}
else
  #export IOS_SIMULATOR_VERSION_MIN=${IOS_SIMULATOR_VERSION_MIN-"5.1.1"}
  export IOS_SIMULATOR_VERSION_MIN=${IOS_SIMULATOR_VERSION_MIN-"7.0.0"}
  #export IOS_VERSION_MIN=${IOS_VERSION_MIN-"5.1.1"}
  export IOS_VERSION_MIN=${IOS_VERSION_MIN-"7.0.0"}
fi

# Unarchive library, then configure and make for specified architectures
function  configure_make() {
    local ARCH=$1
    local SDK_VERSION=$2
    local ABI_OR_RUST_ARCH=$(abi_or_rust_arch "${ARCH}");
    local PLATFORM="iPhoneOS"

    if [ -d "${LIB_NAME}" ]; then rm -rf "${LIB_NAME}"; fi
    mkdir -p "${LIB_NAME}"
    tar xzf "${LIB_NAME}.tar.gz" --strip-components=1 -C "${LIB_NAME}"
    pushd .; cd "${LIB_NAME}";

    if [[ "${ARCH}" == "i386" || "${ARCH}" == "x86_64" ]]; then
        PLATFORM="iPhoneSimulator"
    else
        sed -ie "s!static volatile sig_atomic_t intr_signal;!static volatile intr_signal;!" "crypto/ui/ui_openssl.c"
    fi

    export CROSS_TOP="${DEVELOPER_DIR}/Platforms/${PLATFORM}.platform/Developer"
    export CROSS_SDK="${PLATFORM}${SDK_VERSION}.sdk"
    #export CC="${DEVELOPER_DIR}/usr/bin/gcc -arch ${ARCH}"
    export CC="$(xcrun --sdk iphoneos -f cc) -arch ${ARCH} -mios-version-min=${IOS_VERSION_MIN}"

    if [ ! -d "${CROSS_TOP}/SDKs/${CROSS_SDK}" ]; then
        echo "error SDK ${CROSS_TOP}/SDKs/${CROSS_SDK} not found."
        exit 1
    fi

    local PREFIX_DIR="${SCRIPT_PATH}/../target/${LIB_NAME}-${ABI_OR_RUST_ARCH}-apple-ios"
    if [ -d "${PREFIX_DIR}" ]; then rm -fr "${PREFIX_DIR}"; fi
    mkdir -p "${PREFIX_DIR}"

    if [[ "${ARCH}" == "arm64" ]]; then
        CFLAGS="-O2 -arch ${ARCH} -mios-version-min=${IOS_VERSION_MIN}"
        LDFLAGS="-arch ${ARCH} -mios-version-min=${IOS_VERSION_MIN}"
    elif [[ "${ARCH}" == "armv7" ]]; then
        CFLAGS="-O2 -mthumb -arch ${ARCH} -mios-version-min=${IOS_VERSION_MIN}"
        LDFLAGS="-mthumb -arch ${ARCH} -mios-version-min=${IOS_VERSION_MIN}"
    elif [[ "${ARCH}" == "armv7s" ]]; then
        CFLAGS="-O2 -mthumb -arch ${ARCH} -mios-version-min=${IOS_VERSION_MIN}"
        LDFLAGS="-mthumb -arch ${ARCH} -mios-version-min=${IOS_VERSION_MIN}"
    elif [[ "${ARCH}" == "i386" ]]; then
        export CC="$(xcrun --sdk iphonesimulator -f cc) -arch ${ARCH} -mios-simulator-version-min=${IOS_SIMULATOR_VERSION_MIN}"
        CFLAGS="-O2 -arch ${ARCH} -mios-simulator-version-min=${IOS_SIMULATOR_VERSION_MIN}"
        LDFLAGS="-arch ${ARCH} -mios-simulator-version-min=${IOS_SIMULATOR_VERSION_MIN}"
    elif [[ "${ARCH}" == "x86_64" ]]; then
        export CC="$(xcrun --sdk iphonesimulator -f cc) -arch ${ARCH} -mios-simulator-version-min=${IOS_SIMULATOR_VERSION_MIN}"
        CFLAGS="-O2 -arch ${ARCH} -mios-simulator-version-min=${IOS_SIMULATOR_VERSION_MIN}"
        LDFLAGS="-arch ${ARCH} -mios-simulator-version-min=${IOS_SIMULATOR_VERSION_MIN}"
    fi
    export CFLAGS="${CFLAGS} -isysroot ${CROSS_TOP}/SDKs/${CROSS_SDK} -flto"
    export LDFLAGS="${LDFLAGS} -isysroot ${CROSS_TOP}/SDKs/${CROSS_SDK} -flto"

    if [[ "${ARCH}" == "x86_64" ]]; then
        ./Configure darwin64-x86_64-cc no-comp --prefix="${PREFIX_DIR}" | ${FILTER}
    elif [[ "${ARCH}" == "i386" ]]; then
        ./Configure darwin-i386-cc no-comp --prefix="${PREFIX_DIR}" | ${FILTER}
    else
        ./Configure iphoneos-cross no-comp --prefix="${PREFIX_DIR}" | ${FILTER}
    fi

    if make -j16 | ${FILTER}; then
        echo "make done. $(pwd)"
        set +e
        make install | ${FILTER}
        set -e
        echo "make install done. $(pwd)"
        popd
        rm -rf "${LIB_NAME}"
    fi
}

IOS_ARCHS_ARRAY=(${IOS_ARCHS})
IOS_RUST_STYLE_ARCHS=()
for ((i=0; i < ${#IOS_ARCHS_ARRAY[@]}; i++))
do
    IOS_RUST_STYLE_ARCHS+=($(abi_or_rust_arch "${IOS_ARCHS_ARRAY[i]}"))
done

# Combine libraries for different architectures into one
# Use .a files from the temp directory by providing relative paths
function create_universal_lib() {
    local LIB_SRC=$1;
    local LIB_DST=$2;

    LIB_PATHS=( "${IOS_RUST_STYLE_ARCHS[@]/#/${SCRIPT_PATH}/../target/${LIB_NAME}-}" )
    LIB_PATHS=( "${LIB_PATHS[@]/%/-apple-ios}" )
    LIB_PATHS=( "${LIB_PATHS[@]/%//lib/${LIB_SRC}}" )
    echo "LIB_PATHS: ${LIB_PATHS[@]}"
    mkdir -p "${LIB_DST}/lib"
    lipo ${LIB_PATHS[@]} -create -output "${LIB_DST}/lib/${LIB_SRC}"
}

: "${IOS_SDK_VERSION:=10.3}"
for ((i=0; i < ${#IOS_ARCHS_ARRAY[@]}; i++))
do
    if [[ $# -eq 0 || "$1" == "${IOS_ARCHS_ARRAY[i]}" ]]; then
        configure_make "${IOS_ARCHS_ARRAY[i]}" "${IOS_SDK_VERSION}"
    fi
done
