#!/vendor/bin/sh

if [ "`cat /proc/device-tree/bcmdhd_wlan/status`" = "okay" ]; then
  /vendor/bin/modprobe -a -d /vendor/lib/modules bcmdhd;
else
  /vendor/bin/modprobe -a -d /vendor/lib/modules rtk_btusb;
  /vendor/bin/modprobe -a -d /vendor/lib/modules rtl8822ce;
fi
