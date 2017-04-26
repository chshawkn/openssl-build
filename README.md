# openssl-build

Build openssl

    cd scripts
    ./build-openssl-ios.sh
    ./build-openssl-android.sh

Usage:

    cd scripts
    # for aarch64 (arm64_v8a)
    sh ./build-openssl-android.sh android64-aarch64
    # for armv7 (armeabi-v7a)
    sh ./build-openssl-android.sh android-armeabi
    # for arm (armeabi)
    sh ./build-openssl-android.sh android
    # for i686 (x86)
    sh ./build-openssl-android.sh android-x86
    
    # for x86_64
    sh ./build-openssl-android.sh android64
    # for mips
    sh ./build-openssl-android.sh android-mips
    # for mips64
    sh ./build-openssl-android.sh android-mips64
