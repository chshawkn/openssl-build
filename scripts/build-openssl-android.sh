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

source ./android.sh
LIB_DEST_DIR=${TOOLS_ROOT}/libs
[ -d ${LIB_DEST_DIR} ] && rm -rf ${LIB_DEST_DIR}
FILTER="${script_path}/filter"

# Unarchive library, then configure and make for specified architectures
function configure_make() {
    local ARCH=$1;
    local ABI_OR_RUST_ARCH=$2;

    if [ -d "${LIB_NAME}" ]; then rm -rf "${LIB_NAME}"; fi
    mkdir -p "${LIB_NAME}"
    tar xzf "${LIB_NAME}.tar.gz" --strip-components=1 -C "${LIB_NAME}"
    pushd "${LIB_NAME}"

    echo "android_configure $*"
    android_configure $*

    #support openssl-1.0.x
#    if [[ $LIB_NAME != "openssl-1.1.*" ]]; then
#        if [[ $ARCH == "android-armeabi" ]]; then
#            ARCH="android-armv7"
#        elif [[ $ARCH == "android64" ]]; then
#            ARCH="linux-x86_64 shared no-ssl2 no-ssl3 no-hw "
#        elif [[ "$ARCH" == "android64-aarch64" ]]; then
#            ARCH="android shared no-ssl2 no-ssl3 no-hw "
#        fi
#    fi

    local PREFIX_DIR="${LIB_DEST_DIR}/${ABI_OR_RUST_ARCH}"

    ./Configure $ARCH \
        --prefix=${PREFIX_DIR} \
        --with-zlib-include=$SYSROOT/usr/include \
        --with-zlib-lib=$SYSROOT/usr/lib \
        zlib \
        no-asm \
        no-shared \
        no-unit-test | ${FILTER}
    PATH=$TOOLCHAIN_PATH:$PATH

    if make -j4 | ${FILTER}; then
        echo "make done. $(pwd)"
        set +e
        make install | ${FILTER}
        set -e
        echo "make install done. $(pwd)"

        local OUTPUT_ROOT="${TOOLS_ROOT}/../target/${LIB_NAME}-android-${ABI_OR_RUST_ARCH}"
        [ -d ${OUTPUT_ROOT}/include ] || mkdir -p ${OUTPUT_ROOT}/include
        cp -r ${PREFIX_DIR}/include/openssl ${OUTPUT_ROOT}/include

        [ -d ${OUTPUT_ROOT}/lib ] || mkdir -p ${OUTPUT_ROOT}/lib
        cp ${PREFIX_DIR}/lib/libcrypto.a ${OUTPUT_ROOT}/lib
        cp ${PREFIX_DIR}/lib/libssl.a ${OUTPUT_ROOT}/lib
    fi;
    popd
}

for ((i=0; i < ${#AND_ARCHS_ARRAY[@]}; i++))
do
    echo "\${AND_ARCHS[$i]} ${AND_ARCHS_ARRAY[i]}"
    if [[ $# -eq 0 ]] || [[ "$1" == "${AND_ARCHS_ARRAY[i]}" ]]; then
        # Do not build 64 bit arch if ANDROID_API is less than 21 which is
        # the minimum supported API level for 64 bit.
        ABI_OR_RUST_ARCH=$(abi_or_rust_arch "${AND_ARCHS_ARRAY[i]}");
        [[ ${ANDROID_API} < 21 ]] && ( echo "${ABI_OR_RUST_ARCH}" | grep 64 > /dev/null ) && continue;
        configure_make "${AND_ARCHS_ARRAY[i]}" "${ABI_OR_RUST_ARCH}"
    fi
done
