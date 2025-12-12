#!/bin/bash

IMG_QCOW2="${IMG_QCOW2:-2025-05-13-raspios-bookworm-arm64-lite.qcow2}"

# shellcheck disable=SC2054
# Base configuration (known working)
args=(
    # Only accelerated on native ARM64 server
    # -accel kvm
    # -cpu host
    -smp 4
    -m 1G
    #-smp 4,sockets=1,cores=4,threads=1

    # QEMU monitor listening on /tmp/qga.sock in background
    # -chardev socket,id=charchannel0,path=/tmp/qga.sock,server=on,wait=off
    # -mon chardev=charchannel0,id=monitor,mode=readline

    # Serial output to terminal stdout & logfile
    # -chardev stdio,id=char0,logfile=/tmp/qemu-serial.log,signal=off
    # -serial chardev:char0

    # Serial output to background pseudoterminal & logged to file
    -chardev pty,id=char0,logfile=/tmp/qemu-serial.log,signal=off
    -serial chardev:char0

    # Simple stdio/pty alternate options
    # -serial pty
    # -serial stdio
    -monitor stdio

    # -boot order=c
    #-d guest_errors,unimp,int
    #-D /tmp/qemu-debug.log

#     -object '{"qom-type":"memory-backend-ram","id":"pc.ram","size":4294967296}'
)

# Group 1: Machine and CPU configuration
args+=(
    -name 'guest=raspbian-bookworm-2025'
#    -S
#    -uuid $(uuidgen)
    -uuid a01f3487-2856-4f1b-b64c-b0f15153e68f
    -machine raspi3b
    -kernel kernel8.img
    -dtb bcm2710-rpi-3-b.dtb
    #-append "console=ttyAMA0,115200 earlyprintk loglevel=8 dwc_otg.lpm_enable=0 root=/dev/mmcblk0p2 rw rootwait rootfstype=ext4"
    -append  "rw earlyprintk loglevel=8 console=ttyAMA1,115200 console=tty1
              coherent_pool=1M 8250.nr_uarts=0
              snd_bcm2835.enable_headphones=1 snd_bcm2835.enable_hdmi=1
              bcm2708_fb.fbwidth=720 bcm2708_fb.fbheight=480
              bcm2708_fb.fbdepth=16 bcm2708_fb.fbswap=1 vc_mem.mem_base=0x3f000000
              vc_mem.mem_size=0x3f600000 dwc_otg.lpm_enable=0
              root=/dev/mmcblk0p2 rootfstype=ext4 rootdelay=1 fsck.repair=yes
              verbosity=2 net.ifnames=0"

# Other kernel cmdline options:
# dwc2 network
#              modules-load=dwc2,g_ether
# Firstboot init script
#              init=/usr/lib/raspberrypi-sys-mods/firstboot"

#    -nographic

#    -no-user-config
#    -nodefaults
)


# # Group 2: USB and input devices
args+=(
    -usb
    -device usb-mouse
    -device usb-kbd
#    -device usb-tablet
)

# # Group 3: Storage and block devices
args+=(
    #-sd "$IMG_QCOW2"
    -blockdev '{"driver":"file","filename":"'"${IMG_QCOW2}"'","node-name":"libvirt-2-storage","auto-read-only":true,"discard":"unmap"}'
    -blockdev '{"node-name":"libvirt-2-format","read-only":false,"discard":"unmap","driver":"qcow2","file":"libvirt-2-storage","backing":null, "detect-zeroes":"unmap"}'
    -device '{"driver":"sd-card","drive":"libvirt-2-format","id":"virtio-disk0"}'
#    -device '{"driver":"ide-cd","bus":"ide.0","id":"sata0-0-0","bootindex":2}'
)

# # Group 4: Audio configuration
args+=(
    -device '{"driver":"usb-audio","id":"sound0"}'
)


# # Group 5: Security and sandbox settings
#args+=(
    # -sandbox on,obsolete=deny,elevateprivileges=deny,spawn=deny,resourcecontrol=deny
#    -sandbox off
#    -msg timestamp=on
#    -d 'trace:net_*'
#    -D /tmp/qemu-debug.log
#)

# # Group 6: Networking
args+=(
    # localhost forwarding
    #-device usb-net,netdev=net0
    #-netdev user,id=net0,hostfwd=tcp::5555-:22

    # Bridged via libvirt virbr0 (must be created manually)
    -netdev bridge,id=net0,br=virbr0,helper=/usr/lib/qemu/qemu-bridge-helper
    -device usb-net,netdev=net0
)


# # Group 7: RNG and other devices
#args+=(
#    -object '{"qom-type":"rng-random","id":"objrng0","filename":"/dev/urandom"}'
#    -device '{"driver":"virtio-rng-device","rng":"objrng0","id":"rng0","bus":"usb.0","port":"2"}'
#    -device '{"driver":"virtio-balloon-pci","id":"balloon0","bus":"pci.5","addr":"0x0"}'
#)

# Infnoise daemon using unix socket + netcat
# Group 8: Infnoise RNG configuration
#args+=(
    # Use a Unix socket instead of a pipe, configured for one-way random data send
#    -chardev socket,id=infnoise0,path=/tmp/infnoise.sock,server=off
#    -object rng-egd,id=hwrng0,chardev=infnoise0
#    -device virtio-rng,rng=hwrng0,period=1000,max-bytes=204799,bus=pcie.0,addr=0x04
#)

# Start infnoise and create Unix socket
#/usr/bin/infnoise --multiplier 1 | nc -lU /tmp/infnoise.sock &
#INFNOISE_PID=$!
# Clean up when the script exits
#trap "kill $INFNOISE_PID 2>/dev/null; rm -f /tmp/infnoise.sock" EXIT

qemu-system-aarch64 "${args[@]}"
