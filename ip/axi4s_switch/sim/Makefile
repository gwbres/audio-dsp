GHDL = ghdl
GTKWAVE = /usr/bin/gtkwave

RM = rm -rf

TESTBENCH = testbench

SOURCES = ../src/axi4s_switch.vhd

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

.PHONY: clean
clean:
	$(RM) *.cf *.vcd
