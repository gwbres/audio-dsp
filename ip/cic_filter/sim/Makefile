GHDL = ghdl
GTKWAVE = /usr/bin/gtkwave

RM = rm -rf

TESTBENCH = testbench

SOURCES = ../../signed_rounding/src/signed_rounding.vhd

SOURCES += ../src/cic_integrator_stage.vhd
SOURCES += ../src/cic_comb_stage.vhd
SOURCES += ../src/cic_decimator.vhd
SOURCES += ../src/cic_interpolator.vhd
SOURCES += ../src/cic_filter.vhd

GFLAGS += --std=08

all: run_sim 

compile: $(SOURCES) $(TESTBENCH).vhd 
	$(GHDL) -a $(GFLAGS) $(SOURCES) $(TESTBENCH).vhd

simulate: compile
	$(GHDL) -e $(GFLAGS) $(TESTBENCH)

run_sim: simulate
	timeout 1s $(GHDL) -r $(GFLAGS) $(TESTBENCH) --vcd=traces.vcd

waveform: run_sim
	$(GTKWAVE) traces.gtkw

.PHONY:
clean:
	$(RM) *.vcd *.cf
