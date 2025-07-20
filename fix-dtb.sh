#!/bin/bash

# Source: https://gitlab.com/qemu-project/qemu/-/issues/2969#note_2586988981

dtc -I dtb -O dts -o bcm2711-rpi-4-b.dts bcm2711-rpi-4-b.dtb

patch -p1 < bcm2711-rpi-4-b.dts.patch

dtc -I dts -O dtb -o bcm2711-rpi-4-b-mod.dtb bcm2711-rpi-4-b.dts
chmod +x bcm2711-rpi-4-b-mod.dtb
