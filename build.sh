#!/usr/bin/env bash

 #
 # Script For Building Android Kernel
 #

##----------------------------------------------------------##
# Specify Kernel Directory
KERNEL_DIR="$(pwd)"

DEVICE=$1

if [ "${DEVICE}" = "lmi" ]; then
DEVICE2=lmi-FW12
DEFCONFIG=vendor/lmi_defconfig
MODEL=Poco F2 Pro
VERSION=BETA
curl https://github.com/projects-nexus/nexus_kernel_xiaomi_sm8250/commit/d982f028426863ebcc1c0c247bd855434b4e9826.patch | git am
elif [ "${DEVICE}" = "alioth" ]; then
DEVICE2=alioth
DEFCONFIG=vendor/alioth_defconfig
MODEL=Poco F3
VERSION=BETA
elif [ "${DEVICE}" = "fw13" ]; then
DEVICE2=lmi-FW13
DEFCONFIG=vendor/lmi_defconfig
MODEL=Poco F2 Pro
VERSION=BETA
elif [ "${DEVICE}" = "apollo" ]; then
DEVICE2=apollo
DEFCONFIG=vendor/apollo_defconfig
MODEL=Mi 10T Pro
VERSION=BETA
fi

# Files
IMAGE=$(pwd)/out/arch/arm64/boot/Image
DTBO=$(pwd)/out/arch/arm64/boot/dtbo.img
DTB=$(pwd)/out/arch/arm64/boot/dts/vendor/qcom/kona-v2.1.dtb

# Verbose Build
VERBOSE=0

# Kernel Version
KERVER=$(make kernelversion)

COMMIT_HEAD=$(git log --oneline -1)

# Date and Time
DATE=$(TZ=Asia/Kolkata date +"%Y%m%d-%T")
TANGGAL=$(date +"%F%S")

# Specify Final Zip Name
ZIPNAME=Nexus
if [ "${DEVICE}" = "fw13" ]; then
  FINAL_ZIP=${ZIPNAME}-${VERSION}-${DEVICE2}-KERNEL-AOSP-${TANGGAL}.zip
  FINAL_ZIP2=${ZIPNAME}-${VERSION}-lmi-KERNEL-MIUI-${TANGGAL}.zip
elif [ "${DEVICE}" = "lmi" ]; then
  FINAL_ZIP=${ZIPNAME}-${VERSION}-${DEVICE2}-KERNEL-AOSP-${TANGGAL}.zip
else
  FINAL_ZIP=${ZIPNAME}-${VERSION}-${DEVICE}-KERNEL-AOSP-${TANGGAL}.zip
fi

##----------------------------------------------------------##
# Specify Linker
LINKER=ld.lld

##----------------------------------------------------------##
# Specify compiler [ proton, atomx, eva, aosp ]
COMPILER=zyc14

##----------------------------------------------------------##
# Clone ToolChain
function cloneTC() {
	
	if [ $COMPILER = "atomx" ];
	then
	git clone --depth=1 https://gitlab.com/ElectroPerf/atom-x-clang.git clang
	PATH="${KERNEL_DIR}/clang/bin:$PATH"
	
	elif [ $COMPILER = "proton" ];
	then
	git clone --depth=1  https://github.com/kdrag0n/proton-clang.git clang
	PATH="${KERNEL_DIR}/clang/bin:$PATH"
	
	elif [ $COMPILER = "nexus" ];
	then
	git clone --depth=1  https://gitlab.com/Project-Nexus/nexus-clang clang
	PATH="${KERNEL_DIR}/clang/bin:$PATH"

	elif [ $COMPILER = "neutron" ];
    then
    git clone --depth=1 https://gitlab.com/dakkshesh07/neutron-clang.git clang
    PATH="${KERNEL_DIR}/clang/bin:$PATH"

	elif [ $COMPILER = "zyc14" ];
    then
    git clone --depth=1 https://github.com/EmanuelCN/zyc_clang-14 clang
    PATH="${KERNEL_DIR}/clang/bin:$PATH"
	
	elif [ $COMPILER = "prelude" ];
	then
	git clone --depth=1 https://gitlab.com/jjpprrrr/prelude-clang.git clang
	PATH="${KERNEL_DIR}/clang/bin:$PATH"
	
	elif [ $COMPILER = "eva" ];
	then
	git clone --depth=1 https://github.com/mvaisakh/gcc-arm64.git -b gcc-new gcc64
	git clone --depth=1 https://github.com/mvaisakh/gcc-arm.git -b gcc-new gcc32
	PATH=$KERNEL_DIR/gcc64/bin/:$KERNEL_DIR/gcc32/bin/:/usr/bin:$PATH
	
	elif [ $COMPILER = "aosp" ];
	then
	echo "* Checking if Aosp Clang is already cloned..."
	if [ -d clangB ]; then
	  echo "××××××××××××××××××××××××××××"
	  echo "  Already Cloned Aosp Clang"
	  echo "××××××××××××××××××××××××××××"
	else
	export CLANG_VERSION="clang-r458507"
	echo "* It's not cloned, cloning it..."
        mkdir clangB
        cd clangB || exit
	wget -q https://android.googlesource.com/platform/prebuilts/clang/host/linux-x86/+archive/refs/heads/master/${CLANG_VERSION}.tgz
        tar -xf ${CLANG_VERSION}.tgz
        cd .. || exit
	git clone https://github.com/LineageOS/android_prebuilts_gcc_linux-x86_aarch64_aarch64-linux-android-4.9.git --depth=1 gcc
	git clone https://github.com/LineageOS/android_prebuilts_gcc_linux-x86_arm_arm-linux-androideabi-4.9.git  --depth=1 gcc32
	fi
	PATH="${KERNEL_DIR}/clangB/bin:${KERNEL_DIR}/gcc/bin:${KERNEL_DIR}/gcc32/bin:${PATH}"
	
	elif [ $COMPILER = "zyc" ];
	then
        mkdir clang
        cd clang
		wget -cO --quiet - https://raw.githubusercontent.com/ZyCromerZ/Clang/main/Clang-main-lastbuild.txt > version.txt
		V="$(cat version.txt)"
        wget https://github.com/ZyCromerZ/Clang/releases/download/16.0.0-$V-release/Clang-16.0.0-$V.tar.gz
	    tar -xf Clang-16.0.0-$V.tar.gz
	    cd ..
	    PATH="${KERNEL_DIR}/clang/bin:$PATH"
	fi
        # Clone AnyKernel
        if [ "${DEVICE}" = "alioth" ]; then
          git clone --depth=1 https://github.com/NotZeetaa/Flashable_Zip_lmi.git -b alioth AnyKernel3
        elif [ "${DEVICE}" = "apollo" ]; then
          git clone --depth=1 https://github.com/NotZeetaa/Flashable_Zip_lmi.git -b apollo AnyKernel3
        else
		  git clone --depth=1 https://github.com/NotZeetaa/Flashable_Zip_lmi.git AnyKernel3
		fi
	}
	
##------------------------------------------------------##
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
        
        # CI
        if [ "$CI" ]
           then
               
           if [ "$CIRCLECI" ]
              then
                  export KBUILD_BUILD_VERSION=${CIRCLE_BUILD_NUM}
                  export CI_BRANCH=${CIRCLE_BRANCH}
           elif [ "$DRONE" ]
	      then
		  export KBUILD_BUILD_VERSION=${DRONE_BUILD_NUMBER}
		  export CI_BRANCH=${DRONE_BRANCH}
           fi
		   
        fi
	export PROCS=$(nproc --all)
	export DISTRO=$(source /etc/os-release && echo "${NAME}")
	}
        
##----------------------------------------------------------------##
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
##----------------------------------------------------------##
# Compilation
function compile() {
START=$(date +"%s")
	# Push Notification
	post_msg "<b>$KBUILD_BUILD_VERSION CI Build Triggered</b>%0A<b>Docker OS: </b><code>$DISTRO</code>%0A<b>Kernel Version : </b><code>$KERVER</code>%0A<b>Date : </b><code>$(TZ=Asia/Kolkata date)</code>%0A<b>Device : </b><code>$MODEL [$DEVICE2]</code>%0A<b>Pipeline Host : </b><code>$KBUILD_BUILD_HOST</code>%0A<b>Host Core Count : </b><code>$PROCS</code>%0A<b>Compiler Used : </b><code>$KBUILD_COMPILER_STRING</code>%0A<b>Branch : </b><code>$CI_BRANCH</code>%0A<b>Top Commit : </b><a href='$DRONE_COMMIT_LINK'>$COMMIT_HEAD</a>"
	
	# Compile
	if [ -d ${KERNEL_DIR}/clang ];
	   then
           make O=out CC=clang ARCH=arm64 ${DEFCONFIG}
	       make -kj$(nproc --all) O=out \
	       ARCH=arm64 \
	       LLVM=1 \
	       LLVM_IAS=1 \
	       LD=${LINKER} \
	       CROSS_COMPILE=aarch64-linux-gnu- \
	       CROSS_COMPILE_COMPAT=arm-linux-gnueabi- \
	       V=$VERBOSE 2>&1 | tee error.log
	elif [ -d ${KERNEL_DIR}/gcc64 ];
	   then
           make O=out ARCH=arm64 ${DEFCONFIG}
	       make -kj$(nproc --all) O=out \
	       ARCH=arm64 \
	       CROSS_COMPILE_COMPAT=arm-eabi- \
	       CROSS_COMPILE=aarch64-elf- \
	       AR=llvm-ar \
	       NM=llvm-nm \
	       OBJCOPY=llvm-objcopy \
	       OBJDUMP=llvm-objdump \
	       STRIP=llvm-strip \
	       OBJSIZE=llvm-size \
	       V=$VERBOSE 2>&1 | tee error.log
        elif [ -d ${KERNEL_DIR}/clangB ];
           then
           make O=out CC=clang ARCH=arm64 ${DEFCONFIG}
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

##----------------------------------------------------------------##
function zipping() {
	# Copy Files To AnyKernel3 Zip
	mv $IMAGE AnyKernel3
    mv $DTBO AnyKernel3
    mv $DTB AnyKernel3/dtb

	# Zipping and Push Kernel
	cd AnyKernel3 || exit 1
        zip -r9 ${FINAL_ZIP} *
        MD5CHECK=$(md5sum "$FINAL_ZIP" | cut -d' ' -f1)
		if [ "${DEVICE}" = "fw13" ]; then
          push "$FINAL_ZIP" "FW 13. Build took : $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) second(s) | For <b>$MODEL ($DEVICE)</b> | <b>${KBUILD_COMPILER_STRING}</b> | <b>MD5 Checksum : </b><code>$MD5CHECK</code>"
		elif [ "${DEVICE}" = "lmi" ]; then
		  push "$FINAL_ZIP" "FW 12. Build took : $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) second(s) | For <b>$MODEL ($DEVICE)</b> | <b>${KBUILD_COMPILER_STRING}</b> | <b>MD5 Checksum : </b><code>$MD5CHECK</code>"
		else
		  push "$FINAL_ZIP" "Build took : $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) second(s) | For <b>$MODEL ($DEVICE)</b> | <b>${KBUILD_COMPILER_STRING}</b> | <b>MD5 Checksum : </b><code>$MD5CHECK</code>"
		fi
        if [ "${DEVICE}" = "fw13" ]; then
          rm -rf dtbo.img && rm -rf *.zip
          zip -r9 ${FINAL_ZIP2} *
          MD5CHECK=$(md5sum "$FINAL_ZIP2" | cut -d' ' -f1)
          push "$FINAL_ZIP2" "MIUI 13. Build took : $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) second(s) | For <b>$MODEL (lmi)</b> | <b>${KBUILD_COMPILER_STRING}</b> | <b>MD5 Checksum : </b><code>$MD5CHECK</code>"
          cd ..
          rm -rf AnyKernel3
		else 
		  cd ..
          rm -rf AnyKernel3
        fi
        }
    
##----------------------------------------------------------##

cloneTC
exports
compile
END=$(date +"%s")
DIFF=$(($END - $START))
zipping

##----------------*****-----------------------------##
