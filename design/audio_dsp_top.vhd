library ieee;
use     ieee.std_logic_1164.all;

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
	signal adau_i2c_sda_i_s: std_logic;
	signal adau_i2c_sda_o_s: std_logic;
	signal adau_i2c_sda_t_s: std_logic;

begin

	-- ######################
	-- Audio Codec (Adau1761)
	-- ######################

	adau1761_drv_inst: entity ip_library.adau1761_top
	port map (
		clk100 => clk100,
		-- I2C
		scl => adau_scl,
		sda => adau_sda,
		-- I2S
	);

end rtl;
