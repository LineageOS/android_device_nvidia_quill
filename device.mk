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

# Only include Shield apps for first party targets
ifneq ($(filter $(word 2,$(subst _, ,$(TARGET_PRODUCT))), quill quill_tab),)
include device/nvidia/shield-common/shield.mk
endif

TARGET_REFERENCE_DEVICE ?= quill
TARGET_TEGRA_VARIANT    ?= common

TARGET_TEGRA_MODELS := $(shell awk -F, '/tegra_init::devices/{ f = 1; next } /};/{ f = 0 } f{ gsub(/"/, "", $$3); gsub(/ /, "", $$3); print $$3 }' device/nvidia/$(TARGET_REFERENCE_DEVICE)/init/init_$(TARGET_REFERENCE_DEVICE).cpp |sort |uniq)

TARGET_KERNEL_VERSION ?= 6.12
TARGET_BOOT_HAL       ?= smd
TARGET_LIGHT_HAL      ?= tegra
TARGET_THERMAL_HAL    ?= tegra

TARGET_HAS_BATTERY    ?= false

include device/nvidia/t186-common/t186.mk

# System properties
include device/nvidia/quill/system_prop.mk

PRODUCT_CHARACTERISTICS   := tv
PRODUCT_AAPT_PREBUILT_DPI := xxhdpi xhdpi hdpi mdpi hdpi tvdpi
PRODUCT_AAPT_PREF_CONFIG  := xhdpi

$(call inherit-product, frameworks/native/build/tablet-10in-xhdpi-2048-dalvik-heap.mk)

include device/nvidia/quill/vendor/quill-vendor.mk

# Soong namespaces
PRODUCT_SOONG_NAMESPACES += device/nvidia/quill

# Overlays
DEVICE_PACKAGE_OVERLAYS += \
    device/nvidia/quill/overlay

# Init related
PRODUCT_COPY_FILES += \
    $(foreach model,$(TARGET_TEGRA_MODELS),device/nvidia/quill/initfiles/fstab.quill:$(TARGET_COPY_OUT_VENDOR)/etc/fstab.$(model)) \
    $(foreach model,$(TARGET_TEGRA_MODELS),device/nvidia/quill/initfiles/fstab.quill:$(TARGET_COPY_OUT_RAMDISK)/fstab.$(model)) \
    $(foreach model,$(TARGET_TEGRA_MODELS),device/nvidia/quill/initfiles/init.$(model).rc:$(TARGET_COPY_OUT_VENDOR)/etc/init/hw/init.$(model).rc) \
    $(foreach model,$(TARGET_TEGRA_MODELS),device/nvidia/quill/initfiles/init.recovery.quill.rc:$(TARGET_COPY_OUT_RECOVERY)/root/init.recovery.$(model).rc) \
    $(foreach model,$(TARGET_TEGRA_MODELS),device/nvidia/quill/initfiles/power.quill.rc:$(TARGET_COPY_OUT_ODM)/etc/power.$(model).rc) \
    device/nvidia/quill/initfiles/init.quill_common.rc:$(TARGET_COPY_OUT_VENDOR)/etc/init/hw/init.quill_common.rc

PRODUCT_PACKAGES += \
    symlink_data \
    symlink_data-rec.recovery

# Permissions
PRODUCT_COPY_FILES += \
    frameworks/native/data/etc/android.hardware.audio.low_latency.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.audio.low_latency.xml \
    frameworks/native/data/etc/android.hardware.ethernet.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.ethernet.xml

# Audio
ifeq ($(TARGET_AUDIO_HAL),baylibre)
PRODUCT_COPY_FILES += \
    device/nvidia/tegra-common/audio/primary_audio_policy_configuration.xml:$(TARGET_COPY_OUT_VENDOR)/etc/primary_audio_policy_configuration.xml
endif

# Fingerprint
PRODUCT_BUILD_PROP_OVERRIDES += \
    BuildFingerprint=NVIDIA/quill/quill:11/RQ1A.210105.003/13961456_3871.0251:user/release-keys

# Loadable kernel modules
PRODUCT_PACKAGES += \
    lkm_loader
PRODUCT_COPY_FILES += \
    device/nvidia/tegra-common/initfiles/init.lkm.rc:$(TARGET_COPY_OUT_VENDOR)/etc/init/hw/init.lkm.rc \
    device/nvidia/quill/initfiles/lkm.rc:$(TARGET_COPY_OUT_VENDOR)/etc/init/lkm.rc

# Power
ifeq ($(TARGET_POWER_HAL),perfmgr-lineage)
ifeq ($(TARGET_GRAPHICS),mesa)
PRODUCT_PACKAGES += \
    powerhint.nouveau.json
PRODUCT_PROPERTY_OVERRIDES += \
    vendor.powerhal.config=powerhint.nouveau.json
endif
endif

# Shipping API
PRODUCT_SHIPPING_API_LEVEL := 36
PRODUCT_VIRTUAL_AB_COW_VERSION := 2

# Thermal
ifeq ($(TARGET_THERMAL_HAL),tegra)
PRODUCT_COPY_FILES += \
    $(foreach model,$(TARGET_TEGRA_MODELS),device/nvidia/quill/thermal/thermalhal.quill.xml:$(TARGET_COPY_OUT_VENDOR)/etc/thermalhal.$(model).xml)
endif

# Trusted firmware
ATF_PATH ?= hardware/nvidia/t210/arm-trusted-firmware

# Updater
ifneq ($(TARGET_BOOT_HAL),)
AB_OTA_PARTITIONS += \
    boot \
    recovery \
    system \
    system_dlkm \
    vbmeta \
    vendor \
    odm
ifeq ($(TARGET_BOOT_HAL),smd)
AB_OTA_POSTINSTALL_CONFIG += \
    FILESYSTEM_TYPE_system=ext4 \
    POSTINSTALL_OPTIONAL_system=true \
    POSTINSTALL_PATH_system=system/bin/otapreopt_script \
    RUN_POSTINSTALL_system=true \
    FILESYSTEM_TYPE_vendor=ext4 \
    POSTINSTALL_OPTIONAL_vendor=true \
    POSTINSTALL_PATH_vendor=bin/nv_bootloader_payload_updater \
    RUN_POSTINSTALL_vendor=true
PRODUCT_PACKAGES += \
    nv_bootloader_payload_updater.vendor
endif
endif

PRODUCT_PACKAGES += \
    WifiOverlay
