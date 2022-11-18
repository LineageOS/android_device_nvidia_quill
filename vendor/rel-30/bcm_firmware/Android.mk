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

# Purposefully unguarded, these are not available in any other supported branch
LOCAL_PATH := $(call my-dir)
REL30_BCM_PATH := ../../../../../../vendor/nvidia/quill/rel-30/bcm_firmware

include $(CLEAR_VARS)
LOCAL_MODULE               := bcmdhd_clm_4354
LOCAL_SRC_FILES            := $(REL30_BCM_PATH)/bcm4354/foster.clm_blob
LOCAL_MODULE_SUFFIX        := .blob
LOCAL_MODULE_CLASS         := ETC
LOCAL_MODULE_PATH          := $(TARGET_OUT_VENDOR)/firmware
LOCAL_MODULE_TAGS          := optional
LOCAL_MODULE_OWNER         := nvidia
include $(BUILD_NVIDIA_PREBUILT)
