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

FLASH_XML="flash_android_t186.xml";
LOCK=0;

# Bit 15: Tegra watchdog timer
# Bit 16: Denver watchdog timer
# Bit 19: Enable debug port
# Bit 24: Uphy lane 0 enable xusb
ODMDATA=$((1<<15 | 1<<16 | 1<<19 | 1<<24))

VALID_ARGS=$(getopt -o hl:: --long help,lock:: -- "$@")
if [[ $? -ne 0 ]]; then
    exit 1;
fi

eval set -- "$VALID_ARGS"
while [ : ]; do
  case "$1" in
    -l | --lock)
      if [ "$2" == "0" ]; then
        LOCK=0;
      elif [ -z "$2" -o "$2" == "1" ]; then
        LOCK=1;
      else
        echo "Invalid value for lock";
        exit 1;
      fi;
      shift 2
      ;;
    --) shift;
      break
      ;;
    ? | h | --help)
      echo "Usage: $(basename $0) [-n|--nvme]"
      exit 1
      ;;
  esac
done

if [ ${LOCK} -eq 1 ]; then
  if [ ! -f "avb_pkmd.bin" -o ! -f "vbmeta.img" ]; then
    echo "avb_pkmd.bin and vbmeta.img are required to boot in locked state.";
    exit 1;
  fi;

  sed '0,/vbmeta_skip.img/s//vbmeta.img/' ${FLASH_XML} > flash.xml;
  sed -i '/name="avb_custom_key"/a \ \ \ \ \ \ \ \ \ \ \ \ <filename> avb_pkmd.bin </filename>' flash.xml;
  FLASH_XML="flash.xml";

  # Bit 13: Bootloader Lock State
  ODMDATA=$((${ODMDATA} | 1<<13));
fi;

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
  --odmdata $(printf "0x%x" ${ODMDATA})
  --misc_config tegra186-mb1-bct-misc-si-l4t.cfg
  --pinmux_config tegra186-mb1-bct-pinmux-quill-p3310-1000-c03.cfg
  --pmic_config tegra186-mb1-bct-pmic-quill-p3310-1000-${PMIC_CFG_VER}.cfg
  --pmc_config tegra186-mb1-bct-pad-quill-p3310-1000-c03.cfg
  --prod_config tegra186-mb1-bct-prod-quill-p3310-1000-c03.cfg
  --scr_config minimal_scr.cfg
  --scr_cold_boot_config mobile_scr.cfg
  --br_cmd_config tegra186-mb1-bct-bootrom-quill-p3310-1000-c03.cfg
  --dev_params emmc.cfg
  --bins "mb2_bootloader nvtboot_recovery.bin; mts_preboot preboot_d15_prod_cr.bin; mts_bootpack mce_mts_d15_prod_cr.bin; bpmp_fw bpmp.bin; bpmp_fw_dtb tegra186-a02-bpmp-quill-p3310-1000-${BPF_DTB_VER}-00-te770d-ucm2.dtb; tlk tos.img; eks eks.img; bootloader_dtb tegra186-quill-p3310-1000-c03-00-base-bl.dtb");

cp ${NCT} p2771-0000-devkit.bin;
cp tegra186-a02-bpmp-quill-p3310-1000-${BPF_DTB_VER}-00-te770d-ucm2.dtb tegra186-bpmp.dtb

tegraflash.py \
  "${FLASH_CMD_FLASH[@]}" \
  --instance ${INTERFACE} \
  --cfg ${FLASH_XML} \
  --cmd "flash; reboot"

rm p2771-0000-devkit.bin tegra186-bpmp.dtb emmc_bootblob_ver.txt;
if [ ${LOCK} -eq 1 ]; then
  rm ${FLASH_XML};
fi;
