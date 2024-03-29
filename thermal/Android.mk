# Copyright (C) 2018 The LineageOS Project
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

LOCAL_PATH:= $(call my-dir)

# Parameters
# $1 Variant name
define thermal_config_rule
include $(CLEAR_VARS)
LOCAL_MODULE        := thermalhal.$(strip $(1)).xml
LOCAL_MODULE_TAGS   := optional
LOCAL_MODULE_CLASS  := ETC
LOCAL_SRC_FILES     := thermalhal.quill.xml
LOCAL_VENDOR_MODULE := true
include $(BUILD_PREBUILT)
endef
$(foreach model,$(TARGET_TEGRA_MODELS),$(eval $(call thermal_config_rule,$(model))))
