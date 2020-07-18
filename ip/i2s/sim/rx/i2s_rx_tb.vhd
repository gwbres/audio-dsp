library ieee;
use     ieee.std_logic_1164.all;

entity i2s_rx_tb is
end i2s_rx_tb;

architecture rtl of i2s_rx_tb is

	signal clk: std_logic := '0';

	signal bit_count_reg: natural range 0 to 8-1 := 7;

	signal bclk: std_logic := '0';
	signal din, i2s_dout: std_logic := '0';
	signal din_reg: std_logic := '0';
	signal lr: std_logic := '0';

	signal lr_hold: std_logic := '0';
	signal lr_hold_z1: std_logic := '0';

	type data_lut is array (0 to 1) of std_logic_vector(7 downto 0);
	constant DIN_DATA_LUT: data_lut := (x"AA",x"55");
	signal is_odd: std_logic := '0';

	signal stereo_out_valid: std_logic;
	signal stereo_out_data: std_logic_vector(15 downto 0);
begin
	
	clk <= not(clk) after 5.0 ns;

	bclk <= not(bclk) after 20.83 ns;

	fake_stereo_lr: process (bclk)
	begin
	if falling_edge (bclk) then
		if bit_count_reg = 1 then
			lr <= not(lr);
		end if;
		
		if bit_count_reg = 0 then
			bit_count_reg <= 7;
		else
			bit_count_reg <= bit_count_reg-1;
		end if;

		if is_odd = '1' then
			if lr = '1' then
				din <= DIN_DATA_LUT(0)(bit_count_reg);
			else
				din <= DIN_DATA_LUT(1)(bit_count_reg);
			end if;
		else
			if lr = '1' then
				din <= DIN_DATA_LUT(1)(bit_count_reg);
			else
				din <= DIN_DATA_LUT(0)(bit_count_reg);
			end if;
		end if;
	end if;
	end process;

	process (bclk) 
	begin
	if rising_edge (bclk) then
		din_reg <= din;
		lr_hold <= lr;
	end if;
	end process;

	process (clk)
	begin
	if rising_edge (clk) then
		lr_hold_z1 <= lr_hold;
		if lr_hold = '0' and lr_hold_z1 = '1' then -- L+R done
			is_odd <= not(is_odd);
		end if;
	end if;
	end process;
		
	dut: entity work.i2s_rx
	generic map (
		G_DATA_WIDTH => 8
	) port map (
		clk => clk,
		-- stereo
		stereo_valid => stereo_out_valid,
		stereo_data => stereo_out_data,
		-- I2S
		bclk => bclk,
		din => din_reg,
		lr => lr
	);

end rtl;
