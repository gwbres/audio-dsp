GHDL = ghdl
GTKWAVE = /usr/bin/gtkwave

RM = rm -rf

TESTBENCH = i2s_rx_tb

SOURCES = ../../src/i2s_rx.vhd

all: run_sim 

compile: $(SOURCES) $(TESTBENCH).vhd 
	$(GHDL) -a $(SOURCES) $(TESTBENCH).vhd

simulate: compile
	$(GHDL) -e $(TESTBENCH)

run_sim: simulate
	timeout 1s $(GHDL) -r $(TESTBENCH) --vcd=traces.vcd

waveform: run_sim
	$(GTKWAVE) traces.gtkw

.PHONY:
clean:
	$(RM) *.vcd *.cf
