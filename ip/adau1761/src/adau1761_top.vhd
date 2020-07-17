library ieee;
use     ieee.std_logic_1164.all;

entity adau1761_top is
port (
	clk100: in std_logic;
	clk48: out std_logic;
	clk48_rst: out std_logic;
	mclk: out std_logic;
	-- I2C
	scl: out std_logic;
	sda: inout std_logic;
	addr0: out std_logic;
	addr1: out std_logic;
	-- I2S
	bclk: in std_logic;
	din: in std_logic;
	dout: out std_logic;
	lr: in std_logic;
	-- stereo/in
	stereo_in_valid: in std_logic;
	stereo_in_data: in std_logic_vector(24*2-1 downto 0)
	-- stereo/out
	stereo_out_valid: out std_logic;
	stereo_out_data: out std_logic_vector(24*2-1 downto 0)
);
end adau1761_top;

architecture rtl of adau1761_top is

	-------------------------------------
	-- clock synthesizer
	-- CLOCK in: 100 MHz
	-- Clock out (1): 48M (system clock)
	-- Clock out (2): 24M (adau 'm'clock)
	-------------------------------------
	component clk100_clk48_synth is
	port (
		clk100: in std_logic;
		clk48: out std_logic;
		clk24: out std_logic
	);
	end clk100_clk48_synth;

	signal i2c_sda_i_s: std_logic;
	signal i2c_sda_o_s: std_logic;
	signal i2c_sda_t_s: std_logic;

	signal clk48_s: std_logic;
	signal clk48_rst_s: std_logic;
	signal clk48_reset_reg: std_logic_vector(15 downto 0) := (others => '1');
begin
	
	------------------------------
	-- Adau/System clk synthesizer
	------------------------------
	adau_clk48_generator: adau_clk100_clk48_synth
	port map (
		clk100 => clk100,
		clk48 => clk48_s,
		clk24 => mclk,
	);

	clk48 <= clk48_s;
	clk48_rst_s <= clk48_reset_reg(clk48_reset_reg'high);
	clk48_rst <= clk48_rst;

	-- CLK48 reset bit generator
	process (clk48_s)
	begin
	if rising_edge (clk48_s) then
		if clk48_reset_reg(clk48_reset_reg'high) = '1' then
			clk48_reset_reg <= clk48_reset_reg(clk48_reset_reg'length-1 downto 1) & '0';
		end if;
	end if;
	end process;
	
	-----------------------
	-- IIC
	-----------------------
	adau_iic_bus: entity work.i2c 
	port map (
		clk => clk100,
		i2c_sda_i => i2c_sda_i_s,
		i2c_sda_o => i2c_sda_o_s,
		i2c_sda_t => i2c_sda_t_s,
		sw => "00",
		active => open
	);

	-- tristate buf for I2C bus
	adau_iic_iobuf_inst: IOBUF
	port map (
		T => i2c_sda_t_s,
		I => i2c_sda_i_s,
		O => i2c_sda_o_s,
		IO => sda
	);

	addr0 <= '0';
	addr1 <= '0';

	-----------------------
	-- I2S
	-----------------------
	adau_i2s_bus: entity ip_library.i2s
	generic map (
		G_DATA_WIDTH => 24
	) port map (
		clk => clk48_s, 
		rst => clk48_rst_s,
		-- tx buffer
		tx_almost_empty => open,
		tx_empty => open,
		tx_underflow => open,
		tx_almost_full => open,
		tx_full => open,
		tx_overflow => open,
		-- stereo stream (in)
		stereo_in_ready => stereo_in_ready,
		stereo_in_valid => stereo_in_valid,
		stereo_in_data => stereo_in_data,
		-- stream stream (out)
		stereo_out_valid => stereo_out_valid,
		stereo_out_data => stereo_out_data,
		-- i2s
		bclk => bclk,
		din => din,
		dout => dout,
		lr => lr
	);

end rtl;
