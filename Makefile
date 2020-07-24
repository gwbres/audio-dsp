FIRMWARE = audio_dsp_top.bit.bin
FIRMWARE_DIR = design/project_1/project_1.runs/impl_1

BUILDROOT_DIR = buildroot
BUILDROOT_SDIMAGE = $(BUILDROOT_DIR)/output/images/sdcard.img

Q = @
RM = rm -rf

all: finalize

$(BUILDROOT_DIR): $(BUILDROOT_DIR)
	git clone https://github.com/buildroot/buildroot

$(BUILDROOT_SDIMAGE): $(BUILDROOT_DIR)
	make -C $(BUILDROOT_DIR) zynq_zed_defconfig
	cp software/zedboard-defconfig $(BUILDROOT_DIR)/.config
	make -C $(BUILDROOT_DIR)
	$(Q)echo "Buildroot image has been built"

$(FIRMWARE_DIR)/$(FIRMWARE): $(BUILDROOT_SD_IMAGE)
	make -C design

$(OVERLAY_DIR)/lib/firmware/$(FIRMWARE): $(FIRMWARE_DIR)/$(FIRMWARE)
	mkdir -p $(OVERLAY_DIR)/lib/firmware
	cp $< $@ 

finalize: $(OVERLAY_DIR)/lib/firmware/$(FIRMWARE) 
	make -C $(BUILDROOT_DIR)
	$(Q)echo "SD card image $(BUILDROOT_SDIMAGE) is ready"

.PHONY:
clean:
	$(RM) $(BUILDROOT_SDIMAGE)
	make -C design clean
