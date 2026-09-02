/*
   Copyright (c) 2013, The Linux Foundation. All rights reserved.
   Redistribution and use in source and binary forms, with or without
   modification, are permitted provided that the following conditions are
   met:
    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above
      copyright notice, this list of conditions and the following
      disclaimer in the documentation and/or other materials provided
      with the distribution.
    * Neither the name of The Linux Foundation nor the names of its
      contributors may be used to endorse or promote products derived
      from this software without specific prior written permission.
   THIS SOFTWARE IS PROVIDED "AS IS" AND ANY EXPRESS OR IMPLIED
   WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
   MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NON-INFRINGEMENT
   ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS
   BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
   CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
   SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR
   BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
   WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
   OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN
   IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#include "init_tegra.h"

#include <map>

void recovery_set_usb_product_ids(tegra_init *ti)
{
	std::map<std::string, std::string> mCommonUsbIds, mDeviceUsbIds;

	mCommonUsbIds["ro.recovery.usb.vid"]     = "0955";
	mCommonUsbIds["ro.recovery.usb.adb.pid"] = "7104";

	mDeviceUsbIds["ro.recovery.usb.fastboot.pid"] = "EE16";

	for (auto const& id : mDeviceUsbIds)
		ti->property_set(id.first, id.second);

	for (auto const& id : mCommonUsbIds)
		ti->property_set(id.first, id.second);
}

void vendor_set_usb_product_ids(tegra_init *ti)
{
	std::map<std::string, std::string> mCommonUsbIds, mDeviceUsbIds;

	mCommonUsbIds["ro.vendor.usb.vid"]                            = "0955";
	mCommonUsbIds["ro.vendor.usb.pid.adb"]                        = "7104";
	mCommonUsbIds["ro.vendor.usb.pid.accessory"]                  = "EE0A";
	mCommonUsbIds["ro.vendor.usb.pid.accessory.adb"]              = "7105";
	mCommonUsbIds["ro.vendor.usb.pid.accessory.audio_source"]     = "EE0C";
	mCommonUsbIds["ro.vendor.usb.pid.accessory.audio_source.adb"] = "EE0D";
	mCommonUsbIds["ro.vendor.usb.pid.audio_source"]               = "EE0B";
	mCommonUsbIds["ro.vendor.usb.pid.audio_source.adb"]           = "7106";
	mCommonUsbIds["ro.vendor.usb.pid.ncm"]                        = "7107";
	mCommonUsbIds["ro.vendor.usb.pid.ncm.adb"]                    = "7108";
	mCommonUsbIds["ro.vendor.usb.pid.midi"]                       = "7109";
	mCommonUsbIds["ro.vendor.usb.pid.midi.adb"]                   = "710A";
	mCommonUsbIds["ro.vendor.usb.pid.uvc"]                        = "710B";
	mCommonUsbIds["ro.vendor.usb.pid.uvc.adb"]                    = "710C";

	mDeviceUsbIds["ro.vendor.usb.pid.mtp"]                        = "EE02";
	mDeviceUsbIds["ro.vendor.usb.pid.mtp.adb"]                    = "EE03";
	mDeviceUsbIds["ro.vendor.usb.pid.ptp"]                        = "EE04";
	mDeviceUsbIds["ro.vendor.usb.pid.ptp.adb"]                    = "EE05";
	mDeviceUsbIds["ro.vendor.usb.pid.rndis"]                      = "EE08";
	mDeviceUsbIds["ro.vendor.usb.pid.rndis.adb"]                  = "EE09";

	for (auto const& id : mDeviceUsbIds)
		ti->property_set(id.first, id.second);

	for (auto const& id : mCommonUsbIds)
		ti->property_set(id.first, id.second);
}

void vendor_load_properties()
{
	std::vector<tegra_init::devices> devices = {
		// device      name       hardware    model            id    sku   api dpi
		{ "quill",    "quill",    "quill",   "Jetson TX2",     3310, 1000, 28, 320 },
		{ "quill",    "quill",    "quill",   "Jetson TX2",     3310, 1001, 28, 320 },
		{ "quill",    "storm",    "quill",   "Jetson TX2i",    3489,    0, 28, 320 },
		{ "quill",    "lighting", "quill",   "Jetson TX2 4GB", 3489,  888, 28, 320 },
		{ "quill",    "lighting", "quill",   "Jetson TX2 4GB", 3489,    1, 28, 320 },
		{ "lanai",    "lanai",    "lanai",   "Jetson TX2 NX",  3636,    1, 28, 320 },
	};
	tegra_init::build_version tav = { "11", "RQ1A.210105.003", "7825230_4387.0822" };

	tegra_init ti(devices);
	ti.set_properties();
	ti.set_fingerprints(tav);

	if (ti.recovery_context()) {
		recovery_set_usb_product_ids(&ti);

		ti.property_set("ro.product.vendor.model", ti.property_get("ro.product.model"));
		ti.property_set("ro.product.vendor.manufacturer", ti.property_get("ro.product.manufacturer"));
		ti.property_set("ro.recovery.batteryless", "true");
	}

	if (ti.vendor_context() || ti.recovery_context()) {
		vendor_set_usb_product_ids(&ti);

		std::string boot_dev = ti.property_get("ro.boot.boot_devices");
		if (boot_dev.empty())
			boot_dev = "3460000.sdhci";
		ti.property_set("vendor.tegra.ota.boot_device", std::string("/dev/block/platform/") + boot_dev + "/mmcblk0boot0");
		ti.property_set("vendor.tegra.ota.gpt_device",  std::string("/dev/block/platform/") + boot_dev + "/mmcblk0boot1");
	}

	if (ti.vendor_context())
		vendor_set_usb_product_ids(&ti);
}
