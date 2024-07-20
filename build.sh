#!/usr/bin/env bash

 #
 # Script For Building Android Kernel
 #

# Specify Kernel Directory
KERNEL_DIR="$(pwd)"

# Default linker to use for builds
export LINKER="ld.lld"

BUILD=$1

if [ "$BUILD" = "local" ]; then
	if [ -e ids.txt ]; then
		chat_id=$(awk "NR==1{print;exit}" ids.txt)
		token=$(awk "NR==2{print;exit}" ids.txt)
	else
		echo "Type ur chat id:"
		read chat
		echo "$chat" > ids.txt
		chat_id=$chat
		echo "Type ur bot token:"
		read token
		echo "$token" >> ids.txt
		token=$token
	fi
fi

DEVICE=$2

VERSION=BETA
if [ "${DEVICE}" = "alioth" ]; then
DEFCONFIG=vendor/xiaomi/alioth.config
MODEL="Poco F3"
elif [ "${DEVICE}" = "lmi" ]; then
DEFCONFIG=vendor/xiaomi/lmi.config
MODEL="Poco F2 Pro"
elif [ "${DEVICE}" = "apollo" ]; then
DEFCONFIG=vendor/xiaomi/apollo.config
MODEL="Mi 10T Pro"
elif [ "${DEVICE}" = "munch" ]; then
DEFCONFIG=vendor/xiaomi/munch.config
MODEL="Poco F4"
elif [ "${DEVICE}" = "cas" ]; then
DEFCONFIG=vendor/xiaomi/cas.config
MODEL="Mi 10 Ultra"
elif [ "${DEVICE}" = "cmi" ]; then
DEFCONFIG=vendor/xiaomi/cmi.config
MODEL="Mi 10 Pro"
elif [ "${DEVICE}" = "umi" ]; then
DEFCONFIG=vendor/xiaomi/umi.config
MODEL="Mi 10"
fi

# Files
IMAGE=$(pwd)/out/arch/arm64/boot/Image
DTBO=$(pwd)/out/arch/arm64/boot/dtbo.img
DTB=$(pwd)/out/arch/arm64/boot/dtb.img
OUT_DIR=out/
#dts_source=arch/arm64/boot/dts/vendor/qcom

# Verbose Build
VERBOSE=0

# Kernel Version
KERVER=$(make kernelversion)

COMMIT_HEAD=$(git log --oneline -1)

# Date and Time
DATE=$(TZ=Europe/Lisbon date +"%Y%m%d-%T")
TM=$(date +"%F%S")

# Specify Final Zip Name
FINAL_ZIP=Nexus-${VERSION}-${DEVICE}-KERNEL-${TM}.zip

# Specify compiler [ proton, nexus, aosp ]
COMPILER=aosp

# Clone ToolChain
function cloneTC() {
	
	case $COMPILER in
	
		nexus)
			git clone --depth=1  https://gitlab.com/Project-Nexus/nexus-clang.git clang
			PATH="${KERNEL_DIR}/clang/bin:$PATH"
			;;

		neutron)
			if [ ! -d clang ]; then
			mkdir clang && cd clang
			bash <(curl -s https://raw.githubusercontent.com/Neutron-Toolchains/antman/main/antman) -S
			cd ..
			else
			echo "Neutron alreay cloned"
			fi
			PATH="${KERNEL_DIR}/clang/bin:$PATH"
			;;

		nex14)
			git clone --depth=1  https://gitlab.com/Project-Nexus/nexus-clang.git -b nexus-14 clang
			PATH="${KERNEL_DIR}/clang/bin:$PATH"
			;;

		aosp)
			echo "* Checking if Aosp Clang is already cloned..."
			if [ -d clangB ]; then
	  		echo "××××××××××××××××××××××××××××"
	  		echo "  Already Cloned Aosp Clang"
	  		echo "××××××××××××××××××××××××××××"
			else
			export CLANG_VERSION="clang-r530567"
            mkdir -p clangB
            (
              cd clangB || exit
              wget -q -O - https://android.googlesource.com/platform/prebuilts/clang/host/linux-x86/+archive/refs/heads/master/${CLANG_VERSION}.tgz | tar -xzf -
            )

			git clone https://github.com/LineageOS/android_prebuilts_gcc_linux-x86_aarch64_aarch64-linux-android-4.9.git --depth=1 gcc
			git clone https://github.com/LineageOS/android_prebuilts_gcc_linux-x86_arm_arm-linux-androideabi-4.9.git  --depth=1 gcc32
			fi
			PATH="${KERNEL_DIR}/clangB/bin:${KERNEL_DIR}/gcc/bin:${KERNEL_DIR}/gcc32/bin:${PATH}"
			;;
			
		zyc)
		    if [ ! -d clang ]; then
				mkdir clang
            	cd clang
		    	wget https://raw.githubusercontent.com/ZyCromerZ/Clang/main/Clang-main-lastbuild.txt
		    	V="$(cat Clang-main-lastbuild.txt)"
            	wget -q https://github.com/ZyCromerZ/Clang/releases/download/19.0.0git-$V-release/Clang-19.0.0git-$V.tar.gz
	        	tar -xf Clang-19.0.0git-$V.tar.gz
	        	cd ..
				fi
	        	PATH="${KERNEL_DIR}/clang/bin:$PATH"
	        ;;
	    slim)
	        git clone --depth=1 https://gitlab.com/ThankYouMario/android_prebuilts_clang-standalone -b slim-16 clangB
	        git clone https://github.com/LineageOS/android_prebuilts_gcc_linux-x86_aarch64_aarch64-linux-android-4.9.git --depth=1 gcc
			git clone https://github.com/LineageOS/android_prebuilts_gcc_linux-x86_arm_arm-linux-androideabi-4.9.git  --depth=1 gcc32
			PATH="${KERNEL_DIR}/clangB/bin:${KERNEL_DIR}/gcc/bin:${KERNEL_DIR}/gcc32/bin:${PATH}"
	        ;;
	    eva-gcc)
	        git clone https://github.com/mvaisakh/gcc-arm64 --depth=1 gcc64
	        git clone https://github.com/mvaisakh/gcc-arm --depth=1 gcc32
            PATH="${KERNEL_DIR}"/gcc32/bin:"${KERNEL_DIR}"/gcc64/bin:/usr/bin/:${PATH}
            ;;
		yuki)
			git clone --depth=1 https://bitbucket.org/thexperienceproject/yuki-clang.git -b 19.0.0git clang
			PATH="${KERNEL_DIR}/clang/bin:$PATH"
			;;
		*)
			echo "Compiler not defined"
			;;
	esac
        # Clone AnyKernel
		rm -rf AnyKernel3
		if [ "${DEVICE}" = "alioth" ]; then
          git clone --depth=1 https://github.com/NotZeetaa/AnyKernel3 -b alioth AnyKernel3
        elif [ "${DEVICE}" = "apollo" ]; then
          git clone --depth=1 https://github.com/NotZeetaa/AnyKernel3 -b apollo AnyKernel3
        elif [ "${DEVICE}" = "munch" ]; then
          git clone --depth=1 https://github.com/NotZeetaa/AnyKernel3 -b munch AnyKernel3
		elif [ "${DEVICE}" = "cas" ]; then
          git clone --depth=1 https://github.com/NotZeetaa/AnyKernel3 -b cas AnyKernel3
		elif [ "${DEVICE}" = "cmi" ]; then
          git clone --depth=1 https://github.com/NotZeetaa/AnyKernel3 -b cmi AnyKernel3
		elif [ "${DEVICE}" = "umi" ]; then
          git clone --depth=1 https://github.com/NotZeetaa/AnyKernel3 -b umi AnyKernel3
		else
		  git clone --depth=1 https://github.com/NotZeetaa/AnyKernel3 -b lmi AnyKernel3
		fi
	}
	
# Export Variables
function exports() {
	
        # Export KBUILD_COMPILER_STRING
        if [ -d ${KERNEL_DIR}/clang ];
           then
               export KBUILD_COMPILER_STRING=$(${KERNEL_DIR}/clang/bin/clang --version | head -n 1 | perl -pe 's/\(http.*?\)//gs' | sed -e 's/  */ /g' -e 's/[[:space:]]*$//')
        elif [ -d ${KERNEL_DIR}/gcc64 ];
           then
               export KBUILD_COMPILER_STRING=$("$KERNEL_DIR/gcc64"/bin/aarch64-elf-gcc --version | head -n 1)
        elif [ -d ${KERNEL_DIR}/clangB ];
            then
               export KBUILD_COMPILER_STRING=$(${KERNEL_DIR}/clangB/bin/clang --version | head -n 1 | perl -pe 's/\(http.*?\)//gs' | sed -e 's/  */ /g' -e 's/[[:space:]]*$//')
        fi
        
        # Export ARCH and SUBARCH
        export ARCH=arm64
        export SUBARCH=arm64
               
        # KBUILD HOST and USER
        export KBUILD_BUILD_HOST=ArchLinux
        export KBUILD_BUILD_USER="NotZeeta"
        
	export PROCS=$(nproc --all)
	export DISTRO=$(source /etc/os-release && echo "${NAME}")
	}

# Telegram Bot Integration

function post_msg() {
	curl -s -X POST "https://api.telegram.org/bot$token/sendMessage" \
	-d chat_id="$chat_id" \
	-d "disable_web_page_preview=true" \
	-d "parse_mode=html" \
	-d text="$1"
	}

function push() {
	curl -F document=@$1 "https://api.telegram.org/bot$token/sendDocument" \
	-F chat_id="$chat_id" \
	-F "disable_web_page_preview=true" \
	-F "parse_mode=html" \
	-F caption="$2"
	}

# Compilation

METHOD=$3

function compile() {
START=$(date +"%s")
	# Push Notification
	post_msg "<b>$KBUILD_BUILD_VERSION CI Build Triggered</b>%0A<b>Docker OS: </b><code>$DISTRO</code>%0A<b>Kernel Version : </b><code>$KERVER</code>%0A<b>Date : </b><code>$(TZ=Europe/Lisbon date)</code>%0A<b>Device : </b><code>$MODEL [$DEVICE]</code>%0A<b>Pipeline Host : </b><code>$KBUILD_BUILD_HOST</code>%0A<b>Host Core Count : </b><code>$PROCS</code>%0A<b>Compiler Used : </b><code>$KBUILD_COMPILER_STRING</code>%0A<b>Top Commit : </b><a href='$DRONE_COMMIT_LINK'>$COMMIT_HEAD</a>"
	
	# Compile
	if [ -d ${KERNEL_DIR}/clang ];
	   then
           make O=out CC=clang ARCH=arm64 vendor/kona-perf_defconfig vendor/xiaomi/sm8250-common.config ${DEFCONFIG}
		   if [ "$METHOD" = "lto" ]; then
		     scripts/config --file ${OUT_DIR}/.config \
             -e LTO_CLANG \
             -d THINLTO
           fi
	       make -kj$(nproc --all) O=out \
	       ARCH=arm64 \
	       LLVM=1 \
	       LLVM_IAS=1 \
	       CROSS_COMPILE=aarch64-linux-gnu- \
	       CROSS_COMPILE_COMPAT=arm-linux-gnueabi- \
	       V=$VERBOSE 2>&1 | tee error.log
	elif [ -d ${KERNEL_DIR}/gcc64 ];
	   then
           make O=out ARCH=arm64 vendor/kona-perf_defconfig vendor/xiaomi/sm8250-common.config ${DEFCONFIG}
		   if [ "$METHOD" = "lto" ]; then
		     scripts/config --file ${OUT_DIR}/.config \
             -e CONFIG_LTO_GCC
           fi
	       make -kj$(nproc --all) O=out \
	       	ARCH=arm64 \
	       	CC=aarch64-elf-gcc \
			LD="${KERNEL_DIR}/gcc64/bin/aarch64-elf-ld.lld" \
			AR=llvm-ar \
			NM=llvm-nm \
			OBJCOPY=llvm-objcopy \
			OBJDUMP=llvm-objdump \
			OBJCOPY=llvm-objcopy \
			OBJSIZE=llvm-size \
			STRIP=llvm-strip \
			CROSS_COMPILE=aarch64-elf- \
			CROSS_COMPILE_COMPAT=arm-eabi- \
			CC_COMPAT=arm-eabi-gcc \
	       	V=$VERBOSE 2>&1 | tee error.log
        elif [ -d ${KERNEL_DIR}/clangB ];
           then
           make O=out CC=clang ARCH=arm64 vendor/kona-perf_defconfig vendor/xiaomi/sm8250-common.config ${DEFCONFIG}
		   if [ "$METHOD" = "lto" ]; then
		     scripts/config --file ${OUT_DIR}/.config \
             -e LTO_CLANG \
             -d THINLTO
           fi
           make -kj$(nproc --all) O=out \
	       ARCH=arm64 \
	       LLVM=1 \
	       LLVM_IAS=1 \
	       CLANG_TRIPLE=aarch64-linux-gnu- \
	       CROSS_COMPILE=aarch64-linux-android- \
	       CROSS_COMPILE_COMPAT=arm-linux-androideabi- \
	       V=$VERBOSE 2>&1 | tee error.log
	fi
	
	# Verify Files
	if ! [ -a "$IMAGE" ];
	   then
	       push "error.log" "Build Throws Errors"
	       exit 1
	fi
	}
	
function compile_ksu() {
START=$(date +"%s")
	# Compile
	if [ -d ${KERNEL_DIR}/clang ];
	   then
           make O=out CC=clang ARCH=arm64 vendor/kona-perf_defconfig vendor/xiaomi/sm8250-common.config ${DEFCONFIG}
		   if [ "$METHOD" = "lto" ]; then
		     scripts/config --file ${OUT_DIR}/.config \
             -e LTO_CLANG \
             -d THINLTO
           fi
	       make -kj$(nproc --all) O=out \
	       ARCH=arm64 \
	       LLVM=1 \
	       LLVM_IAS=1 \
	       CROSS_COMPILE=aarch64-linux-gnu- \
	       CROSS_COMPILE_COMPAT=arm-linux-gnueabi- \
	       V=$VERBOSE 2>&1 | tee error.log
	elif [ -d ${KERNEL_DIR}/gcc64 ];
	   then
           make O=out ARCH=arm64 vendor/kona-perf_defconfig vendor/xiaomi/sm8250-common.config ${DEFCONFIG}
	       if [ "$METHOD" = "lto" ]; then
		     scripts/config --file ${OUT_DIR}/.config \
             -e CONFIG_LTO_GCC
           fi
		   make -kj$(nproc --all) O=out \
	       ARCH=arm64 \
	       CC=aarch64-elf-gcc \
			LD="${KERNEL_DIR}/gcc64/bin/aarch64-elf-ld.lld" \
			AR=llvm-ar \
			NM=llvm-nm \
			OBJCOPY=llvm-objcopy \
			OBJDUMP=llvm-objdump \
			OBJCOPY=llvm-objcopy \
			OBJSIZE=llvm-size \
			STRIP=llvm-strip \
			CROSS_COMPILE=aarch64-elf- \
			CROSS_COMPILE_COMPAT=arm-eabi- \
			CC_COMPAT=arm-eabi-gcc \
	       V=$VERBOSE 2>&1 | tee error.log
        elif [ -d ${KERNEL_DIR}/clangB ];
           then
           make O=out CC=clang ARCH=arm64 vendor/kona-perf_defconfig vendor/xiaomi/sm8250-common.config ${DEFCONFIG}
		   if [ "$METHOD" = "lto" ]; then
		     scripts/config --file ${OUT_DIR}/.config \
             -e LTO_CLANG \
             -d THINLTO
           fi
           make -kj$(nproc --all) O=out \
	       ARCH=arm64 \
	       LLVM=1 \
	       LLVM_IAS=1 \
	       CLANG_TRIPLE=aarch64-linux-gnu- \
	       CROSS_COMPILE=aarch64-linux-android- \
	       CROSS_COMPILE_COMPAT=arm-linux-androideabi- \
	       V=$VERBOSE 2>&1 | tee error.log
	fi
	
	# Verify Files
	if ! [ -a "$IMAGE" ];
	   then
	       push "error.log" "Build Throws Errors"
	       exit 1
	   else
	       post_msg " Kernel Compilation Finished. Started Zipping "
	fi
}

# Zipping
function move() {
	# Copy Files To AnyKernel3 Zip
	mv $IMAGE AnyKernel3
    mv $DTBO AnyKernel3
    mv $DTB AnyKernel3
}

function move_ksu() {
	mv $IMAGE AnyKernel3/ksu/
}

function zipping() {
    # Zipping and Push Kernel
    cd AnyKernel3 || exit 1
    zip -r9 ${FINAL_ZIP} *
    MD5CHECK=$(md5sum "$FINAL_ZIP" | cut -d' ' -f1)
    UPLOAD_GOFILE=$(curl -F file=@$FINAL_ZIP https://store1.gofile.io/uploadFile)
    DOWNLOAD_LINK_GOFILE=$(echo $UPLOAD_GOFILE | awk -F '"' '{print $10}')
    push "$FINAL_ZIP" "Build took : $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) second(s) | For <b>$MODEL ($DEVICE)</b> | <b>${KBUILD_COMPILER_STRING}</b> | <b>MD5 Checksum : </b><code>$MD5CHECK</code> | GOFILE Download link: $DOWNLOAD_LINK_GOFILE"
	rm *.zip
    cd ..
}

cloneTC
exports
compile
END=$(date +"%s")
DIFF=$(($END - $START))
move
# KernelSU
echo "CONFIG_KSU=y" >> $(pwd)/arch/arm64/configs/$DEFCONFIG
compile_ksu
move_ksu
zipping
if [ "$BUILD" = "local" ]; then
# Discard KSU changes in defconfig
git restore arch/arm64/configs/$DEFCONFIG
fi
