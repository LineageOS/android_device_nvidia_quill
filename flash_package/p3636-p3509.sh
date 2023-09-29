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
TARGET_MODULE_ID=3636;
TARGET_CARRIER_ID=3509;

source $(pwd)/scripts/helpers.sh;

declare -a FLASH_CMD_EEPROM=(
  --applet mb1_recovery_prod.bin
  --chip 0x18);

if ! get_interfaces; then
  exit -1;
fi;

if ! check_compatibility ${TARGET_MODULE_ID} ${TARGET_CARRIER_ID}; then
  echo "No Jetson TX2 NX + Xavier NX carrier found";
  exit -1;
fi;

if [ ! ${MODULEINFO[sku]} -eq 1 ]; then
  echo "Unsupported TX2 NX module sku: ${MODULEINFO[sku]}";
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
  --sdram_config tegra186-mb1-bct-memcfg-p3636-0001-a01.cfg
  --odmdata 0x2090000
  --misc_config tegra186-mb1-bct-misc-si-l4t.cfg
  --pinmux_config tegra186-mb1-bct-pinmux-p3636-0001-a00.cfg
  --pmic_config tegra186-mb1-bct-pmic-p3636-0001-a00.cfg
  --pmc_config tegra186-mb1-bct-pad-p3636-0001-a00.cfg
  --prod_config tegra186-mb1-bct-prod-p3636-0001-a00.cfg
  --scr_config minimal_scr.cfg
  --scr_cold_boot_config mobile_scr.cfg
  --br_cmd_config tegra186-mb1-bct-bootrom-p3636-0001-a00.cfg
  --dev_params emmc.cfg
  --bins "mb2_bootloader nvtboot_recovery.bin; mts_preboot preboot_d15_prod_cr.bin; mts_bootpack mce_mts_d15_prod_cr.bin; bpmp_fw bpmp.bin; bpmp_fw_dtb tegra186-bpmp-p3636-0001-a00-00.dtb; tlk tos-mon-only.img; bootloader_dtb tegra186-p3636-0001-p3509-0000-a01-android.dtb");

cp tegra186-bpmp-p3636-0001-a00-00.dtb tegra186-bpmp.dtb;

tegraflash.py \
  "${FLASH_CMD_FLASH[@]}" \
  --instance ${INTERFACE} \
  --cfg flash_android_t186_p3636.xml \
  --cmd "flash; reboot"

rm tegra186-bpmp.dtb emmc_bootblob_ver.txt;
