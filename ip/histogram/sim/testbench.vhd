library ieee;
use     ieee.math_real.all;
use     ieee.numeric_std.all;
use     ieee.std_logic_1164.all;

entity testbench is
end testbench;

architecture rtl of testbench is

	signal clk: std_logic := '0';
	signal rst: std_logic := '1';

	constant C_HISTOGRAM_WIDTH: natural := 128;
	constant C_HISTOGRAM_HEIGHT: natural := 32;
	constant C_CLOG2_HISTOGRAM_HEIGHT: natural := integer(ceil(log2(real(C_HISTOGRAM_HEIGHT))));

	-- data (in)
	signal data_in_ready: std_logic := '0';
	signal data_in_valid: std_logic := '0';
	signal data_in_data: std_logic_vector(C_CLOG2_HISTOGRAM_HEIGHT-1 downto 0);
	signal last_count: natural range 0 to C_HISTOGRAM_WIDTH-1;
	signal data_in_last: std_logic;

	-- oled ctrl
	signal oled_update_ready: std_logic;
	signal oled_update_start: std_logic;
	signal oled_update_clear: std_logic;
	signal oled_disp_on_ready: std_logic;
	signal oled_disp_on_start: std_logic;
	signal oled_disp_off_ready: std_logic;
	signal oled_disp_off_start: std_logic;
	-- oled wr 
	signal oled_wr_start: std_logic;
	signal oled_wr_ready: std_logic;
	signal oled_wr_addr: std_logic_vector(8 downto 0);
	signal oled_wr_data: std_logic_vector(7 downto 0);
	-- oled spi
	signal oled_dc: std_logic;
	signal oled_res: std_logic;
	signal oled_vdd: std_logic;
	signal oled_vbat: std_logic;
	signal oled_sdin: std_logic;
	signal oled_sclk: std_logic;
	
begin
	
	clk <= not(clk) after 5.0 ns;
	rst <= '0' after 100.0 ns;

	pattern_gen_inst: entity work.histogram_ramp_pattern
	generic map (
		G_HISTOGRAM_WIDTH => C_HISTOGRAM_WIDTH,
		G_HISTOGRAM_HEIGHT => C_HISTOGRAM_HEIGHT
	) port map (
		clk => clk,
		-- stream (out)
		data_out_ready => data_in_ready,
		data_out_valid => data_in_valid,
		data_out_data => data_in_data,
		data_out_last => data_in_last
	);

	data_in_ready <= '1';

	dut: entity work.histogram
	generic map (
		G_HISTOGRAM_WIDTH => C_HISTOGRAM_WIDTH,
		G_HISTOGRAM_HEIGHT => 32
	) port map (
		clk => clk,
		rst => rst,
		-- magnitude (in)
		magnitude_valid => data_in_valid,
		magnitude_data => data_in_data,
		magnitude_last => data_in_last,
		-- oled ctrl
		oled_disp_on_ready => oled_disp_on_ready,
		oled_disp_on_start => oled_disp_on_start,
		oled_disp_off_ready => oled_disp_off_ready,
		oled_disp_off_start => oled_disp_off_start,
		-- oled wr 
		oled_wr_ready => oled_wr_ready,
		oled_wr_start => oled_wr_start,
		oled_wr_addr => oled_wr_addr,
		oled_wr_data => oled_wr_data
	);
	
	oled_update_start <= '0';
	oled_update_clear <= '0';

	oled_ctrl_inst: entity work.OLEDCtrl
	port map (
		clk => clk,
		-- oled.wr
		write_ready => oled_wr_ready,
		write_start => oled_wr_start,
		write_base_addr => oled_wr_addr,
		write_ascii_data => oled_wr_data,
		-- oled.update
		update_ready => oled_update_ready,
		update_start => oled_update_start,
		update_clear => oled_update_clear,
		-- oled init
		disp_on_ready => oled_disp_on_ready,
		disp_on_start => '1', --oled_disp_on_start,
		disp_off_ready => oled_disp_off_ready,
		disp_off_start => '1', --oled_disp_off_start,
		toggle_disp_ready => open,
		toggle_disp_start => '1',
		-- oled
		dc => oled_dc,
		res => oled_res,
		sclk => oled_sclk,
		sdin => oled_sdin,
		vbat => oled_vbat,
		vdd => oled_vdd
	);

end rtl;
