#!/bin/bash
set -e


# CHECK ROOT
if [ "$(whoami)" != "root" ]; then
  echo "You are not root"

  if [ ! -z $@ ]; then
    echo "Add sudo before command: sudo $0 $@"
  else
    echo "Add sudo before command: sudo $0"
  fi

  exit 1
fi


if [ -d /Library/Extensions/NVDAEGPUSupport.kext-unloaded ]; then
  mv /Library/Extensions/NVDAEGPUSupport.kext-unloaded /Library/Extensions/NVDAEGPUSupport.kext

  nvram nvda_drv=1

  echo "Loaded"

  exit 0
fi

mv /Library/Extensions/NVDAEGPUSupport.kext /Library/Extensions/NVDAEGPUSupport.kext-unloaded
nvram -d nvda_drv
echo "Unloaded"
