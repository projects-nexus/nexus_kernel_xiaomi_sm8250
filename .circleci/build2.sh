#!/usr/bin/env bash
echo "Cloning dependencies"
git clone --depth=1 https://github.com/NotZeetaa/Flashable_Zip_lmi.git -b alioth AnyKernel2
echo "Done"
IMAGE=$(pwd)/out/arch/arm64/boot/Image
TANGGAL=$(date +"%F-%S")
START=$(date +"%s")
KERNEL_DIR=$(pwd)
PATH="${PWD}/clang/bin:$PATH"
export KBUILD_COMPILER_STRING="$(${KERNEL_DIR}/clang/bin/clang --version | head -n 1 | perl -pe 's/\(http.*?\)//gs' | sed -e 's/  */ /g')"
export ARCH=arm64
export KBUILD_BUILD_HOST=droneci
export KBUILD_BUILD_USER="NotZeetaa"
# Send info plox channel
function sendinfo() {
    curl -s -X POST "https://api.telegram.org/bot$token/sendMessage" \
        -d chat_id="$chat_id" \
        -d "disable_web_page_preview=true" \
        -d "parse_mode=html" \
        -d text="<b>• aRise Kernel •</b>%0ABuild started on <code>Drone CI</code>%0AFor device <b>Poco F3</b> (alioth)%0Abranch <code>$(git rev-parse --abbrev-ref HEAD)</code>(master)%0AUnder commit <code>$(git log --pretty=format:'"%h : %s"' -1)</code>%0AUsing compiler: <code>${KBUILD_COMPILER_STRING}</code>%0AStarted on <code>$(date)</code>%0A<b>Build Status:</b>#Stable"
}
# Push kernel to channel
function push() {
    cd AnyKernel2
    ZIP=$(echo *.zip)
    curl -F document=@$ZIP "https://api.telegram.org/bot$token/sendDocument" \
        -F chat_id="$chat_id" \
        -F "disable_web_page_preview=true" \
        -F "parse_mode=html" \
        -F caption="Build took $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) second(s). | For <b>Poco F3 (alioth)</b> | <b>${KBUILD_COMPILER_STRING}</b>"
}
function push2() {
    cd AnyKernel2
    ZIP=$(echo *.zip)
    curl -F document=@$ZIP "https://api.telegram.org/bot$token/sendDocument" \
        -F chat_id="$chat_id" \
        -F "disable_web_page_preview=true" \
        -F "parse_mode=html" \
        -F caption="Build took $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) second(s). | For <b>Poco F3 (alioth)</b> | <b>${KBUILD_COMPILER_STRING}</b>"
    cd ..
}
# Fin Error
function finerr() {
    curl -s -X POST "https://api.telegram.org/bot$token/sendMessage" \
        -d chat_id="$chat_id" \
        -d "disable_web_page_preview=true" \
        -d "parse_mode=markdown" \
        -d text="Build throw an error(s)"
    exit 1
}
# Compile plox
function compile() {
    make O=out ARCH=arm64 vendor/alioth_defconfig
    make -j$(nproc --all) O=out \
                          ARCH=arm64 \
			  CC=clang \
			  CROSS_COMPILE=aarch64-linux-gnu- \
			  CROSS_COMPILE_ARM32=arm-linux-gnueabi-

    if ! [ -a "$IMAGE" ]; then
        finerr
        exit 1
    fi
    cp out/arch/arm64/boot/dts/vendor/qcom/kona-v2.1.dtb AnyKernel2/dtb
    cp out/arch/arm64/boot/Image AnyKernel2
    cp out/arch/arm64/boot/dtbo.img AnyKernel2
}
# Zipping AOSP
function zippingaosp() {
    cd AnyKernel2 || exit 1
    zip -r9 neXus-BETA-kernel-AOSP-alioth-${TANGGAL}.zip *
    cd ..
}
# Zipping Miui
function zippingmiui() {
    cd AnyKernel2 || exit 1
    rm -rf *.zip
    rm -rf dtbo.img
    zip -r9 neXus-BETA-kernel-MIUI-alioth-${TANGGAL}.zip *
    cd ..
}
# Clean
function clean() {
    rm -rf out/arch/arm64/boot/Image
    rm -rf out/arch/arm64/boot/dtbo.img
    rm -rf out/arch/arm64/boot/dts/vendor/qcom/kona-v2.1.dtb
    echo "************************"
    echo "    Cleaned Done"
    echo "************************"
}
sticker
sendinfo
compile
zippingaosp
END=$(date +"%s")
DIFF=$(($END - $START))
push2
zippingmiui
END=$(date +"%s")
DIFF=$(($END - $START))
push
clean

