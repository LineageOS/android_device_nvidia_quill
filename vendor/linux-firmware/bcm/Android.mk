# Copyright (C) 2020 The LineageOS Project
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

LOCAL_PATH := $(call my-dir)
DOWNSTREAM_BRANCH      := rel-shield-r
L4T_BRANCH             := r35
COMMON_DOWNSTREAM_PATH := ../../../../../../vendor/nvidia/common/$(DOWNSTREAM_BRANCH)/bcm_firmware
QUILL_L4T_PATH         := ../../../../../../vendor/nvidia/quill/$(L4T_BRANCH)/bcm_firmware

include $(CLEAR_VARS)
LOCAL_MODULE               := bcm4350.hcd
LOCAL_SRC_FILES            := $(COMMON_DOWNSTREAM_PATH)/bcm4354/BCM4350C0.hcd
LOCAL_MODULE_CLASS         := ETC
LOCAL_MODULE_PATH          := $(TARGET_OUT_VENDOR)/firmware/brcm
LOCAL_MODULE_TAGS          := optional
LOCAL_MODULE_OWNER         := nvidia
LOCAL_MODULE_SYMLINKS      := BCM4354.nvidia,p2771-0000.hcd
include $(BUILD_PREBUILT)

include $(CLEAR_VARS)
LOCAL_MODULE               := nvram_quill_4354.txt
LOCAL_SRC_FILES            := $(QUILL_L4T_PATH)/bcm4354/nvram_quill_4354.txt
LOCAL_MODULE_CLASS         := ETC
LOCAL_MODULE_PATH          := $(TARGET_OUT_VENDOR)/firmware/brcm
LOCAL_MODULE_TAGS          := optional
LOCAL_MODULE_OWNER         := nvidia
LOCAL_MODULE_SYMLINKS      := brcmfmac4354-sdio.nvidia,p2771-0000.txt
include $(BUILD_PREBUILT)
