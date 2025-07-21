#!/bin/bash

# bail if any unset variable is referenced
set -u

qemu-img convert -f raw -O qcow2 -o compression_type=zstd "${IMG}"  "${IMG_QCOW2}"
qemu-img resize "${IMG_QCOW2}" 4G
sudo qemu-nbd -c /dev/nbd0  "${IMG_QCOW2}"
echo  ',+' | sudo sfdisk  -N2  /dev/nbd0
sudo resize2fs /dev/nbd0p2
sudo mount -t vfat /dev/nbd0p1  "${MNT_DIR}"/boot
sudo mount -t ext4 /dev/nbd0p2  "${MNT_DIR}"/root
echo "${USER_PASSWD}" | sudo tee "${MNT_DIR}"/boot/userconf 2>/dev/null 1>&2
echo -e 'otg_mode=0\ndtoverlay=dwc2' | sudo tee -a "${MNT_DIR}"/boot/config.txt 2>/dev/null 1>&2
sync --file-system "${MNT_DIR}"/boot && sleep 0.5
sudo ln -sf /lib/systemd/system/ssh.service "${MNT_DIR}"/root/etc/systemd/system/multi-user.target.wants/ssh.service
if [ -e "$HOME/.ssh/authorized_keys" ]; then
  mkdir -p "${MNT_DIR}"/root/home/pi/.ssh/
  cp "$HOME/.ssh/authorized_keys" "${MNT_DIR}"/root/home/pi/.ssh/
  chown -R 1000:1000 "${MNT_DIR}"/root/home/pi/.ssh/
  chmod 0700 "${MNT_DIR}"/root/home/pi/.ssh/
  chmod 0600 "${MNT_DIR}"/root/home/pi/.ssh/authorized_keys
fi
sync --file-system "${MNT_DIR}"/root && sleep 0.5
sudo umount "${MNT_DIR}"/boot
sudo umount "${MNT_DIR}"/root
sync "${IMG_QCOW2}" && sleep 0.5
sudo qemu-nbd --disconnect /dev/nbd0

