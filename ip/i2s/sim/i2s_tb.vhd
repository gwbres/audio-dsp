library ieee;
use     ieee.std_logic_1164.all;

entity i2s_tb is
end i2s_tb;

architecture rtl of i2s_tb is

	signal clk: std_logic := '0';

	signal bit_count_reg: natural range 0 to 8-1 := 7;

	signal i2s_bclk: std_logic := '0';
	signal i2s_din, i2s_dout: std_logic := '0';
	signal i2s_din_reg: std_logic := '0';
	signal i2s_lr: std_logic := '0';

	signal i2s_lr_hold: std_logic := '0';
	signal i2s_lr_hold_z1: std_logic := '0';

	type data_lut is array (0 to 1) of std_logic_vector(7 downto 0);
	constant DIN_DATA_LUT: data_lut := (x"AA",x"55");
	signal is_odd: std_logic := '0';

	signal stereo_out_valid: std_logic;
	signal stereo_out_data: std_logic_vector(15 downto 0);
begin
	
	clk <= not(clk) after 5.0 ns;

	i2s_bclk <= not(i2s_bclk) after 100.0 ns;

	fake_stereo_lr: process (i2s_bclk)
	begin
	if falling_edge (i2s_bclk) then
		if bit_count_reg = 1 then
			i2s_lr <= not(i2s_lr);
		end if;
		
		if bit_count_reg = 0 then
			bit_count_reg <= 7;
		else
			bit_count_reg <= bit_count_reg-1;
		end if;

		if is_odd = '1' then
			if i2s_lr = '1' then
				i2s_din <= DIN_DATA_LUT(0)(bit_count_reg);
			else
				i2s_din <= DIN_DATA_LUT(1)(bit_count_reg);
			end if;
		else
			if i2s_lr = '1' then
				i2s_din <= DIN_DATA_LUT(1)(bit_count_reg);
			else
				i2s_din <= DIN_DATA_LUT(0)(bit_count_reg);
			end if;
		end if;
	end if;
	end process;

	process (i2s_bclk) 
	begin
	if rising_edge (i2s_bclk) then
		i2s_din_reg <= i2s_din;
		i2s_lr_hold <= i2s_lr;
	end if;
	end process;

	process (clk)
	begin
	if rising_edge (clk) then
		i2s_lr_hold_z1 <= i2s_lr_hold;
		if i2s_lr_hold = '0' and i2s_lr_hold_z1 = '1' then -- L+R done
			is_odd <= not(is_odd);
		end if;
	end if;
	end process;
		
	dut: entity work.i2s
	generic map (
		G_DATA_WIDTH => 8
	) port map (
		clk => clk,
		-- stereo/out
		stereo_out_valid => stereo_out_valid,
		stereo_out_data => stereo_out_data,
		-- I2S
		i2s_bclk => i2s_bclk,
		i2s_din => i2s_din_reg,
		i2s_dout => i2s_dout,
		i2s_lr => i2s_lr
	);

end rtl;
