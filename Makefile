include .env.mk
export $(shell sed -e 's/^#.*//' -e 's/=.*//' -e '/^$$/d' .env.mk)

IMG_QCOW2 := $(patsubst %.img,%.qcow2,$(IMG))

TOP_BUILDDIR := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
MNT_DIR := $(TOP_BUILDDIR)/mnt
QEMU_BOOT_FILES := kernel8.img bcm2710-rpi-3-b.dtb bcm2711-rpi-4-b.dtb

export MNT_DIR

$(IMG):
	./get-rpi-img.sh

$(IMG_QCOW2): $(IMG)
	./prep-qcow2.sh

$(QEMU_BOOT_FILES): | $(IMG_QCOW2)
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

export IMG_QCOW2
.PHONY: run-raspi4 run-raspi3 prep-image
prep-image: | $(IMG_QCOW2)

run-raspi4: | $(QEMU_BOOT_FILES) $(subst .dtb,.mod.dtb,$(filter-out bcm2710-rpi-3-b.dtb,$(QEMU_BOOT_FILES)))
	$(TOP_BUILDDIR)/run-raspi4.sh

run-raspi3: | $(QEMU_BOOT_FILES) $(filter-out bcm2711-rpi-4-b.dtb,$(QEMU_BOOT_FILES))
	$(TOP_BUILDDIR)/run-raspi3.sh

clean::
	rm -f $(QEMU_BOOT_FILES)


clean-all:: clean
	rm -f "$(IMG)"
	rm -f "$(IMG_QCOW2)"
	rm -f *.dts *.dtb *.dts.patched
