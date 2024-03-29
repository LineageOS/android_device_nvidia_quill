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

TARGET_TEGRA_BOOTCTRL ?= smd
TARGET_TEGRA_BT       ?= bcm btlinux
TARGET_TEGRA_CAMERA   ?= rel-shield-r
TARGET_TEGRA_KERNEL   ?= 4.9
TARGET_TEGRA_HEALTH   ?= nobattery
TARGET_TEGRA_KEYSTORE ?= software
TARGET_TEGRA_WIDEVINE ?= rel-shield-r
TARGET_TEGRA_WIFI     ?= bcm
TARGET_TEGRA_WIREGUARD ?= compat

include device/nvidia/t186-common/t186.mk

# System properties
include $(LOCAL_PATH)/system_prop.mk

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
PRODUCT_PACKAGES += \
    $(foreach model,$(TARGET_TEGRA_MODELS),fstab.$(model) init.$(model).rc init.recovery.$(model).rc power.$(model).rc) \
    init.quill_common.rc

# Permissions
PRODUCT_COPY_FILES += \
    frameworks/native/data/etc/android.hardware.audio.low_latency.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.audio.low_latency.xml \
    frameworks/native/data/etc/android.hardware.ethernet.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.ethernet.xml

# ATV specific stuff
ifeq ($(PRODUCT_IS_ATV),true)
    $(call inherit-product-if-exists, vendor/google/atv/atv-common.mk)

    PRODUCT_PACKAGES += \
        android.hardware.tv.input@1.0-impl
endif

# Audio
ifneq ($(filter rel-shield-r, $(TARGET_TEGRA_AUDIO)),)
PRODUCT_PACKAGES += \
    audio_effects.xml \
    audio_policy_configuration.xml \
    nvaudio_conf.xml \
    nvaudio_fx.xml
endif

# Kernel
ifneq ($(TARGET_PREBUILT_KERNEL),)
TARGET_FORCE_PREBUILT_KERNEL := true
endif

# Light
PRODUCT_PACKAGES += \
    android.hardware.light@2.0-service-nvidia

# Loadable kernel modules
PRODUCT_PACKAGES += \
    init.lkm.rc \
    lkm_loader \
    lkm_loader_target

# Media config
PRODUCT_COPY_FILES += \
    frameworks/av/media/libstagefright/data/media_codecs_google_audio.xml:$(TARGET_COPY_OUT_ODM)/etc/media_codecs_google_audio.xml \
    frameworks/av/media/libstagefright/data/media_codecs_google_video.xml:$(TARGET_COPY_OUT_ODM)/etc/media_codecs_google_video.xml
PRODUCT_PACKAGES += \
    media_codecs.xml
ifneq ($(filter rel-shield-r, $(TARGET_TEGRA_OMX)),)
PRODUCT_PACKAGES += \
    media_codecs_performance.xml \
    media_profiles_V1_0.xml \
    enctune.conf
endif

# NvPModel
PRODUCT_PACKAGES += \
    nvpmodel \
    nvpmodel_t186.conf \
    nvpmodel_t186_p3636.conf

# PHS
ifneq ($(TARGET_TEGRA_PHS),)
PRODUCT_PACKAGES += \
    nvphsd.conf
endif

# Thermal
PRODUCT_PACKAGES += \
    android.hardware.thermal@1.0-service-nvidia \
    $(foreach model,$(TARGET_TEGRA_MODELS),thermalhal.$(model).xml)

# Updater
ifneq ($(TARGET_TEGRA_BOOTCTRL),)
AB_OTA_PARTITIONS += \
    boot \
    recovery \
    system \
    vbmeta \
    vendor \
    odm
ifeq ($(TARGET_PREBUILT_KERNEL),)
ifeq ($(TARGET_TEGRA_BOOTCTRL),smd)
AB_OTA_POSTINSTALL_CONFIG += \
    FILESYSTEM_TYPE_system=ext4 \
    POSTINSTALL_OPTIONAL_system=true \
    POSTINSTALL_PATH_system=system/bin/nv_bootloader_payload_updater \
    RUN_POSTINSTALL_system=true
PRODUCT_PACKAGES += \
    nv_bootloader_payload_updater \
    bl_update_payload \
    bmp_update_payload
endif
endif
endif
