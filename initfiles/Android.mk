LOCAL_PATH:= $(call my-dir)

# Parameters
# $1 Variant name
define initfiles_rule
include $(CLEAR_VARS)
LOCAL_MODULE           := fstab.$(strip $(1))
LOCAL_MODULE_CLASS     := ETC
LOCAL_SRC_FILES        := fstab.quill
LOCAL_VENDOR_MODULE    := true
include $(BUILD_PREBUILT)

include $(CLEAR_VARS)
LOCAL_MODULE               := init.$(strip $(1)).rc
LOCAL_MODULE_CLASS         := ETC
LOCAL_SRC_FILES            := init.$(strip $(1)).rc
LOCAL_VENDOR_MODULE        := true
LOCAL_MODULE_RELATIVE_PATH := init/hw
include $(BUILD_PREBUILT)

include $(CLEAR_VARS)
LOCAL_MODULE       := init.recovery.$(strip $(1)).rc
LOCAL_MODULE_CLASS := ETC
LOCAL_SRC_FILES    := init.recovery.quill.rc
LOCAL_MODULE_PATH  := $(TARGET_ROOT_OUT)
include $(BUILD_PREBUILT)

include $(CLEAR_VARS)
LOCAL_MODULE       := power.$(strip $(1)).rc
LOCAL_MODULE_CLASS := ETC
LOCAL_ODM_MODULE   := true
LOCAL_SRC_FILES    := power.quill.rc
include $(BUILD_PREBUILT)
endef
$(foreach model,$(TARGET_TEGRA_MODELS),$(eval $(call initfiles_rule,$(model))))

include $(CLEAR_VARS)
LOCAL_MODULE               := init.quill_common.rc
LOCAL_MODULE_CLASS         := ETC
LOCAL_SRC_FILES            := init.quill_common.rc
LOCAL_VENDOR_MODULE        := true
LOCAL_MODULE_RELATIVE_PATH := init/hw
include $(BUILD_PREBUILT)

include $(CLEAR_VARS)
LOCAL_MODULE        := lkm_loader_target
LOCAL_SRC_FILES     := lkm_loader_target.sh
LOCAL_MODULE_SUFFIX := .sh
LOCAL_MODULE_CLASS  := EXECUTABLES
LOCAL_VENDOR_MODULE := true
include $(BUILD_PREBUILT)
