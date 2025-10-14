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
BOARD_ODMIMAGE_PARTITION_SIZE      := 134217728
BOARD_SYSTEMIMAGE_PARTITION_SIZE   := 4294967296
BOARD_VENDORIMAGE_PARTITION_SIZE   := 536870912
TARGET_USERIMAGES_USE_EXT4         := true
BOARD_ODMIMAGE_FILE_SYSTEM_TYPE    := ext4
BOARD_VENDORIMAGE_FILE_SYSTEM_TYPE := ext4
TARGET_COPY_OUT_ODM                := odm
TARGET_COPY_OUT_VENDOR             := vendor
BOARD_USES_METADATA_PARTITION      := true

# Android Verified Boot
BOARD_AVB_ENABLE ?= true
ifeq ($(BOARD_AVB_ENABLE),true)
ifneq ($(TARGET_BUILD_VARIANT),user)
BOARD_AVB_MAKE_VBMETA_IMAGE_ARGS           += --flags 3
endif
BOARD_AVB_ALGORITHM                        ?= SHA256_RSA4096
BOARD_AVB_KEY_PATH                         ?= external/avb/test/data/testkey_rsa4096.pem
BOARD_AVB_BOOT_ALGORITHM                   := $(BOARD_AVB_ALGORITHM)
BOARD_AVB_BOOT_KEY_PATH                    := $(BOARD_AVB_KEY_PATH)
BOARD_AVB_BOOT_ROLLBACK_INDEX              := 0
BOARD_AVB_BOOT_ROLLBACK_INDEX_LOCATION     := 1
BOARD_AVB_RECOVERY_ALGORITHM               := $(BOARD_AVB_ALGORITHM)
BOARD_AVB_RECOVERY_KEY_PATH                := $(BOARD_AVB_KEY_PATH)
BOARD_AVB_RECOVERY_ROLLBACK_INDEX          := 0
BOARD_AVB_RECOVERY_ROLLBACK_INDEX_LOCATION := 2
BOARD_AVB_ODM_ALGORITHM                    := $(BOARD_AVB_ALGORITHM)
BOARD_AVB_ODM_KEY_PATH                     := $(BOARD_AVB_KEY_PATH)
BOARD_AVB_ODM_ROLLBACK_INDEX               := 0
BOARD_AVB_ODM_ROLLBACK_INDEX_LOCATION      := 3
BOARD_AVB_SYSTEM_ALGORITHM                 := $(BOARD_AVB_ALGORITHM)
BOARD_AVB_SYSTEM_KEY_PATH                  := $(BOARD_AVB_KEY_PATH)
BOARD_AVB_SYSTEM_ROLLBACK_INDEX            := 0
BOARD_AVB_SYSTEM_ROLLBACK_INDEX_LOCATION   := 4
BOARD_AVB_VENDOR_ALGORITHM                 := $(BOARD_AVB_ALGORITHM)
BOARD_AVB_VENDOR_KEY_PATH                  := $(BOARD_AVB_KEY_PATH)
BOARD_AVB_VENDOR_ROLLBACK_INDEX            := 0
BOARD_AVB_VENDOR_ROLLBACK_INDEX_LOCATION   := 5
endif

# Assert
TARGET_OTA_ASSERT_DEVICE := quill,lanai

# Bluetooth
TARGET_VENDOR_PROP += device/nvidia/quill/bluetooth.prop

# Boot image
BOARD_MKBOOTIMG_ARGS := --header_version 1

# Kernel
ifeq ($(TARGET_PREBUILT_KERNEL),)
TARGET_KERNEL_PLATFORM_TARGET := tegra
TARGET_KERNEL_SOURCE          := vendor/nvidia/$(TARGET_KERNEL_PLATFORM_TARGET)
BOARD_KERNEL_IMAGE_NAME       := Image
endif

BOARD_KERNEL_CMDLINE          := firmware_class.path=/vendor/firmware cpufreq.default_governor=performance nouveau.atomic=1 cma=512MB 8250.nr_uarts=1 earlycon
include device/nvidia/quill/modules.mk

# Recovery
TARGET_RECOVERY_FSTAB    := device/nvidia/quill/initfiles/fstab.quill
TARGET_RECOVERY_PIXEL_FORMAT := BGRA_8888

# SELinux
BOARD_VENDOR_SEPOLICY_DIRS += device/nvidia/quill/sepolicy/vendor

# Security Patch Level
VENDOR_SECURITY_PATCH := 2024-12-05

include device/nvidia/t186-common/BoardConfigCommon.mk
