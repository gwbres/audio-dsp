library ieee;
use     ieee.numeric_std.all;
use     ieee.std_logic_1164.all;

entity i2s_tb is
end i2s_tb;

architecture rtl of i2s_tb is

	constant C_DATA_WIDTH: natural := 8;

	signal clk: std_logic := '0';
	signal rst: std_logic := '1';

	-- I2S
	signal bclk: std_logic := '0';
	signal counter_reg: std_logic_vector(C_DATA_WIDTH-1 downto 0) := (others => '0');
	signal pointer_reg: natural range 0 to C_DATA_WIDTH-1 := C_DATA_WIDTH-1;
	signal din: std_logic;
	signal dout: std_logic;
	signal lr: std_logic := '0';
	signal lr_z1: std_logic := '0';

	-- tx buf
	signal tx_almost_empty: std_logic; 
	signal tx_empty: std_logic; 
	signal tx_underflow: std_logic; 
	signal tx_almost_full: std_logic; 
	signal tx_full: std_logic; 
	signal tx_overflow: std_logic; 

	-- loopback
	signal stereo_rx_ready: std_logic;
	signal stereo_rx_valid: std_logic;
	signal stereo_rx_data: std_logic_vector(2*C_DATA_WIDTH-1 downto 0);
begin
	
	clk <= not(clk) after 5.0 ns;
	rst <= '0' after 30.0 ns;

	bclk <= not(bclk) after 20.83 ns;

	fake_stereo_lr: process (bclk)
	begin
	if falling_edge (bclk) then
		lr_z1 <= lr;

		if pointer_reg = 0 then
			lr <= not(lr);
			counter_reg <= std_logic_vector(unsigned(counter_reg)+1); -- pattern
			pointer_reg <= C_DATA_WIDTH-1;
		else
			pointer_reg <= pointer_reg-1;
		end if;
	end if;
	end process;

	din <= counter_reg(pointer_reg);

	dut: entity work.i2s
	generic map (
		G_DATA_WIDTH => C_DATA_WIDTH
	) port map (
		clk => clk,
		rst => rst,
		-- tx buf
		tx_almost_empty => tx_almost_empty,
		tx_empty => tx_empty,
		tx_underflow => tx_underflow,
		tx_almost_full => tx_almost_full,
		tx_full => tx_full,
		tx_overflow => tx_overflow,
		-- stereo (in)
		stereo_in_ready => stereo_rx_ready,
		stereo_in_valid => stereo_rx_valid,
		stereo_in_data => stereo_rx_data,
		-- stereo (out)
		stereo_out_valid => stereo_rx_valid,
		stereo_out_data => stereo_rx_data,
		-- I2S
		bclk => bclk,
		din => din,
		dout => dout,
		lr => lr_z1
	);

end rtl;
