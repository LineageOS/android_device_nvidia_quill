LOCAL_PATH:= $(call my-dir)

include $(CLEAR_VARS)
LOCAL_MODULE        := lkm_loader_target
LOCAL_SRC_FILES     := lkm_loader_target.sh
LOCAL_MODULE_SUFFIX := .sh
LOCAL_MODULE_CLASS  := EXECUTABLES
LOCAL_VENDOR_MODULE := true
include $(BUILD_PREBUILT)
