library ieee;
use     ieee.numeric_std.all;
use     ieee.std_logic_1164.all;

entity testbench is
end testbench;

architecture rtl of testbench is

	signal clk: std_logic := '0';
	signal rst: std_logic := '1';

	constant C_DATA_WIDTH: natural := 16;
	constant C_HISTOGRAM_WIDTH: natural := 128;
	constant C_CLOG2_HISTOGRAM_HEIGHT: natural := 5;

	-- data (in)
	signal data_in_valid: std_logic := '0';
	signal data_in_data: std_logic_vector(C_DATA_WIDTH-1 downto 0);
	signal last_count: natural range 0 to C_HISTOGRAM_WIDTH-1;
	signal data_in_last: std_logic;

	-- oled ctrl
	signal oled_disp_on_ready: std_logic := '0';
	signal oled_disp_on_start: std_logic;
	signal oled_disp_off_ready: std_logic := '0';
	signal oled_disp_off_start: std_logic;
	-- oled wr 
	signal oled_wr_start: std_logic;
	signal oled_wr_ready: std_logic;
	signal oled_wr_addr: std_logic_vector(8 downto 0);
	signal oled_wr_data: std_logic_vector(7 downto 0);
begin
	
	clk <= not(clk) after 5.0 ns;
	rst <= '0' after 100.0 ns;

	process (clk)
	begin
	if rising_edge (clk) then
		if rst = '1' then
			data_in_valid <= '0';
			last_count <= 0;
			data_in_data <= std_logic_vector(to_unsigned(2**(C_DATA_WIDTH-C_CLOG2_HISTOGRAM_HEIGHT), C_DATA_WIDTH));
			data_in_last <= '0';
		else
			data_in_valid <= not(data_in_valid);
			data_in_last <= '0';
			
			if data_in_valid = '0' then
				if last_count < 127 then
					last_count <= last_count+1;
				else
					last_count <= 0;
					data_in_last <= '1';
				end if;
			end if;

			if data_in_valid = '1' then
				-- ramp pattern
				-- that ranges from pxl(x=0,y=0), to pxl(x=EOF,y=EOF)
				data_in_data <= std_logic_vector(unsigned(data_in_data)+2**C_DATA_WIDTH/C_HISTOGRAM_WIDTH);
			end if;
		end if;
	end if;
	end process;

	dut: entity work.histogram
	generic map (
		G_HISTOGRAM_WIDTH => C_HISTOGRAM_WIDTH,
		G_HISTOGRAM_HEIGHT => 32,
		G_DATA_WIDTH => C_DATA_WIDTH
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

	-- oled emulator
	oled_disp_on_ready <= '1';
	oled_disp_off_ready <= '1' after 35.0 ns;

	fake_oled_ctrl_ready: process 
	begin
		if rst = '1' then
			oled_wr_ready <= '0';
			wait until rising_edge (clk);
		else
			oled_wr_ready <= '1';
			wait until rising_edge (oled_wr_start);
			oled_wr_ready <= '0';
			wait for 30.0 ns;
		end if;
	end process;

end rtl;
