# Copyright (C) 2022 The LineageOS Project
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

# The new qspi settings fail to initialize in cboot, revert to what was used in l4t r32
function patch_misc_bct() {
  echo -n "Patching bct to increase tee carveout...";

  sed -i '/cpubl_params_carveout_size/a sw_carveout.tzdram_carveout_size = 0x000C00000;' ${LINEAGE_ROOT}/${OUTDIR}/quill/r32/BCT/tegra186-mb1-bct-misc-si-l4t.cfg

  echo "";
}

patch_misc_bct;
