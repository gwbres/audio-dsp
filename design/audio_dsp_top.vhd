library ieee;
use     ieee.std_logic_1164.all;

library ip_library;

entity audio_dsp_top is
port (
	clk100: in std_logic;
	-- #####################
	-- Adau1761: audio Codec
	-- #####################
	adau_mclk: out std_logic;
	-- I2C
	adau_scl: out std_logic;
	adau_sda: inout std_logic;
	-- I2S
	adau_bclk: in std_logic;
	adau_lr: in std_logic;
	adau_din: in std_logic;
	adau_dout: out std_logic
);
end audio_dsp_top;

architecture rtl of audio_dsp_top is

	-- ######################
	-- Audio Codec (Adau1761)
	-- ######################
	signal clk48_s: std_logic;
	signal clk48_rst_s: std_logic;

	signal audio_rx_valid_s: std_logic;
	signal audio_rx_data_s: std_logic_vector(23 downto 0);

begin

	-- ######################
	-- Audio Codec (Adau1761)
	-- ######################
	adau1761_drv_inst: entity ip_library.adau1761_top
	port map (
		clk100 => clk100,
		clk48 => clk48_s,
		clk48_rst => clk48_rst_s,
		mclk => adau_mclk,
		-- I2C
		scl => adau_scl,
		sda => adau_sda,
		addr0 => adau_addr0,
		addr1 => adau_addr1,
		-- I2S
		bclk => adau_bclk,
		din => adau_din,
		dout => adau_dout,
		lr => adau_lr,
		-- stereo (in)
		stereo_in_valid => audio_rx_valid_s,
		stereo_in_data => audio_rx_data_s,
		-- stereo (out)
		stereo_out_valid => audio_rx_valid_s,
		stereo_out_data => audio_rx_data_s
	);

end rtl;
