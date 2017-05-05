# openssl-build

Build openssl for android and ios.

    cd scripts
    ./build-openssl-ios.sh
    ./build-openssl-android.sh

Usage:

    cd scripts
    # for arm (armeabi)
    sh ./build-openssl-android.sh android
    # for armv7 (armeabi-v7a)
    sh ./build-openssl-android.sh android-armeabi
    # for mips
    #sh ./build-openssl-android.sh android-mips
    # for i686 (x86)
    sh ./build-openssl-android.sh android-x86
    # for x86_64
    sh ./build-openssl-android.sh android64
    # for aarch64 (arm64_v8a)
    sh ./build-openssl-android.sh android64-aarch64

Build a release:

    git tag v$version
    git push origin v$version
