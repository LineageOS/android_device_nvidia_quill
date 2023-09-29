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

TEGRAFLASH_PATH := $(BUILD_TOP)/vendor/nvidia/t186/r32/tegraflash
TEGRAFLASH_R35  := $(BUILD_TOP)/vendor/nvidia/common/r35/tegraflash
T186_BL         := $(BUILD_TOP)/vendor/nvidia/t186/r32/bootloader
QUILL_BCT       := $(BUILD_TOP)/vendor/nvidia/quill/r32/BCT
QUILL_FLASH     := $(BUILD_TOP)/device/nvidia/quill/flash_package

INSTALLED_CBOOT_TARGET  := $(PRODUCT_OUT)/cboot.bin
INSTALLED_KERNEL_TARGET := $(PRODUCT_OUT)/kernel
INSTALLED_TOS_TARGET    := $(PRODUCT_OUT)/tos-mon-only.img

TOYBOX_HOST  := $(HOST_OUT_EXECUTABLES)/toybox
SMD_GEN_HOST := $(HOST_OUT_EXECUTABLES)/nv_smd_generator

LINEAGEVER := $(shell python $(COMMON_FLASH)/get_branch_name.py)

KERNEL_OUT ?= $(PRODUCT_OUT)/obj/KERNEL_OBJ

ifneq ($(TARGET_TEGRA_KERNEL),4.9)
DTB_SUBFOLDER := nvidia/
endif

include $(CLEAR_VARS)
LOCAL_MODULE               := bl_update_payload
LOCAL_MODULE_CLASS         := ETC
LOCAL_MODULE_RELATIVE_PATH := firmware

_quill_blob_intermediates := $(call intermediates-dir-for,$(LOCAL_MODULE_CLASS),$(LOCAL_MODULE))
_quill_blob := $(_quill_blob_intermediates)/$(LOCAL_MODULE)$(LOCAL_MODULE_SUFFIX)

P2771-C03_SIGNED_PATH   := $(_quill_blob_intermediates)/p2771-c03-signed
P2771-C04_SIGNED_PATH   := $(_quill_blob_intermediates)/p2771-c04-signed
P3636-P3509_SIGNED_PATH := $(_quill_blob_intermediates)/p3636-p3509-signed

_p2771-c03_br_bct   := $(P2771-C03_SIGNED_PATH)/br_bct_BR.bct
_p2771-c04_br_bct   := $(P2771-C04_SIGNED_PATH)/br_bct_BR.bct
_p3636-p3509_br_bct := $(P3636-P3509_SIGNED_PATH)/br_bct_BR.bct

# Parameters
# $1  Intermediates path
# $2  Partition xml
# $3  BPMP dtb
# $4  Kernel dtb
# $5  ODM data
# $6  Sdram config
# $7  Pinmux config
# $8  Pmic config
# $9  Pmc config
# $10 Prod config
# $11 Br cmd config
# $12 Module board id
# $13 Module sku
define t186_bl_signing_rule
$(strip $1)/br_bct_BR.bct: $(INSTALLED_KERNEL_TARGET) $(INSTALLED_CBOOT_TARGET) $(INSTALLED_TOS_TARGET) $(TOYBOX_HOST) $(SMD_GEN_HOST)
	@mkdir -p $(strip $1)
	@cp $(QUILL_FLASH)/$(strip $2) $(strip $1)/
	@cp $(T186_BL)/* $(strip $1)/
	@cp $(INSTALLED_CBOOT_TARGET) $(strip $1)/cboot.bin
	@rm $(strip $1)/tos-mon-only.img
	@cp $(INSTALLED_TOS_TARGET) $(strip $1)/tos-mon-only.img
	@cp $(QUILL_BCT)/$(strip $3) $(strip $1)/tegra186-bpmp.dtb
	@cp $(KERNEL_OUT)/arch/arm64/boot/dts/$(DTB_SUBFOLDER)$(strip $4) $(strip $1)/
	echo "NV3" > $(strip $1)/emmc_bootblob_ver.txt
	echo "# R$(word 1,$(subst ., ,$(LINEAGEVER))) , REVISION: $(word 2,$(subst ., ,$(LINEAGEVER)))" >> $(strip $1)/emmc_bootblob_ver.txt
	echo "BOARDID=$(strip $(12)) BOARDSKU=$(strip $(13)) FAB=" >> $(strip $1)/emmc_bootblob_ver.txt
	$(TOYBOX_HOST) date '+%Y%m%d%H%M%S' >> $(strip $1)/emmc_bootblob_ver.txt
	python -c 'import zlib; print("%X"%(zlib.crc32(open("'"$(strip $1)/emmc_bootblob_ver.txt"'", "rb").read()) & 0xFFFFFFFF))' > $(strip $1)/crc.txt
	wc -c < $(strip $1)/emmc_bootblob_ver.txt | tr -d '\n' > $(strip $1)/bytes.txt
	echo -n "BYTES:" >> $(strip $1)/emmc_bootblob_ver.txt
	cat $(strip $1)/bytes.txt >> $(strip $1)/emmc_bootblob_ver.txt
	echo -n " CRC32:" >> $(strip $1)/emmc_bootblob_ver.txt
	cat $(strip $1)/crc.txt >> $(strip $1)/emmc_bootblob_ver.txt
	sed -i '/bmp\.blob/d' $(strip $1)/$(strip $(2))
	sed -i '/p[0-9]\{4\}.*bin/d' $(strip $1)/$(strip $(2))
	sed -i '/recovery\.img/d' $(strip $1)/$(strip $(2))
	sed -i '/vbmeta_skip\.img/d' $(strip $1)/$(strip $(2))
	@$(SMD_GEN_HOST) $(strip $(1))/slot_metadata.bin
	@$(TOYBOX_HOST) dd if=/dev/zero of=$(strip $1)/badpage_dummy.bin bs=4096 count=1
	cd $(strip $1); PYTHONDONTWRITEBYTECODE=1 $(TEGRAFLASH_PATH)/tegraflash.py \
		--chip 0x18 \
		--bl $(strip $(1))/nvtboot_recovery_cpu.bin \
		--applet $(strip $(1))/mb1_recovery_prod.bin \
		--cmd "sign" \
		--cfg $(strip $(1))/$(strip $(2)) \
		--odmdata $(strip $(5)) \
		--sdram_config $(QUILL_BCT)/$(strip $(6)) \
		--misc_config $(QUILL_BCT)/tegra186-mb1-bct-misc-si-l4t.cfg \
		--pinmux_config $(QUILL_BCT)/$(strip $(7)) \
		--pmic_config $(QUILL_BCT)/$(strip $(8)) \
		--pmc_config $(QUILL_BCT)/$(strip $(9)) \
		--prod_config $(QUILL_BCT)/$(strip $(10)) \
		--scr_config $(QUILL_BCT)/minimal_scr.cfg \
		--scr_cold_boot_config $(QUILL_BCT)/mobile_scr.cfg \
		--br_cmd_config $(QUILL_BCT)/$(strip $(11)) \
		--dev_params $(QUILL_BCT)/emmc.cfg
	@mv $(strip $1)/signed/* $(strip $1)/
endef

# $1 Intermediates path
# $2 Bpmp dtb fab
# $3 Pmic fab
define p2771_bl_signing_rule
$(call t186_bl_signing_rule, \
  $(strip $(1)), \
  flash_android_t186.xml, \
  tegra186-a02-bpmp-quill-p3310-1000-$(strip $(2))-00-te770d-ucm2.dtb, \
  tegra186-quill-p3310-1000-c03-00-base.dtb, \
  0x1098000, \
  P3310_A00_8GB_lpddr4_A02_l4t.cfg, \
  tegra186-mb1-bct-pinmux-quill-p3310-1000-c03.cfg, \
  tegra186-mb1-bct-pmic-quill-p3310-1000-$(strip $(3)).cfg, \
  tegra186-mb1-bct-pad-quill-p3310-1000-c03.cfg, \
  tegra186-mb1-bct-prod-quill-p3310-1000-c03.cfg, \
  tegra186-mb1-bct-bootrom-quill-p3310-1000-c03.cfg, \
  3310, \
  0 \
)
endef

# $1 Intermediates path
define p3636-p3509_bl_signing_rule
$(call t186_bl_signing_rule, \
  $(strip $(1)), \
  flash_android_t186_p3636.xml, \
  tegra186-bpmp-p3636-0001-a00-00.dtb, \
  tegra186-p3636-0001-p3509-0000-a01-android.dtb, \
  0x2090000, \
  tegra186-mb1-bct-memcfg-p3636-0001-a01.cfg, \
  tegra186-mb1-bct-pinmux-p3636-0001-a00.cfg, \
  tegra186-mb1-bct-pmic-p3636-0001-a00.cfg, \
  tegra186-mb1-bct-pad-p3636-0001-a00.cfg, \
  tegra186-mb1-bct-prod-p3636-0001-a00.cfg, \
  tegra186-mb1-bct-bootrom-p3636-0001-a00.cfg, \
  3636, \
  1 \
)
endef


$(eval $(call p2771_bl_signing_rule, $(P2771-C03_SIGNED_PATH), c01, c03))
$(eval $(call p2771_bl_signing_rule, $(P2771-C04_SIGNED_PATH), c04, c04))

$(eval $(call p3636-p3509_bl_signing_rule, $(P3636-P3509_SIGNED_PATH)))

$(_quill_blob): $(_p2771-c03_br_bct) $(_p2771-c04_br_bct) $(_p3636-p3509_br_bct) $(INSTALLED_KERNEL_TARGET)
	@mkdir -p $(dir $@)
	OUT=$(dir $@) TOP=$(BUILD_TOP) python2 $(TEGRAFLASH_R35)/BUP_generator.py -t update -e \
		"$(P2771-C04_SIGNED_PATH)/spe_sigheader.bin.encrypt spe-fw 2 0 common; \
		 $(P2771-C04_SIGNED_PATH)/nvtboot_sigheader.bin.encrypt mb2 2 0 common; \
		 $(P2771-C04_SIGNED_PATH)/cboot_sigheader.bin.encrypt cpu-bootloader 2 0 common; \
		 $(P2771-C04_SIGNED_PATH)/tos-mon-only_sigheader.img.encrypt secure-os 2 0 common; \
		 $(P2771-C04_SIGNED_PATH)/bpmp_sigheader.bin.encrypt bpmp-fw 2 0 common; \
		 $(P2771-C04_SIGNED_PATH)/adsp-fw_sigheader.bin.encrypt adsp-fw 2 0 common; \
		 $(P2771-C04_SIGNED_PATH)/camera-rtcpu-sce_sigheader.img.encrypt sce-fw 2 0 common; \
		 $(P2771-C04_SIGNED_PATH)/preboot_d15_prod_cr_sigheader.bin.encrypt mts-preboot 2 2 common; \
		 $(P2771-C04_SIGNED_PATH)/mce_mts_d15_prod_cr_sigheader.bin.encrypt mts-bootpack 2 2 common; \
		 $(P2771-C04_SIGNED_PATH)/warmboot_wbheader.bin.encrypt sc7 2 2 common; \
		 $(P2771-C04_SIGNED_PATH)/mb1_prod.bin.encrypt mb1 2 2 common; \
		 $(P2771-C03_SIGNED_PATH)/tegra186-bpmp_sigheader.dtb.encrypt bpmp-fw-dtb 2 0 P2771-0000-DEVKIT-C03.default; \
		 $(P2771-C03_SIGNED_PATH)/tegra186-quill-p3310-1000-c03-00-base_sigheader.dtb.encrypt bootloader-dtb 2 0 P2771-0000-DEVKIT-C03.default; \
		 $(KERNEL_OUT)/arch/arm64/boot/dts/$(DTB_SUBFOLDER)tegra186-quill-p3310-1000-c03-00-base.dtb kernel-dtb 2 0 P2771-0000-DEVKIT-C03.default; \
		 $(P2771-C03_SIGNED_PATH)/br_bct_BR.bct BCT 2 2 P2771-0000-DEVKIT-C03.default; \
		 $(P2771-C03_SIGNED_PATH)/mb1_cold_boot_bct_MB1_sigheader.bct.encrypt MB1_BCT 2 0 P2771-0000-DEVKIT-C03.default; \
		 $(P2771-C04_SIGNED_PATH)/tegra186-bpmp_sigheader.dtb.encrypt bpmp-fw-dtb 2 0 P2771-0000-DEVKIT-C04.default; \
		 $(P2771-C04_SIGNED_PATH)/tegra186-quill-p3310-1000-c03-00-base_sigheader.dtb.encrypt bootloader-dtb 2 0 P2771-0000-DEVKIT-C04.default; \
		 $(KERNEL_OUT)/arch/arm64/boot/dts/$(DTB_SUBFOLDER)tegra186-quill-p3310-1000-c03-00-base.dtb kernel-dtb 2 0 P2771-0000-DEVKIT-C04.default; \
		 $(P2771-C04_SIGNED_PATH)/br_bct_BR.bct BCT 2 2 P2771-0000-DEVKIT-C04.default; \
		 $(P2771-C04_SIGNED_PATH)/mb1_cold_boot_bct_MB1_sigheader.bct.encrypt MB1_BCT 2 0 P2771-0000-DEVKIT-C04.default; \
		 $(P3636-P3509_SIGNED_PATH)/tegra186-bpmp_sigheader.dtb.encrypt bpmp-fw-dtb 2 0 P3636-0001-P3509.default; \
		 $(P3636-P3509_SIGNED_PATH)/tegra186-p3636-0001-p3509-0000-a01-android_sigheader.dtb.encrypt bootloader-dtb 2 0 P3636-0001-P3509.default; \
		 $(KERNEL_OUT)/arch/arm64/boot/dts/$(DTB_SUBFOLDER)tegra186-p3636-0001-p3509-0000-a01-android.dtb kernel-dtb 2 0 P3636-0001-P3509.default; \
		 $(P3636-P3509_SIGNED_PATH)/br_bct_BR.bct BCT 2 2 P3636-0001-P3509.default; \
		 $(P3636-P3509_SIGNED_PATH)/mb1_cold_boot_bct_MB1_sigheader.bct.encrypt MB1_BCT 2 0 P3636-0001-P3509.default"
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
