#!/usr/bin/env bash
echo "Cloning dependencies"
git clone --depth=1 https://github.com/kdrag0n/proton-clang clang
git clone --depth=1 https://github.com/NotZeetaa/Flashable_Zip_lmi.git AnyKernel
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
        -d text="<b>• neXus Kernel •</b>%0ABuild started on <code>Drone CI</code>%0AFor device <b>Poco F2 Pro</b> (lmi)%0Abranch <code>$(git rev-parse --abbrev-ref HEAD)</code>(master)%0AUnder commit <code>$(git log --pretty=format:'"%h : %s"' -1)</code>%0AUsing compiler: <code>${KBUILD_COMPILER_STRING}</code>%0AStarted on <code>$(date)</code>%0A<b>Build Status:</b>#Stable"
}
# Push kernel to channel
function push() {
    cd AnyKernel
    ZIP=$(echo *.zip)
    curl -F document=@$ZIP "https://api.telegram.org/bot$token/sendDocument" \
        -F chat_id="$chat_id" \
        -F "disable_web_page_preview=true" \
        -F "parse_mode=html" \
        -F caption="Build took $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) second(s). | For <b>Poco F2 Pro (lmi)</b> | <b>${KBUILD_COMPILER_STRING}</b>"
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
    make O=out ARCH=arm64 vendor/lmi_defconfig
    make -j$(nproc --all) O=out \
                          ARCH=arm64 \
			  CC=clang \
			  CROSS_COMPILE=aarch64-linux-gnu- \
			  CROSS_COMPILE_ARM32=arm-linux-gnueabi-

    if ! [ -a "$IMAGE" ]; then
        finerr
        exit 1
    fi
    cp out/arch/arm64/boot/dts/vendor/qcom/kona-v2.1.dtb AnyKernel/dtb
    cp out/arch/arm64/boot/Image AnyKernel
    cp out/arch/arm64/boot/dtbo.img AnyKernel
}
# Zipping AOSP
function zippingaosp() {
    cd AnyKernel || exit 1
    zip -r9 neXus-BETA-kernel-AOSP-lmi-${TANGGAL}.zip *
    cd ..
}
# Zipping Miui
function zippingmiui() {
    cd AnyKernel || exit 1
    rm -rf *.zip
    rm -rf dtb
    zip -r9 neXus-BETA-kernel-MIUI-lmi-${TANGGAL}.zip *
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
zippingmiui
END=$(date +"%s")
DIFF=$(($END - $START))
push
clean

