#!/usr/bin/env bash

source ./common.sh
TOOLS_ROOT="${SCRIPT_PATH}/../target"
if [[ ! -v AND_ARCHS ]]; then
    : "${AND_ARCHS:=android android-armeabi android64-aarch64 android-x86 android64 android-mips android-mips64}"
fi
AND_ARCHS_ARRAY=(${AND_ARCHS})
# API 21 is the minimum requirement for 64 bit archs.
ANDROID_API=${ANDROID_API:-22}
# see: http://stackoverflow.com/questions/11362250/in-bash-how-do-i-test-if-a-variable-is-defined-in-u-mode
: "${ANDROID_NDK_HOME:=/usr/local/opt/android-ndk}"
: "${ANDROID_NDK:=/usr/local/opt/android-ndk/android-ndk-r14b}"
NDK="${ANDROID_NDK}"

function android_configure() {
    # ARCH must expose for build scripts
    local ARCH=$1;
    local ABI_OR_RUST_ARCH=$(abi_or_rust_arch "${ARCH}");
    local CLANG=${3:-""};

    local RUST_ANDROID_OS="linux-android"
    if [[ "${ABI_OR_RUST_ARCH}" == arm* ]]; then
        RUST_ANDROID_OS="linux-androideabi"
    fi
    local TOOLCHAIN_ROOT=${TOOLS_ROOT}/toolchain-${ABI_OR_RUST_ARCH}-${RUST_ANDROID_OS}

    if [ "$ARCH" == "android" ]; then
        export ARCH_FLAGS="-mthumb"
        export ARCH_LINK=""
        export TOOL="arm-linux-androideabi"
        NDK_FLAGS="--arch=arm"
    elif [ "$ARCH" == "android-armeabi" ]; then
        export ARCH_FLAGS="-march=armv7-a -mfloat-abi=softfp -mfpu=vfpv3-d16 -mthumb -mfpu=neon"
        export ARCH_LINK="-march=armv7-a -Wl,--fix-cortex-a8"
        export TOOL="arm-linux-androideabi"
        NDK_FLAGS="--arch=arm"
    elif [ "$ARCH" == "android64-aarch64" ]; then
        export ARCH_FLAGS=""
        export ARCH_LINK=""
        export TOOL="aarch64-linux-android"
        NDK_FLAGS="--arch=arm64"
    elif [ "$ARCH" == "android-x86" ]; then
        export ARCH_FLAGS="-march=i686 -mtune=intel -msse3 -mfpmath=sse -m32"
        export ARCH_LINK=""
        export TOOL="i686-linux-android"
        NDK_FLAGS="--arch=x86"
    elif [ "$ARCH" == "android64" ]; then
        export ARCH_FLAGS="-march=x86-64 -msse4.2 -mpopcnt -m64 -mtune=intel"
        export ARCH_LINK=""
        export TOOL="x86_64-linux-android"
        NDK_FLAGS="--arch=x86_64"
    elif [ "$ARCH" == "android-mips" ]; then
        export ARCH_FLAGS=""
        export ARCH_LINK=""
        export TOOL="mipsel-linux-android"
        NDK_FLAGS="--arch=mips"
#    elif [ "$ARCH" == "android-mips64" ]; then
#        export ARCH="linux64-mips64"
#        export ARCH_FLAGS=""
#        export ARCH_LINK=""
#        export TOOL="mips64el-linux-android"
#        NDK_FLAGS="--arch=mips64"
    fi;

    [ -d ${TOOLCHAIN_ROOT} ] || python $NDK/build/tools/make_standalone_toolchain.py \
                                    --api ${ANDROID_API} \
                                    --stl libc++ \
                                    --install-dir=${TOOLCHAIN_ROOT} \
                                    $NDK_FLAGS

    export TOOLCHAIN_PATH=${TOOLCHAIN_ROOT}/bin
    export NDK_TOOLCHAIN_BASENAME=${TOOLCHAIN_PATH}/${TOOL}
    export SYSROOT=${TOOLCHAIN_ROOT}/sysroot
    export CROSS_SYSROOT=$SYSROOT
    if [ -z "${CLANG}" ]; then
        export CC=${NDK_TOOLCHAIN_BASENAME}-gcc
        export CXX=${NDK_TOOLCHAIN_BASENAME}-g++
    else
        export CC=${TOOLCHAIN_PATH}/clang
        export CXX=${TOOLCHAIN_PATH}/clang++
    fi;
    export LINK=${CXX}
    export LD=${NDK_TOOLCHAIN_BASENAME}-ld
    export AR=${NDK_TOOLCHAIN_BASENAME}-ar
    export RANLIB=${NDK_TOOLCHAIN_BASENAME}-ranlib
    export STRIP=${NDK_TOOLCHAIN_BASENAME}-strip
    export CPPFLAGS=${CPPFLAGS:-""}
    export LIBS=${LIBS:-""}
    export CFLAGS="${ARCH_FLAGS} -fpic -ffunction-sections -funwind-tables -fstack-protector -fno-strict-aliasing -finline-limit=64"
    export CXXFLAGS="${CFLAGS} -std=c++11 -frtti -fexceptions"
    export LDFLAGS="${ARCH_LINK}"
    echo "**********************************************"
    echo "use ANDROID_API=${ANDROID_API}"
    echo "use NDK=${NDK}"
    echo "export ARCH=${ARCH}"
    echo "export NDK_TOOLCHAIN_BASENAME=${NDK_TOOLCHAIN_BASENAME}"
    echo "export SYSROOT=${SYSROOT}"
    echo "export CC=${CC}"
    echo "export CXX=${CXX}"
    echo "export LINK=${LINK}"
    echo "export LD=${LD}"
    echo "export AR=${AR}"
    echo "export RANLIB=${RANLIB}"
    echo "export STRIP=${STRIP}"
    echo "export CPPFLAGS=${CPPFLAGS}"
    echo "export CFLAGS=${CFLAGS}"
    echo "export CXXFLAGS=${CXXFLAGS}"
    echo "export LDFLAGS=${LDFLAGS}"
    echo "export LIBS=${LIBS}"
    echo "**********************************************"
}
