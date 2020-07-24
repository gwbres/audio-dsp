TOP = audio_dsp_top
PROJECT = project_1

BITSTREAM = $(PROJECT)/$(PROJECT).runs/impl_1/$(TOP)

VIVADO = vivado -mode batch
BOOTGEN = bootgen -w -arch zynq

Q = @
RM = rm -rf

all: $(BITSTREAM).bit.bin

$(BITSTREAM).bit:
	$(Q)echo "Building reference design.."
	$(VIVADO) -source make-project.tcl
	$(Q)echo "$@ has been generated" 
	
$(BITSTREAM).bit.bin: $(BITSTREAM).bit
	$(Q)echo "Converting bitstream file.."
	$(BOOTGEN) -image bitstream.bif -process bitstream bin
	$(Q)echo "$@ has been generated" 

.PHONY: clean
clean:
	$(RM) $(BISTREAM).bit
	$(RM) $(BITSTREAM).bit.bin
