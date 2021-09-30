# Copyright (C) 2021 The LineageOS Project
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

TEGRAFLASH_PATH := $(BUILD_TOP)/vendor/nvidia/common/tegraflash
T186_BL         := $(BUILD_TOP)/vendor/nvidia/t186/bootloader
T186_FW         := $(BUILD_TOP)/vendor/nvidia/t186/firmware
QUILL_BCT       := $(BUILD_TOP)/vendor/nvidia/quill/BCT
QUILL_FLASH     := $(BUILD_TOP)/device/nvidia/quill/flash_package
COMMON_FLASH    := $(BUILD_TOP)/device/nvidia/tegra-common/flash_package

TNSPEC_PY    := $(BUILD_TOP)/vendor/nvidia/common/tegraflash/tnspec.py
QUILL_TNSPEC := $(BUILD_TOP)/device/nvidia/quill/tnspec/quill.json

INSTALLED_BMP_BLOB_TARGET      := $(PRODUCT_OUT)/bmp.blob
INSTALLED_CBOOT_TARGET         := $(PRODUCT_OUT)/cboot.bin
INSTALLED_KERNEL_TARGET        := $(PRODUCT_OUT)/kernel
INSTALLED_RECOVERYIMAGE_TARGET := $(PRODUCT_OUT)/recovery.img
INSTALLED_TOS_TARGET           := $(PRODUCT_OUT)/tos-mon-only.img

TOYBOX_HOST  := $(HOST_OUT_EXECUTABLES)/toybox
AWK_HOST     := $(HOST_OUT_EXECUTABLES)/one-true-awk
AVBTOOL_HOST := $(HOST_OUT_EXECUTABLES)/avbtool
SMD_GEN_HOST := $(HOST_OUT_EXECUTABLES)/nv_smd_generator

include $(CLEAR_VARS)
LOCAL_MODULE        := p2771_flash_package
LOCAL_MODULE_SUFFIX := .txz
LOCAL_MODULE_CLASS  := ETC
LOCAL_MODULE_PATH   := $(PRODUCT_OUT)

_p2771_package_intermediates := $(call intermediates-dir-for,$(LOCAL_MODULE_CLASS),$(LOCAL_MODULE))
_p2771_package_archive := $(_p2771_package_intermediates)/$(LOCAL_MODULE)$(LOCAL_MODULE_SUFFIX)

$(_p2771_package_archive): $(INSTALLED_BMP_BLOB_TARGET) $(INSTALLED_CBOOT_TARGET) $(INSTALLED_KERNEL_TARGET) $(INSTALLED_RECOVERYIMAGE_TARGET) $(INSTALLED_TOS_TARGET) $(AWK_HOST) $(TOYBOX_HOST) $(AVBTOOL_HOST) $(SMD_GEN_HOST)
	@mkdir -p $(dir $@)/tegraflash
	@mkdir -p $(dir $@)/scripts
	@cp $(TEGRAFLASH_PATH)/tegraflash* $(dir $@)/tegraflash/
	@cp $(TEGRAFLASH_PATH)/*_v2 $(dir $@)/tegraflash/
	@cp $(TEGRAFLASH_PATH)/sw_memcfg_overlay.pl $(dir $@)/tegraflash/
	@cp $(COMMON_FLASH)/*.sh $(dir $@)/scripts/
	@cp $(QUILL_FLASH)/p2771.sh $(dir $@)/flash.sh
	@cp $(QUILL_FLASH)/flash_android_t186.xml $(dir $@)/
	@cp $(T186_BL)/* $(dir $@)/
	@rm $(dir $@)/tos-mon-only.img
	@cp $(INSTALLED_TOS_TARGET) $(dir $@)/
	@cp $(T186_FW)/xusb/tegra18x_xusb_firmware $(dir $@)/xusb_sil_rel_fw
	@python2 $(TNSPEC_PY) nct new p2771-0000-devkit-c03 -o $(dir $@)/p2771-0000-devkit-c03.bin --spec $(QUILL_TNSPEC)
	@python2 $(TNSPEC_PY) nct new p2771-0000-devkit-c04 -o $(dir $@)/p2771-0000-devkit-c04.bin --spec $(QUILL_TNSPEC)
	@cp $(INSTALLED_BMP_BLOB_TARGET) $(dir $@)/
	@$(SMD_GEN_HOST) $(dir $@)/slot_metadata.bin
	@$(AVBTOOL_HOST) make_vbmeta_image --flags 2 --padding_size 256 --output $(dir $@)/vbmeta_skip.img
	@cp $(INSTALLED_CBOOT_TARGET) $(dir $@)/cboot.bin
	@cp $(INSTALLED_RECOVERYIMAGE_TARGET) $(dir $@)/
	@cp $(KERNEL_OUT)/arch/arm64/boot/dts/tegra186-quill-p3310-1000-c03-00-base.dtb $(dir $@)/
	@cp $(QUILL_BCT)/*3310* $(dir $@)/
	@cp $(QUILL_BCT)/emmc.cfg $(dir $@)/
	@cp $(QUILL_BCT)/*_scr.cfg $(dir $@)/
	@cp $(QUILL_BCT)/tegra186-mb1-bct-misc-si-l4t.cfg $(dir $@)/
	@echo "NV3" > $(dir $@)/emmc_bootblob_ver.txt
	@echo "# R17 , REVISION: 1" >> $(dir $@)/emmc_bootblob_ver.txt
	@echo "BOARDID=3310 BOARDSKU=1000 FAB=B02" >> $(dir $@)/emmc_bootblob_ver.txt
	@$(TOYBOX_HOST) date '+%Y%m%d%H%M%S' >> $(dir $@)/emmc_bootblob_ver.txt
	@$(TOYBOX_HOST) cksum $(dir $@)/emmc_bootblob_ver.txt |$(AWK_HOST) '{ print "BYTES:" $$2, "CRC32:" $$1 }' >> $(dir $@)/emmc_bootblob_ver.txt
	@$(TOYBOX_HOST) dd if=/dev/zero of=$(dir $@)/badpage_dummy.bin bs=4096 count=1
	@cd $(dir $@); tar -cJf $(abspath $@) *

include $(BUILD_SYSTEM)/base_rules.mk

include $(CLEAR_VARS)
LOCAL_MODULE        := p3636-p3509_flash_package
LOCAL_MODULE_SUFFIX := .txz
LOCAL_MODULE_CLASS  := ETC
LOCAL_MODULE_PATH   := $(PRODUCT_OUT)

_p3636-p3509_package_intermediates := $(call intermediates-dir-for,$(LOCAL_MODULE_CLASS),$(LOCAL_MODULE))
_p3636-p3509_package_archive := $(_p3636-p3509_package_intermediates)/$(LOCAL_MODULE)$(LOCAL_MODULE_SUFFIX)

$(_p3636-p3509_package_archive): $(INSTALLED_BMP_BLOB_TARGET) $(INSTALLED_CBOOT_TARGET) $(INSTALLED_KERNEL_TARGET) $(INSTALLED_RECOVERYIMAGE_TARGET) $(INSTALLED_TOS_TARGET) $(AWK_HOST) $(TOYBOX_HOST) $(AVBTOOL_HOST) $(SMD_GEN_HOST)
	@mkdir -p $(dir $@)/tegraflash
	@mkdir -p $(dir $@)/scripts
	@cp $(TEGRAFLASH_PATH)/tegraflash* $(dir $@)/tegraflash/
	@cp $(TEGRAFLASH_PATH)/*_v2 $(dir $@)/tegraflash/
	@cp $(TEGRAFLASH_PATH)/sw_memcfg_overlay.pl $(dir $@)/tegraflash/
	@cp $(COMMON_FLASH)/*.sh $(dir $@)/scripts/
	@cp $(QUILL_FLASH)/p3636-p3509.sh $(dir $@)/flash.sh
	@cp $(QUILL_FLASH)/flash_android_t186_p3636.xml $(dir $@)/
	@cp $(T186_BL)/* $(dir $@)/
	@rm $(dir $@)/tos-mon-only.img
	@cp $(INSTALLED_TOS_TARGET) $(dir $@)/
	@cp $(T186_FW)/xusb/tegra18x_xusb_firmware $(dir $@)/xusb_sil_rel_fw
	@python2 $(TNSPEC_PY) nct new p3636-0001-p3509 -o $(dir $@)/p3636-0001-p3509.bin --spec $(QUILL_TNSPEC)
	@cp $(INSTALLED_BMP_BLOB_TARGET) $(dir $@)/
	@$(SMD_GEN_HOST) $(dir $@)/slot_metadata.bin
	@$(AVBTOOL_HOST) make_vbmeta_image --flags 2 --padding_size 256 --output $(dir $@)/vbmeta_skip.img
	@cp $(INSTALLED_CBOOT_TARGET) $(dir $@)/cboot.bin
	@cp $(INSTALLED_RECOVERYIMAGE_TARGET) $(dir $@)/
	@cp $(KERNEL_OUT)/arch/arm64/boot/dts/tegra186-p3636-0001-p3509-0000-a01-android.dtb $(dir $@)/
	@cp $(QUILL_BCT)/*3636* $(dir $@)/
	@cp $(QUILL_BCT)/emmc.cfg $(dir $@)/
	@cp $(QUILL_BCT)/*_scr.cfg $(dir $@)/
	@cp $(QUILL_BCT)/tegra186-mb1-bct-misc-si-l4t.cfg $(dir $@)/
	@echo "NV3" > $(dir $@)/emmc_bootblob_ver.txt
	@echo "# R17 , REVISION: 1" >> $(dir $@)/emmc_bootblob_ver.txt
	@echo "BOARDID=3636 BOARDSKU=0001 FAB=A00" >> $(dir $@)/emmc_bootblob_ver.txt
	@$(TOYBOX_HOST) date '+%Y%m%d%H%M%S' >> $(dir $@)/emmc_bootblob_ver.txt
	@$(TOYBOX_HOST) cksum $(dir $@)/emmc_bootblob_ver.txt |$(AWK_HOST) '{ print "BYTES:" $$2, "CRC32:" $$1 }' >> $(dir $@)/emmc_bootblob_ver.txt
	@$(TOYBOX_HOST) dd if=/dev/zero of=$(dir $@)/badpage_dummy.bin bs=4096 count=1
	@cd $(dir $@); tar -cJf $(abspath $@) *

include $(BUILD_SYSTEM)/base_rules.mk
