#
# Copyright (C) 2019 The LineageOS Project
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

BOARD_FLASH_BLOCK_SIZE             := 4096
BOARD_BOOTIMAGE_PARTITION_SIZE     := 83886080
BOARD_RECOVERYIMAGE_PARTITION_SIZE := 66060288
BOARD_USERDATAIMAGE_PARTITION_SIZE := 10099646976
BOARD_SYSTEMIMAGE_PARTITION_SIZE   := 2684354560
BOARD_VENDORIMAGE_PARTITION_SIZE   := 536870912
TARGET_USERIMAGES_USE_EXT4         := true
BOARD_VENDORIMAGE_FILE_SYSTEM_TYPE := ext4
TARGET_COPY_OUT_VENDOR             := vendor
BOARD_BUILD_SYSTEM_ROOT_IMAGE      := true

# Android Verified Boot
BOARD_AVB_ENABLE := true
BOARD_AVB_MAKE_VBMETA_IMAGE_ARGS += --set_hashtree_disabled_flag
BOARD_AVB_MAKE_VBMETA_IMAGE_ARGS += --flags 2

# Assert
TARGET_OTA_ASSERT_DEVICE := quill,asg

# Bluetooth
ifeq ($(TARGET_TEGRA_BT),bcm)
BOARD_CUSTOM_BT_CONFIG := device/nvidia/quill/comms/vnd_quill.txt
BOARD_BLUETOOTH_BDROID_BUILDCFG_INCLUDE_DIR := device/nvidia/quill/comms
endif

# Kernel
ifneq ($(TARGET_PREBUILT_KERNEL),)
BOARD_VENDOR_KERNEL_MODULES += $(wildcard $(dir $(TARGET_PREBUILT_KERNEL))/*.ko)
else
KERNEL_TOOLCHAIN        := $(shell pwd)/prebuilts/gcc/linux-x86/aarch64/aarch64-linux-gnu-6.4.1/bin
KERNEL_TOOLCHAIN_PREFIX := aarch64-linux-gnu-
TARGET_KERNEL_SOURCE    := kernel/nvidia/linux-4.9/kernel/kernel-4.9
TARGET_KERNEL_CONFIG    := tegra_android_defconfig
BOARD_KERNEL_IMAGE_NAME := zImage
endif

# Manifest
DEVICE_MANIFEST_FILE := device/nvidia/quill/manifest.xml

# Recovery
TARGET_RECOVERY_FSTAB    := device/nvidia/quill/initfiles/fstab.quill

# Security Patch Level
VENDOR_SECURITY_PATCH := 2020-07-05

# TWRP Support
ifeq ($(WITH_TWRP),true)
include device/nvidia/quill/twrp/twrp.mk
endif

include device/nvidia/t186-common/BoardConfigCommon.mk
include vendor/nvidia/quill/BoardConfigVendor.mk
