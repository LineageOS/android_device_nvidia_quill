# Copyright (C) 2024 The LineageOS Project
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

QUILL_COMMS_L4T_BRANCH := r32
QUILL_COMMS_ANDROID_BRANCH := rel-shield-r
QUILL_BCM_L4T_PATH := vendor/nvidia/quill/$(QUILL_COMMS_L4T_BRANCH)/bcm
QUILL_BCM_ANDROID_PATH := vendor/nvidia/quill/$(QUILL_COMMS_ANDROID_BRANCH)/bcm

include device/nvidia/tegra-common/vendor/$(QUILL_COMMS_L4T_BRANCH)/realtek/rtl8822ce.mk
include device/nvidia/tegra-common/vendor/$(QUILL_COMMS_ANDROID_BRANCH)/bcm/bcm4354.mk

# Device specific bcm firmware
PRODUCT_COPY_FILES += \
    $(QUILL_BCM_L4T_PATH)/bcm4354/nvram_quill_4354.txt:$(TARGET_COPY_OUT_VENDOR)/firmware/nvram_quill_4354.txt \
    $(QUILL_BCM_ANDROID_PATH)/bcm4354/foster.clm_blob:$(TARGET_COPY_OUT_VENDOR)/firmware/bcmdhd_clm_4354.blob
