#!/bin/bash

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

PATH=$(pwd)/tegraflash:${PATH}

TARGET_TEGRA_VERSION=t186;
TARGET_MODULE_ID=3310;
TARGET_CARRIER_ID=2597;

source $(pwd)/scripts/helpers.sh;

declare -a FLASH_CMD_EEPROM=(
  --applet mb1_recovery_prod.bin
  --chip 0x18);

if ! get_interfaces; then
  exit -1;
fi;

if ! check_compatibility ${TARGET_MODULE_ID} ${TARGET_CARRIER_ID}; then
  echo "No Jetson TX2 Devkit found";
  exit -1;
fi;

BPF_DTB=;
PMIC_CFG=;
NCT=;
if [ "${MODULEINFO[version]}" \= "B00" ]; then
  BPF_DTB_VER="c01";
  PMIC_CFG_VER="c03";
  NCT="p2771-0000-devkit-c03.bin";
elif [ "${MODULEINFO[version]}" \= "B01" -o "${MODULEINFO[version]}" \> "B01" ]; then
  BPF_DTB_VER="c04";
  PMIC_CFG_VER="c04";
  NCT="p2771-0000-devkit-c04.bin";
else
  echo "Module version" "${MODULEINFO[version]}" "is too old, only B00 and newer is supported";
  exit -1;
fi;

# Generate version partition
if ! generate_version_bootblob_v3 emmc_bootblob_ver.txt REPLACEME; then
  echo "Failed to generate version bootblob";
  return -1;
fi;

declare -a FLASH_CMD_FLASH=(
  ${FLASH_CMD_EEPROM[@]}
  --bl nvtboot_recovery_cpu.bin
  --sdram_config P3310_A00_8GB_lpddr4_A02_l4t.cfg
  --odmdata 0x1098000
  --misc_config tegra186-mb1-bct-misc-si-l4t.cfg
  --pinmux_config tegra186-mb1-bct-pinmux-quill-p3310-1000-c03.cfg
  --pmic_config tegra186-mb1-bct-pmic-quill-p3310-1000-${PMIC_CFG_VER}.cfg
  --pmc_config tegra186-mb1-bct-pad-quill-p3310-1000-c03.cfg
  --prod_config tegra186-mb1-bct-prod-quill-p3310-1000-c03.cfg
  --scr_config minimal_scr.cfg
  --scr_cold_boot_config mobile_scr.cfg
  --br_cmd_config tegra186-mb1-bct-bootrom-quill-p3310-1000-c03.cfg
  --dev_params emmc.cfg
  --bins "mb2_bootloader nvtboot_recovery.bin; mts_preboot preboot_d15_prod_cr.bin; mts_bootpack mce_mts_d15_prod_cr.bin; bpmp_fw bpmp.bin; bpmp_fw_dtb tegra186-a02-bpmp-quill-p3310-1000-${BPF_DTB_VER}-00-te770d-ucm2.dtb; tlk tos-mon-only.img; bootloader_dtb tegra186-quill-p3310-1000-c03-00-base.dtb");

cp ${NCT} p2771-0000-devkit.bin;
cp tegra186-a02-bpmp-quill-p3310-1000-${BPF_DTB_VER}-00-te770d-ucm2.dtb tegra186-bpmp.dtb

tegraflash.py \
  "${FLASH_CMD_FLASH[@]}" \
  --instance ${INTERFACE} \
  --cfg flash_android_t186.xml \
  --cmd "flash; reboot"

rm p2771-0000-devkit.bin tegra186-bpmp.dtb emmc_bootblob_ver.txt;
