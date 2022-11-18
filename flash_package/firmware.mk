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

TEGRAFLASH_PATH := $(BUILD_TOP)/vendor/nvidia/common/r35/tegraflash
T186_BL         := $(BUILD_TOP)/vendor/nvidia/t186/r32/bootloader
QUILL_BCT       := $(BUILD_TOP)/vendor/nvidia/quill/r32/BCT
QUILL_FLASH     := $(BUILD_TOP)/device/nvidia/quill/flash_package

INSTALLED_CBOOT_TARGET  := $(PRODUCT_OUT)/cboot.bin
INSTALLED_KERNEL_TARGET := $(PRODUCT_OUT)/kernel
INSTALLED_TOS_TARGET    := $(PRODUCT_OUT)/tos-mon-only.img

TOYBOX_HOST := $(HOST_OUT_EXECUTABLES)/toybox

include $(CLEAR_VARS)
LOCAL_MODULE               := bl_update_payload
LOCAL_MODULE_CLASS         := ETC
LOCAL_MODULE_RELATIVE_PATH := firmware

_quill_blob_intermediates := $(call intermediates-dir-for,$(LOCAL_MODULE_CLASS),$(LOCAL_MODULE))
_quill_blob := $(_quill_blob_intermediates)/$(LOCAL_MODULE)$(LOCAL_MODULE_SUFFIX)

LANAI_SIGNED_PATH     := $(_quill_blob_intermediates)/p3636-p3509-signed
QUILL_C03_SIGNED_PATH := $(_quill_blob_intermediates)/p2771-c03-signed
QUILL_C04_SIGNED_PATH := $(_quill_blob_intermediates)/p2771-c04-signed

_lanai_br_bct     := $(LANAI_SIGNED_PATH)/br_bct_BR.bct
_quill_c03_br_bct := $(QUILL_C03_SIGNED_PATH)/br_bct_BR.bct
_quill_c04_br_bct := $(QUILL_C04_SIGNED_PATH)/br_bct_BR.bct

$(_lanai_br_bct): $(TOYBOX_HOST) $(INSTALLED_CBOOT_TARGET) $(INSTALLED_KERNEL_TARGET) $(INSTALLED_TOS_TARGET)
	@mkdir -p $(dir $@)
	@cp $(QUILL_FLASH)/flash_android_t186_p3636.xml $(dir $@)/flash_android_t186.xml.tmp
	@cp $(T186_BL)/* $(dir $@)/
	@rm $(dir $@)/tos-mon-only.img
	@cp $(INSTALLED_TOS_TARGET) $(dir $@)/
	@cp $(INSTALLED_CBOOT_TARGET) $(dir $@)/cboot.bin
	@cp $(QUILL_BCT)/tegra186-bpmp-p3636-0001-a00-00.dtb $(dir $@)/
	@cp $(KERNEL_OUT)/arch/arm64/boot/dts/tegra186-p3636-0001-p3509-0000-a01-android.dtb $(dir $@)/
	@$(TOYBOX_HOST) dd if=/dev/zero of=$(dir $@)/badpage_dummy.bin bs=4096 count=1
	cd $(dir $@); $(TEGRAFLASH_PATH)/tegraparser_v2 --pt flash_android_t186.xml.tmp
	cd $(dir $@); $(TEGRAFLASH_PATH)/tegrahost_v2 --chip 0x18 0 --partitionlayout flash_android_t186.xml.bin --list images_list.xml zerosbk
	cd $(dir $@); $(TEGRAFLASH_PATH)/tegrasign_v2 --key None --list images_list.xml --pubkeyhash pub_key.key
	cd $(dir $@); $(TEGRAFLASH_PATH)/tegrabct_v2 --dev_param $(QUILL_BCT)/emmc.cfg --sdram $(QUILL_BCT)/tegra186-mb1-bct-memcfg-p3636-0001-a01.cfg --brbct br_bct.cfg --chip 0x18 0
	cd $(dir $@); $(TEGRAFLASH_PATH)/tegrabct_v2 --brbct br_bct_BR.bct --chip 0x18 0 --updateblinfo flash_android_t186.xml.bin --updatesig images_list_signed.xml
	cd $(dir $@); $(TEGRAFLASH_PATH)/tegrabct_v2 --brbct br_bct_BR.bct --chip 0x18 --updatesmdinfo flash_android_t186.xml.bin
	cd $(dir $@); $(TEGRAFLASH_PATH)/tegraparser_v2 --chip 0x18 --updatecustinfo br_bct_BR.bct
	cd $(dir $@); $(TEGRAFLASH_PATH)/tegrabct_v2 --brbct br_bct_BR.bct --chip 0x18 0 --updatefields "Odmdata =0x2090000"
	cd $(dir $@); $(TEGRAFLASH_PATH)/tegrabct_v2 --brbct br_bct_BR.bct --chip 0x18 0 --listbct bct_list.xml
	cd $(dir $@); $(TEGRAFLASH_PATH)/tegrasign_v2 --key None --list bct_list.xml --pubkeyhash pub_key.key
	cd $(dir $@); $(TEGRAFLASH_PATH)/tegrabct_v2 --brbct br_bct_BR.bct --chip 0x18 0 --updatesig bct_list_signed.xml
	cd $(dir $@); $(TEGRAFLASH_PATH)/tegrabct_v2 --chip 0x18 0 --mb1bct mb1_cold_boot_bct.cfg --sdram $(QUILL_BCT)/tegra186-mb1-bct-memcfg-p3636-0001-a01.cfg --misc $(QUILL_BCT)/tegra186-mb1-bct-misc-si-l4t.cfg --scr $(QUILL_BCT)/mobile_scr.cfg --pinmux $(QUILL_BCT)/tegra186-mb1-bct-pinmux-p3636-0001-a00.cfg --pmc $(QUILL_BCT)/tegra186-mb1-bct-pad-p3636-0001-a00.cfg --pmic $(QUILL_BCT)/tegra186-mb1-bct-pmic-p3636-0001-a00.cfg --brcommand $(QUILL_BCT)/tegra186-mb1-bct-bootrom-p3636-0001-a00.cfg --prod $(QUILL_BCT)/tegra186-mb1-bct-prod-p3636-0001-a00.cfg
	cd $(dir $@); $(TEGRAFLASH_PATH)/tegrabct_v2 --chip 0x18 --mb1bct mb1_cold_boot_bct_MB1.bct --updatefwinfo flash_android_t186.xml.bin
	cd $(dir $@); $(TEGRAFLASH_PATH)/tegrabct_v2 --chip 0x18 --mb1bct mb1_cold_boot_bct_MB1.bct --updatestorageinfo flash_android_t186.xml.bin
	cd $(dir $@); $(TEGRAFLASH_PATH)/tegraflash.py --chip 0x18 --cmd "sign mb1_cold_boot_bct_MB1.bct"
	cd $(dir $@); $(TEGRAFLASH_PATH)/tegrahost_v2 --chip 0x18 0 --partitionlayout flash_android_t186.xml.bin --updatesig images_list_signed.xml

$(_quill_c03_br_bct): $(TOYBOX_HOST) $(INSTALLED_CBOOT_TARGET) $(INSTALLED_KERNEL_TARGET) $(INSTALLED_TOS_TARGET)
	@mkdir -p $(dir $@)
	@cp $(QUILL_FLASH)/flash_android_t186.xml $(dir $@)/flash_android_t186.xml.tmp
	@cp $(T186_BL)/* $(dir $@)/
	@cp $(INSTALLED_CBOOT_TARGET) $(dir $@)/cboot.bin
	@rm $(dir $@)/tos-mon-only.img
	@cp $(INSTALLED_TOS_TARGET) $(dir $@)/
	@cp $(QUILL_BCT)/tegra186-a02-bpmp-quill-p3310-1000-c01-00-te770d-ucm2.dtb $(dir $@)/tegra186-a02-bpmp-quill-p3310-1000.dtb
	@cp $(KERNEL_OUT)/arch/arm64/boot/dts/tegra186-quill-p3310-1000-c03-00-base.dtb $(dir $@)/
	@$(TOYBOX_HOST) dd if=/dev/zero of=$(dir $@)/badpage_dummy.bin bs=4096 count=1
	cd $(dir $@); $(TEGRAFLASH_PATH)/tegraparser_v2 --pt flash_android_t186.xml.tmp
	cd $(dir $@); $(TEGRAFLASH_PATH)/tegrahost_v2 --chip 0x18 0 --partitionlayout flash_android_t186.xml.bin --list images_list.xml zerosbk
	cd $(dir $@); $(TEGRAFLASH_PATH)/tegrasign_v2 --key None --list images_list.xml --pubkeyhash pub_key.key
	cd $(dir $@); $(TEGRAFLASH_PATH)/tegrabct_v2 --chip 0x18 0 --mb1bct mb1_cold_boot_bct.cfg --sdram $(QUILL_BCT)/P3310_A00_8GB_lpddr4_A02_l4t.cfg --misc $(QUILL_BCT)/tegra186-mb1-bct-misc-si-l4t.cfg --scr $(QUILL_BCT)/mobile_scr.cfg --pinmux $(QUILL_BCT)/tegra186-mb1-bct-pinmux-quill-p3310-1000-c03.cfg --pmc $(QUILL_BCT)/tegra186-mb1-bct-pad-quill-p3310-1000-c03.cfg --pmic $(QUILL_BCT)/tegra186-mb1-bct-pmic-quill-p3310-1000-c03.cfg --brcommand $(QUILL_BCT)/tegra186-mb1-bct-bootrom-quill-p3310-1000-c03.cfg --prod $(QUILL_BCT)/tegra186-mb1-bct-prod-quill-p3310-1000-c03.cfg
	cd $(dir $@); $(TEGRAFLASH_PATH)/tegrabct_v2 --chip 0x18 --mb1bct mb1_cold_boot_bct_MB1.bct --updatefwinfo flash_android_t186.xml.bin
	cd $(dir $@); $(TEGRAFLASH_PATH)/tegrabct_v2 --chip 0x18 --mb1bct mb1_cold_boot_bct_MB1.bct --updatestorageinfo flash_android_t186.xml.bin
	cd $(dir $@); $(TEGRAFLASH_PATH)/tegraflash.py --chip 0x18 --cmd "sign mb1_cold_boot_bct_MB1.bct"

$(_quill_c04_br_bct): $(TOYBOX_HOST) $(INSTALLED_CBOOT_TARGET) $(INSTALLED_KERNEL_TARGET) $(INSTALLED_TOS_TARGET)
	@mkdir -p $(dir $@)
	@cp $(QUILL_FLASH)/flash_android_t186.xml $(dir $@)/flash_android_t186.xml.tmp
	@cp $(T186_BL)/* $(dir $@)/
	@cp $(INSTALLED_CBOOT_TARGET) $(dir $@)/cboot.bin
	@rm $(dir $@)/tos-mon-only.img
	@cp $(INSTALLED_TOS_TARGET) $(dir $@)/
	@cp $(QUILL_BCT)/tegra186-a02-bpmp-quill-p3310-1000-c04-00-te770d-ucm2.dtb $(dir $@)/tegra186-a02-bpmp-quill-p3310-1000.dtb
	@cp $(KERNEL_OUT)/arch/arm64/boot/dts/tegra186-quill-p3310-1000-c03-00-base.dtb $(dir $@)/
	@$(TOYBOX_HOST) dd if=/dev/zero of=$(dir $@)/badpage_dummy.bin bs=4096 count=1
	cd $(dir $@); $(TEGRAFLASH_PATH)/tegraparser_v2 --pt flash_android_t186.xml.tmp
	cd $(dir $@); $(TEGRAFLASH_PATH)/tegrahost_v2 --chip 0x18 0 --partitionlayout flash_android_t186.xml.bin --list images_list.xml zerosbk
	cd $(dir $@); $(TEGRAFLASH_PATH)/tegrasign_v2 --key None --list images_list.xml --pubkeyhash pub_key.key
	cd $(dir $@); $(TEGRAFLASH_PATH)/tegrabct_v2 --dev_param $(QUILL_BCT)/emmc.cfg --sdram $(QUILL_BCT)/P3310_A00_8GB_lpddr4_A02_l4t.cfg --brbct br_bct.cfg --chip 0x18 0
	cd $(dir $@); $(TEGRAFLASH_PATH)/tegrabct_v2 --brbct br_bct_BR.bct --chip 0x18 0 --updateblinfo flash_android_t186.xml.bin --updatesig images_list_signed.xml
	cd $(dir $@); $(TEGRAFLASH_PATH)/tegrabct_v2 --brbct br_bct_BR.bct --chip 0x18 --updatesmdinfo flash_android_t186.xml.bin
	cd $(dir $@); $(TEGRAFLASH_PATH)/tegraparser_v2 --chip 0x18 --updatecustinfo br_bct_BR.bct
	cd $(dir $@); $(TEGRAFLASH_PATH)/tegrabct_v2 --brbct br_bct_BR.bct --chip 0x18 0 --updatefields "Odmdata =0x1098000"
	cd $(dir $@); $(TEGRAFLASH_PATH)/tegrabct_v2 --brbct br_bct_BR.bct --chip 0x18 0 --listbct bct_list.xml
	cd $(dir $@); $(TEGRAFLASH_PATH)/tegrasign_v2 --key None --list bct_list.xml --pubkeyhash pub_key.key
	cd $(dir $@); $(TEGRAFLASH_PATH)/tegrabct_v2 --brbct br_bct_BR.bct --chip 0x18 0 --updatesig bct_list_signed.xml
	cd $(dir $@); $(TEGRAFLASH_PATH)/tegrabct_v2 --chip 0x18 0 --mb1bct mb1_cold_boot_bct.cfg --sdram $(QUILL_BCT)/P3310_A00_8GB_lpddr4_A02_l4t.cfg --misc $(QUILL_BCT)/tegra186-mb1-bct-misc-si-l4t.cfg --scr $(QUILL_BCT)/mobile_scr.cfg --pinmux $(QUILL_BCT)/tegra186-mb1-bct-pinmux-quill-p3310-1000-c03.cfg --pmc $(QUILL_BCT)/tegra186-mb1-bct-pad-quill-p3310-1000-c03.cfg --pmic $(QUILL_BCT)/tegra186-mb1-bct-pmic-quill-p3310-1000-c04.cfg --brcommand $(QUILL_BCT)/tegra186-mb1-bct-bootrom-quill-p3310-1000-c03.cfg --prod $(QUILL_BCT)/tegra186-mb1-bct-prod-quill-p3310-1000-c03.cfg
	cd $(dir $@); $(TEGRAFLASH_PATH)/tegrabct_v2 --chip 0x18 --mb1bct mb1_cold_boot_bct_MB1.bct --updatefwinfo flash_android_t186.xml.bin
	cd $(dir $@); $(TEGRAFLASH_PATH)/tegrabct_v2 --chip 0x18 --mb1bct mb1_cold_boot_bct_MB1.bct --updatestorageinfo flash_android_t186.xml.bin
	cd $(dir $@); $(TEGRAFLASH_PATH)/tegraflash.py --chip 0x18 --cmd "sign mb1_cold_boot_bct_MB1.bct"
	cd $(dir $@); $(TEGRAFLASH_PATH)/tegrahost_v2 --chip 0x18 0 --partitionlayout flash_android_t186.xml.bin --updatesig images_list_signed.xml

$(_quill_blob): $(_lanai_br_bct) $(_quill_c03_br_bct) $(_quill_c04_br_bct) $(INSTALLED_KERNEL_TARGET)
	@mkdir -p $(dir $@)
	OUT=$(dir $@) TOP=$(BUILD_TOP) python2 $(TEGRAFLASH_PATH)/BUP_generator.py -t update -e \
		"$(QUILL_C04_SIGNED_PATH)/spe_sigheader.bin.encrypt spe-fw 2 0 common; \
		 $(QUILL_C04_SIGNED_PATH)/nvtboot_sigheader.bin.encrypt mb2 2 0 common; \
		 $(QUILL_C04_SIGNED_PATH)/cboot_sigheader.bin.encrypt cpu-bootloader 2 0 common; \
		 $(QUILL_C04_SIGNED_PATH)/tos-mon-only_sigheader.img.encrypt secure-os 2 0 common; \
		 $(QUILL_C04_SIGNED_PATH)/bpmp_sigheader.bin.encrypt bpmp-fw 2 0 common; \
		 $(QUILL_C04_SIGNED_PATH)/adsp-fw_sigheader.bin.encrypt adsp-fw 2 0 common; \
		 $(QUILL_C04_SIGNED_PATH)/camera-rtcpu-sce_sigheader.img.encrypt sce-fw 2 0 common; \
		 $(QUILL_C04_SIGNED_PATH)/preboot_d15_prod_cr_sigheader.bin.encrypt mts-preboot 2 2 common; \
		 $(QUILL_C04_SIGNED_PATH)/mce_mts_d15_prod_cr_sigheader.bin.encrypt mts-bootpack 2 2 common; \
		 $(QUILL_C04_SIGNED_PATH)/warmboot_wbheader_aligned.bin.encrypt sc7 2 2 common; \
		 $(QUILL_C04_SIGNED_PATH)/mb1_prod_aligned.bin.encrypt mb1 2 2 common; \
		 $(QUILL_C03_SIGNED_PATH)/tegra186-a02-bpmp-quill-p3310-1000_sigheader.dtb.encrypt bpmp-fw-dtb 2 0 P2771-0000-DEVKIT-C03.default; \
		 $(QUILL_C04_SIGNED_PATH)/tegra186-quill-p3310-1000-c03-00-base_sigheader.dtb.encrypt bootloader-dtb 2 0 P2771-0000-DEVKIT-C03.default; \
		 $(KERNEL_OUT)/arch/arm64/boot/dts/tegra186-quill-p3310-1000-c03-00-base.dtb kernel-dtb 2 0 P2771-0000-DEVKIT-C03.default; \
		 $(QUILL_C04_SIGNED_PATH)/br_bct_BR.bct BCT 2 2 P2771-0000-DEVKIT-C03.default; \
		 $(QUILL_C03_SIGNED_PATH)/mb1_cold_boot_bct_MB1_sigheader.bct.encrypt MB1_BCT 2 0 P2771-0000-DEVKIT-C03.default; \
		 $(QUILL_C04_SIGNED_PATH)/tegra186-a02-bpmp-quill-p3310-1000_sigheader.dtb.encrypt bpmp-fw-dtb 2 0 P2771-0000-DEVKIT-C04.default; \
		 $(QUILL_C04_SIGNED_PATH)/tegra186-quill-p3310-1000-c03-00-base_sigheader.dtb.encrypt bootloader-dtb 2 0 P2771-0000-DEVKIT-C04.default; \
		 $(KERNEL_OUT)/arch/arm64/boot/dts/tegra186-quill-p3310-1000-c03-00-base.dtb kernel-dtb 2 0 P2771-0000-DEVKIT-C04.default; \
		 $(QUILL_C04_SIGNED_PATH)/br_bct_BR.bct BCT 2 2 P2771-0000-DEVKIT-C04.default; \
		 $(QUILL_C04_SIGNED_PATH)/mb1_cold_boot_bct_MB1_sigheader.bct.encrypt MB1_BCT 2 0 P2771-0000-DEVKIT-C04.default; \
		 $(LANAI_SIGNED_PATH)/tegra186-bpmp-p3636-0001-a00-00_sigheader.dtb.encrypt bpmp-fw-dtb 2 0 P3636-0001-P3509.default; \
		 $(LANAI_SIGNED_PATH)/tegra186-p3636-0001-p3509-0000-a01-android_sigheader.dtb.encrypt bootloader-dtb 2 0 P3636-0001-P3509.default; \
		 $(KERNEL_OUT)/arch/arm64/boot/dts/tegra186-p3636-0001-p3509-0000-a01-android.dtb kernel-dtb 2 0 P3636-0001-P3509.default; \
		 $(LANAI_SIGNED_PATH)/br_bct_BR.bct BCT 2 2 P3636-0001-P3509.default; \
		 $(LANAI_SIGNED_PATH)/mb1_cold_boot_bct_MB1_sigheader.bct.encrypt MB1_BCT 2 0 P3636-0001-P3509.default"
	@mv $(dir $@)/ota.blob $@

include $(BUILD_SYSTEM)/base_rules.mk

include $(CLEAR_VARS)
LOCAL_MODULE               := bmp_update_payload
LOCAL_MODULE_STEM          := bmp.blob
LOCAL_MODULE_CLASS         := ETC
LOCAL_MODULE_RELATIVE_PATH := firmware

INSTALLED_BMP_BLOB_TARGET := $(PRODUCT_OUT)/bmp.blob

_bmp_blob_intermediates := $(call intermediates-dir-for,$(LOCAL_MODULE_CLASS),$(LOCAL_MODULE))
_bmp_blob := $(_bmp_blob_intermediates)/$(LOCAL_MODULE_STEM)

$(_bmp_blob): $(INSTALLED_BMP_BLOB_TARGET)
	@mkdir -p $(dir $@)
	@cp $(INSTALLED_BMP_BLOB_TARGET) $@

include $(BUILD_SYSTEM)/base_rules.mk
