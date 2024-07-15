# Copyright (C) 2021-2024 The LineageOS Project
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

ifeq ($(TARGET_REFERENCE_DEVICE), quill)
TEGRAFLASH_PATH := $(BUILD_TOP)/vendor/nvidia/t186/r32/tegraflash
T186_BL         := $(BUILD_TOP)/vendor/nvidia/t186/r32/bootloader
T186_FW         := $(BUILD_TOP)/vendor/nvidia/t186/r32/firmware
QUILL_BL        := $(BUILD_TOP)/vendor/nvidia/quill/r32/bootloader
QUILL_BCT       := $(BUILD_TOP)/vendor/nvidia/quill/r32/BCT
QUILL_FLASH     := $(BUILD_TOP)/device/nvidia/quill/flash_package
COMMON_FLASH    := $(BUILD_TOP)/device/nvidia/tegra-common/flash_package

TNSPEC_PY    := $(BUILD_TOP)/vendor/nvidia/common/rel-24/tegraflash/tnspec.py
QUILL_TNSPEC := $(BUILD_TOP)/device/nvidia/quill/tnspec/quill.json

INSTALLED_BMP_BLOB_TARGET      := $(PRODUCT_OUT)/bmp.blob
INSTALLED_CBOOT_TARGET         := $(PRODUCT_OUT)/cboot.bin
INSTALLED_KERNEL_TARGET        := $(PRODUCT_OUT)/kernel
INSTALLED_RECOVERYIMAGE_TARGET := $(PRODUCT_OUT)/recovery.img
INSTALLED_TOS_TARGET           := $(PRODUCT_OUT)/tos-$(if $(filter software,$(TARGET_TEGRA_TOS)),mon-only,$(TARGET_TEGRA_TOS)).img

TOYBOX_HOST  := $(HOST_OUT_EXECUTABLES)/toybox
AWK_HOST     := $(HOST_OUT_EXECUTABLES)/one-true-awk
AVBTOOL_HOST := $(HOST_OUT_EXECUTABLES)/avbtool
SMD_GEN_HOST := $(HOST_OUT_EXECUTABLES)/nv_smd_generator

ifneq ($(TARGET_PREBUILT_KERNEL),)
DTB_PATH := $(dir $(TARGET_PREBUILT_KERNEL))
else ifneq ($(filter 4.9, $(TARGET_TEGRA_KERNEL)),)
DTB_PATH := $(abspath $(KERNEL_OUT)/arch/arm64/boot/dts)
else ifneq ($(findstring dtstree,$(TARGET_KERNEL_ADDITIONAL_FLAGS)),)
DTB_PATH := $(abspath $(KERNEL_OUT)/../lineage-oot/device-tree/platform/generic-dts/t18x/lineage)
else
DTB_PATH := $(abspath $(KERNEL_OUT)/arch/arm64/boot/dts/nvidia)
endif

_p2771_package_archive := $(call intermediates-dir-for,ETC,p2771_flash_package)/p2771_flash_package.txz

$(_p2771_package_archive): $(INSTALLED_BMP_BLOB_TARGET) $(INSTALLED_CBOOT_TARGET) $(INSTALLED_KERNEL_TARGET) $(INSTALLED_RECOVERYIMAGE_TARGET) $(INSTALLED_TOS_TARGET) $(AWK_HOST) $(TOYBOX_HOST) $(AVBTOOL_HOST) $(SMD_GEN_HOST)
	@mkdir -p $(dir $@)/tegraflash
	@mkdir -p $(dir $@)/scripts
	@cp $(TEGRAFLASH_PATH)/* $(dir $@)/tegraflash/
	@cp $(COMMON_FLASH)/*.sh $(dir $@)/scripts/
	@cp $(QUILL_FLASH)/p2771.sh $(dir $@)/flash.sh
	@LINEAGEVER=$(shell BUILD_TOP=$(abspath $(BUILD_TOP)) python $(COMMON_FLASH)/get_branch_name.py) && \
	$(TOYBOX_HOST) sed -i "s/REPLACEME/$${LINEAGEVER}/" $(dir $@)/flash.sh
	@cp $(QUILL_FLASH)/flash_android_t186.xml $(dir $@)/
	@cp $(T186_BL)/* $(dir $@)/
	@rm $(dir $@)/tos-mon-only.img
	@cp $(INSTALLED_TOS_TARGET) $(dir $@)/tos.img
	@cp $(T186_FW)/xusb/tegra18x_xusb_firmware $(dir $@)/xusb_sil_rel_fw
	@python2 $(TNSPEC_PY) nct new p2771-0000-devkit-c03 -o $(dir $@)/p2771-0000-devkit-c03.bin --spec $(QUILL_TNSPEC)
	@python2 $(TNSPEC_PY) nct new p2771-0000-devkit-c04 -o $(dir $@)/p2771-0000-devkit-c04.bin --spec $(QUILL_TNSPEC)
	@cp $(INSTALLED_BMP_BLOB_TARGET) $(dir $@)/
	@$(SMD_GEN_HOST) $(dir $@)/slot_metadata.bin
	@$(AVBTOOL_HOST) make_vbmeta_image --flags 2 --padding_size 256 --output $(dir $@)/vbmeta_skip.img
	@cp $(INSTALLED_CBOOT_TARGET) $(dir $@)/cboot.bin
	@cp $(INSTALLED_RECOVERYIMAGE_TARGET) $(dir $@)/
	@cp $(QUILL_BL)/tegra186-quill-p3310-1000-c03-00-base.dtb $(dir $@)/tegra186-quill-p3310-1000-c03-00-base-bl.dtb
	@cp $(DTB_PATH)/tegra186-quill-p3310-1000-c03-00-base.dtb $(dir $@)/
	@cp $(QUILL_BCT)/*3310* $(dir $@)/
	@cp $(QUILL_BCT)/emmc.cfg $(dir $@)/
	@cp $(QUILL_BCT)/*_scr.cfg $(dir $@)/
	@cp $(QUILL_BCT)/tegra186-mb1-bct-misc-si-l4t.cfg $(dir $@)/
	@$(TOYBOX_HOST) dd if=/dev/zero of=$(dir $@)/badpage_dummy.bin bs=4096 count=1
	@cd $(dir $@); tar -cJf $(abspath $@) *

$(PRODUCT_OUT)/p2771_flash_package.txz: $(_p2771_package_archive)
	$(hide) cp $< $@

.PHONY: p2771_flash_package
p2771_flash_package: $(PRODUCT_OUT)/p2771_flash_package.txz

_p3636-p3509_package_archive := $(call intermediates-dir-for,ETC,p3636-p3509_flash_package)/p3636-p3509_flash_package.txz

$(_p3636-p3509_package_archive): $(INSTALLED_BMP_BLOB_TARGET) $(INSTALLED_CBOOT_TARGET) $(INSTALLED_KERNEL_TARGET) $(INSTALLED_RECOVERYIMAGE_TARGET) $(INSTALLED_TOS_TARGET) $(AWK_HOST) $(TOYBOX_HOST) $(AVBTOOL_HOST) $(SMD_GEN_HOST)
	@mkdir -p $(dir $@)/tegraflash
	@mkdir -p $(dir $@)/scripts
	@cp $(TEGRAFLASH_PATH)/* $(dir $@)/tegraflash/
	@cp $(COMMON_FLASH)/*.sh $(dir $@)/scripts/
	@cp $(QUILL_FLASH)/p3636-p3509.sh $(dir $@)/flash.sh
	@LINEAGEVER=$(shell BUILD_TOP=$(abspath $(BUILD_TOP)) python $(COMMON_FLASH)/get_branch_name.py) && \
	$(TOYBOX_HOST) sed -i "s/REPLACEME/$${LINEAGEVER}/" $(dir $@)/flash.sh
	@cp $(QUILL_FLASH)/flash_android_t186_p3636.xml $(dir $@)/
	@cp $(QUILL_FLASH)/flash_android_t186_p3636-nodata.xml $(dir $@)/
	@cp $(T186_BL)/* $(dir $@)/
	@rm $(dir $@)/tos-mon-only.img
	@cp $(INSTALLED_TOS_TARGET) $(dir $@)/tos.img
	@cp $(T186_FW)/xusb/tegra18x_xusb_firmware $(dir $@)/xusb_sil_rel_fw
	@python2 $(TNSPEC_PY) nct new p3636-0001-p3509 -o $(dir $@)/p3636-0001-p3509.bin --spec $(QUILL_TNSPEC)
	@python2 $(TNSPEC_PY) nct new p3636-0001-p3509-nvme -o $(dir $@)/p3636-0001-p3509-nvme.bin --spec $(QUILL_TNSPEC)
	@cp $(INSTALLED_BMP_BLOB_TARGET) $(dir $@)/
	@$(SMD_GEN_HOST) $(dir $@)/slot_metadata.bin
	@$(AVBTOOL_HOST) make_vbmeta_image --flags 2 --padding_size 256 --output $(dir $@)/vbmeta_skip.img
	@cp $(INSTALLED_CBOOT_TARGET) $(dir $@)/cboot.bin
	@cp $(INSTALLED_RECOVERYIMAGE_TARGET) $(dir $@)/
	@cp $(QUILL_BL)/tegra186-p3636-0001-p3509-0000-a01.dtb $(dir $@)/tegra186-p3636-0001-p3509-0000-a01-bl.dtb
	@cp $(DTB_PATH)/tegra186-p3636-0001-p3509-0000-a01-android.dtb $(dir $@)/
	@cp $(QUILL_BCT)/*3636* $(dir $@)/
	@cp $(QUILL_BCT)/emmc.cfg $(dir $@)/
	@cp $(QUILL_BCT)/*_scr.cfg $(dir $@)/
	@cp $(QUILL_BCT)/tegra186-mb1-bct-misc-si-l4t.cfg $(dir $@)/
	@$(TOYBOX_HOST) dd if=/dev/zero of=$(dir $@)/badpage_dummy.bin bs=4096 count=1
	@cd $(dir $@); tar -cJf $(abspath $@) *

$(PRODUCT_OUT)/p3636-p3509_flash_package.txz: $(_p3636-p3509_package_archive)
	$(hide) cp $< $@

.PHONY: p3636-p3509_flash_package
p3636-p3509_flash_package: $(PRODUCT_OUT)/p3636-p3509_flash_package.txz


ifeq ($(word 2,$(subst _, ,$(TARGET_PRODUCT))),quill)
BUILT_TARGET_FILES_ZIPROOT := $(call intermediates-dir-for,PACKAGING,target_files)/$(TARGET_PRODUCT)-target_files
$(BUILT_TARGET_FILES_ZIPROOT).zip: $(BUILT_TARGET_FILES_ZIPROOT)/IMAGES/p2771_flash_package.txz $(BUILT_TARGET_FILES_ZIPROOT)/IMAGES/p3636-p3509_flash_package.txz

$(BUILT_TARGET_FILES_ZIPROOT)/IMAGES/p2771_flash_package.txz: $(BUILT_TARGET_FILES_ZIPROOT).zip.list $(PRODUCT_OUT)/p2771_flash_package.txz
	@mkdir -p $(dir $@)
	@cp $(PRODUCT_OUT)/p2771_flash_package.txz $@
	@echo $@ >> $(BUILT_TARGET_FILES_ZIPROOT).zip.list

$(BUILT_TARGET_FILES_ZIPROOT)/IMAGES/p3636-p3509_flash_package.txz: $(BUILT_TARGET_FILES_ZIPROOT).zip.list $(PRODUCT_OUT)/p3636-p3509_flash_package.txz
	@mkdir -p $(dir $@)
	@cp $(PRODUCT_OUT)/p3636-p3509_flash_package.txz $@
	@echo $@ >> $(BUILT_TARGET_FILES_ZIPROOT).zip.list
endif
endif
