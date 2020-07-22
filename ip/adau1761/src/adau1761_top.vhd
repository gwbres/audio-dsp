library ieee;
use     ieee.std_logic_1164.all;

library unisim;
use     unisim.vcomponents.all;

library work;
library ip_library;

entity adau1761_top is
port (
	sys_clk: in std_logic;
	sys_clk_rst: in std_logic;
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
	stereo_in_ready: out std_logic;
	stereo_in_valid: in std_logic;
	stereo_in_data: in std_logic_vector(24*2-1 downto 0);
	-- stereo/out
	stereo_out_valid: out std_logic;
	stereo_out_data: out std_logic_vector(24*2-1 downto 0)
);
end adau1761_top;

architecture rtl of adau1761_top is

	-------------------------------------
	-- clock synthesizer
	-- CLOCK in: 100 MHz
	-- Clock out (1): 48M 
	-- Clock out (2): 24M (adau 'm'clock)
	-------------------------------------
	component clk100_clk24_synth is
	port (
		clk_in1: in std_logic;
		reset: in std_logic;
		locked: out std_logic;
		clk24: out std_logic
	);
	end component clk100_clk24_synth;

    ------------------------------
    -- IIC tri-state buffer
    ------------------------------
	signal i2c_sda_i_s: std_logic;
	signal i2c_sda_o_s: std_logic;
	signal i2c_sda_t_s: std_logic;

begin
	
	------------------------------
	-- Adau/System clk synthesizer
	------------------------------
	audio_clocks_synth_inst: clk100_clk24_synth
	port map (
		clk_in1 => sys_clk,
		reset => '0',
		locked => open,
		clk24 => mclk
	);

	-----------------------
	-- IIC
	-----------------------
	adau_iic_bus: entity work.i2c 
	port map (
		clk => sys_clk,
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
		O => i2c_sda_i_s,
		I => i2c_sda_o_s,
		IO => sda
	);

	addr0 <= '1';
	addr1 <= '1';

	-----------------------
	-- I2S
	-----------------------
	adau_i2s_bus: entity ip_library.i2s
	generic map (
		G_DATA_WIDTH => 24
	) port map (
		clk => sys_clk, 
		rst => sys_clk_rst,
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