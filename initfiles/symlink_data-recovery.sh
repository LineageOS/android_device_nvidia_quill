#!/system/bin/sh

if [ ! -b "/dev/block/by-name/userdata" ]; then
  if [ -b "/dev/block/platform/10003000.pcie-controller/nvme0n1" ]; then
    ln -s /dev/block/platform/10003000.pcie-controller/nvme0n1 /dev/block/by-name/userdata;
  elif [ -b "/dev/block/platform/10003000.pcie/nvme0n1" ]; then
    ln -s /dev/block/platform/10003000.pcie/nvme0n1 /dev/block/by-name/userdata;
  fi;
fi;
