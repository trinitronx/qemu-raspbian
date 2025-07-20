IMG := 2025-05-13-raspios-bookworm-arm64-lite.img
IMG_QCOW2 := $(patsubst %.img,%.qcow2,$(IMG))

TOP_BUILDDIR := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
MNT_DIR := $(TOP_BUILDDIR)/mnt
QEMU_BOOT_FILES := kernel8.img bcm2710-rpi-3-b.dtb bcm2711-rpi-4-b.dtb

# Default insecure pi user password: raspberrypi
# Escape any '$' chars as '$$'
USER_PASSWD := 'pi:$$6$$6jHfJHU59JxxUfOS$$k9natRNnu0AaeS/S9/IeVgSkwkYAjwJfGuYfnwsUoBxlNocOn.5yIdLRdSeHRiw8EWbbfwNSgx9/vUhu0NqF50'

$(IMG):
	./get-rpi-img.sh

$(IMG_QCOW2): $(IMG)
	qemu-img convert -f raw -O qcow2 -o compression_type=zstd "$(IMG)"  "$(IMG_QCOW2)"
	qemu-img resize "$(IMG_QCOW2)" 4G
	sudo qemu-nbd -c /dev/nbd0  "$(IMG_QCOW2)"
	echo  ',+' | sudo sfdisk  -N2  /dev/nbd0
	sudo resize2fs /dev/nbd0p2
	sudo mount -t vfat /dev/nbd0p1  "$(MNT_DIR)"/boot
	sudo mount -t ext4 /dev/nbd0p2  "$(MNT_DIR)"/root
	echo $(USER_PASSWD) | sudo tee "$(MNT_DIR)"/boot/userconf 2>/dev/null 1>&2
	echo -e 'otg_mode=0\ndtoverlay=dwc2' | sudo tee -a "$(MNT_DIR)"/boot/config.txt 2>/dev/null 1>&2
	sync --file-system "$(MNT_DIR)"/boot && sleep 0.5
	sudo ln -sf /lib/systemd/system/ssh.service "$(MNT_DIR)"/root/etc/systemd/system/multi-user.target.wants/ssh.service
	[ -e "$$HOME/.ssh/authorized_keys" ] && (mkdir -p "$(MNT_DIR)"/root/home/pi/.ssh/ \
          && cp "$$HOME/.ssh/authorized_keys" "$(MNT_DIR)"/root/home/pi/.ssh/ \
          && chown -R 1000:1000 "$(MNT_DIR)"/root/home/pi/.ssh/ \
          && chmod 0700 "$(MNT_DIR)"/root/home/pi/.ssh/ \
          && chmod 0600 "$(MNT_DIR)"/root/home/pi/.ssh/authorized_keys ) \
          || true
	sync --file-system "$(MNT_DIR)"/root && sleep 0.5
	sudo umount "$(MNT_DIR)"/boot
	sudo umount "$(MNT_DIR)"/root
	sync $(IMG_QCOW2) && sleep 0.5
	sudo qemu-nbd --disconnect /dev/nbd0

$(QEMU_BOOT_FILES): $(IMG_QCOW2)
	sudo qemu-nbd -c /dev/nbd0  "$(IMG_QCOW2)"
	sudo mount -t vfat /dev/nbd0p1  "$(MNT_DIR)"/boot
	cp $(addprefix '$(MNT_DIR)'/boot/,$(QEMU_BOOT_FILES))  "$(TOP_BUILDDIR)/"
	sync --file-system "$(MNT_DIR)"/boot && sleep 0.5
	sudo umount "$(MNT_DIR)"/boot
	sync $(IMG_QCOW2) && sleep 0.5
	sudo qemu-nbd --disconnect /dev/nbd0
	touch $(QEMU_BOOT_FILES)


.SECONDARY: $(subst .dtb,.dts,$(filter %.dtb,$(QEMU_BOOT_FILES))) $(subst .dtb,.dts.patched,$(filter %.dtb,$(QEMU_BOOT_FILES)))
%.dtb: $(QEMU_BOOT_FILES)
%.dts: %.dtb
	dtc -I dtb -O dts -o $@ $*.dtb
	touch $@

%.dts.patched: %.dts.patch %.dts
	cp $*.dts $*.dts.bak
	cd "$(TOP_BUILDDIR)" && patch -p1 < '$<'
	mv $*.dts $*.dts.patched
	mv $*.dts.bak $*.dts
	touch $*.dts.patched

%.mod.dtb: %.dts.patched
	dtc -I dts -O dtb -o $@ $*.dts.patched
	chmod +x $@

clean::
	rm -f $(QEMU_BOOT_FILES)


clean-all:: clean
	rm -f "$(IMG)"
	rm -f "$(IMG_QCOW2)"
