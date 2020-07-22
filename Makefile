FIRMWARE = audio_dsp_top.bit
FIRMWARE_DIR = design/project_1/project_1.runs/impl_1

BUILDROOT_DIR = buildroot
BUILDROOT_SDIMAGE = $(BUILDROOT_DIR)/output/images/sdcard.img

Q = @
RM = rm -rf

$(BUILDROOT_DIR): $(BUILDROOT_DIR)
	git clone https://github.com/buildroot/buildroot

$(BUILDROOT_SDIMAGE): $(BUILDROOT_DIR)
	make -C $(BUILDROOT_DIR) zynq_zed_defconfig
	cp software/zedboard-defconfig $(BUILDROOT_DIR)/.config
	make -C $(BUILDROOT_DIR)
	$(Q)echo "SD card image $@ has been built"

$(FIRMWARE_DIR)/$(FIRMWARE): $(BUILDROOT_SD_IMAGE)
	make -C design
	$(Q)echo "custom firmware $@ has been generated"

.PHONY:
clean:
	$(RM) $(BUILDROOT_SDIMAGE)
	$(RM) $(FIRMWARE_DIR)/$(FIRMWARE)
