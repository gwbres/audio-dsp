library ieee;
use     ieee.std_logic_1164.all;

library ip_library;

entity adau1761_top is
port (
	clk100: in std_logic;
	-- I2C
	i2s_scl: inout std_logic;
	i2c_sda: inout std_logic;
	-- I2S
	i2s_bclk: in std_logic;
	i2s_din: in std_logic;
	i2s_dout: out std_logic;
	i2s_lr: in std_logic;
	-- stereo/in
	stereo_in_valid: in std_logic;
	stereo_in_data: in std_logic_vector(24*2-1 downto 0)
	-- stereo/out
	stereo_out_valid: out std_logic;
	stereo_out_data: out std_logic_vector(24*2-1 downto 0)
);
end adau1761_top;

architecture rtl of adau1761_top is

	signal i2c_request_s: std_logic;
	signal i2c_addr_s: std_logic_vector( downto 0);
	signal i2c_wdata_s, i2c_rdata_s: std_logic_vector( downto 0);
	signal i2c_busy_s, i2c_done_s: std_logic;
	signal I2c_ack_s: std_logic_vector(3 downto 0);
begin
	
	-----------------------
	-- driver registers 
	-----------------------

	-----------------------------
	-- 100M > 48M clk synthesizer
	-----------------------------
	adau_clk48_generator: adau_clk100_clk48_synth
	port map (
		clk48 =>
		clk24 =>
	);
	
	-----------------------
	-- I2C
	-----------------------
	adau_i2c_bus: entity ip_library.i2c_master
	generic map (
		G_USE_PULL_UP => '1',
		G_REF_CLK_FREQUENCY => 100000000,
		G_I2C_CLK_FREQUENCY => 100000
	) port map (
		clk => clk100,
		-- interface
		i2c_request => i2c_request_s,
		i2c_addr => i2c_addr_s,
		i2c_length => "00",
		i2c_wdata => i2c_wdata_s,
		i2c_rdata => i2c_rdata_s,
		i2c_busy => i2c_busy_s,
		i2c_done => i2c_done_s,
		i2c_ack => i2c_ack_s,
		-- i2c
		scl => i2c_scl,
		sda => i2c_sda
	);

	-----------------------
	-- I2S
	-----------------------
	adau_i2s_bus: entity ip_library.i2s
	generic map (
		G_DATA_WIDTH => 24
	) port map (
		clk => clk100, 
		-- i2s
		i2s_bclk => i2s_bclk,
		i2s_din => i2s_din,
		i2s_dout => i2s_dout,
		i2s_lr => i2s_lr,
		-- stereo /out
		stereo_out_valid => stereo_out_valid,
		stereo_out_data => stereo_out_data
	);

end rtl;
