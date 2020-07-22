# sys clock
set_property IOSTANDARD LVCMOS33				[get_ports "clk100"]
set_property PACKAGE_PIN Y9					[get_ports "clk100"]
create_clock -period 10.0 -name "clk100"	[get_ports "clk100"]

#########################
## ADAU 1761 
#########################
set_property IOSTANDARD LVCMOS33				[get_ports "adau_mclk"]
set_property PACKAGE_PIN AB2					[get_ports "adau_mclk"]
create_clock -period 41.66 -name "mclk"	[get_ports "adau_mclk"]

# I2S
set_property IOSTANDARD LVCMOS33		[get_ports adau_bclk]
set_property PACKAGE_PIN AA6			[get_ports adau_bclk]
create_clock -period 41.66 -name "bclk"	[get_ports adau_bclk]
set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets {adau_bclk_IBUF}]

set_property IOSTANDARD LVCMOS33 	[get_ports "adau_lr"]
set_property IOSTANDARD LVCMOS33 	[get_ports "adau_din"]
set_property IOSTANDARD LVCMOS33 	[get_ports "adau_dout"]
set_property PACKAGE_PIN Y6			[get_ports "adau_lr"]
set_property PACKAGE_PIN AA7			[get_ports "adau_din"]
set_property PACKAGE_PIN Y8			[get_ports "adau_dout"]

# I2S pins
set_input_delay -clock [get_clocks {bclk}] -min -add_delay 20.83 [get_ports {adau_lr}]
set_input_delay -clock [get_clocks {bclk}] -max -add_delay 31.246 [get_ports {adau_lr}]
set_input_delay -clock [get_clocks {bclk}] -min -add_delay 20.83 [get_ports {adau_din}]
set_input_delay -clock [get_clocks {bclk}] -max -add_delay 31.246 [get_ports {adau_din}]
set_input_delay -clock [get_clocks {bclk}] -min -add_delay 20.83 [get_ports {adau_dout}]
set_input_delay -clock [get_clocks {bclk}] -max -add_delay 31.246 [get_ports {adau_dout}]

# I2S rx: bclk -> clk100 (oversampled)
set_false_path -from [get_clocks bclk] -to [get_clocks clk100]
set_false_path -from [get_clocks clk100] -to [get_clocks bclk]

# I2C
set_property IOSTANDARD LVCMOS33 	[get_ports "adau_sda"]
set_property IOSTANDARD LVCMOS33 	[get_ports "adau_scl"]
set_property IOSTANDARD LVCMOS33 	[get_ports "adau_addr0"]
set_property IOSTANDARD LVCMOS33 	[get_ports "adau_addr1"]
set_property PACKAGE_PIN AB5			[get_ports "adau_sda"]
set_property PACKAGE_PIN AB4			[get_ports "adau_scl"]
set_property PACKAGE_PIN AB1			[get_ports "adau_addr0"]
set_property PACKAGE_PIN Y5			[get_ports "adau_addr1"]

#set_input_delay -clock [get_clocks {}] -min -add_delay 2500.0 [get_ports {adau_sda}]
#set_input_delay -clock [get_clocks {}] -max -add_delay 187500.0 [get_ports {adau_sda}]

############################
# OLED display
############################
set_property IOSTANDARD LVCMOS33 [get_ports "oled_sclk"]
set_property IOSTANDARD LVCMOS33 [get_ports "oled_sdin"]
set_property IOSTANDARD LVCMOS33 [get_ports "oled_dc"]
set_property IOSTANDARD LVCMOS33 [get_ports "oled_res"]
set_property IOSTANDARD LVCMOS33 [get_ports "oled_vbat"]
set_property IOSTANDARD LVCMOS33 [get_ports "oled_vdd"]
set_property PACKAGE_PIN AB12		[get_ports "oled_sclk"]
set_property PACKAGE_PIN AA12		[get_ports "oled_sdin"]
set_property PACKAGE_PIN U10		[get_ports "oled_dc"]
set_property PACKAGE_PIN U9		[get_ports "oled_res"]
set_property PACKAGE_PIN U11		[get_ports "oled_vbat"]
set_property PACKAGE_PIN U12		[get_ports "oled_vdd"]
