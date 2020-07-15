# sys clock
set_property IOSTANDARD "LVCMOS33" 	[get_ports "clk100"]
set_property PACKAGE_PIN "Y9" 		[get_ports "clk100"]
create_clock -period 10.0 -name "clk100" [get_ports "clk100"]

#########################
## adau 1761 
#########################
set_property IOSTANDARD "LVCMOS33" 	[get_ports "adau_mclk"]
set_property PACKAGE_PIN "AB2" 		[get_ports "adau_mclk"]
create_clock -period 20.83 -name "clk48" [get_ports "adau_mclk"]
# i2s
set_property IOSTANDARD "LVCMOS33" 	[get_ports "i2s_bclk"]
set_property IOSTANDARD "LVCMOS33" 	[get_ports "i2s_lr"]
set_property IOSTANDARD "LVCMOS33" 	[get_ports "i2s_din"]
set_property IOSTANDARD "LVCMOS33" 	[get_ports "i2s_dout"]
set_property PACKAGE_PIN "AA6" 		[get_ports "i2s_bclk"]
set_property PACKAGE_PIN "Y6" 		[get_ports "i2s_lr"]
set_property PACKAGE_PIN "AA7" 		[get_ports "i2s_din"]
set_property PACKAGE_PIN "Y8" 		[get_ports "i2s_dout"]
# i2c
set_property IOSTANDARD "LVCMOS33" 	[get_ports "i2c_sda"]
set_property IOSTANDARD "LVCMOS33" 	[get_ports "i2c_scl"]
set_property IOSTANDARD "LVCMOS33" 	[get_ports "i2c_addr0"]
set_property IOSTANDARD "LVCMOS33" 	[get_ports "i2c_addr1"]
set_property PACKAGE_PIN "AB5" 		[get_ports "i2c_sda"]
set_property PACKAGE_PIN "AB4" 		[get_ports "i2c_scl"]
set_property PACKAGE_PIN "AB1" 		[get_ports "i2c_addr0"]
set_property PACKAGE_PIN "Y5" 		[get_ports "i2c_addr1"]
