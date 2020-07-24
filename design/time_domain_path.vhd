library ieee;
use     ieee.std_logic_1164.all;

library unisim;
use     unisim.vcomponents.all;

library work;
use     work.system_pkg.all;

library ip_library;

entity time_domain_path is
port (
	sys_clk: in std_logic;
	-- audio codec
	data_rx_valid: in std_logic;
	data_rx_data: in std_logic_vector(C_STEREO_DATA_WIDTH-1 downto 0);
	-- cic decim. filters
	cic_decim_valid_out: out std_logic_vector(L+R downto 0);
	cic_decim_data_out: out std_logic_vector(C_STEREO_DATA_WIDTH-1 downto 0);
	cic_decim_last_out: out std_logic_vector(L+R downto 0)
	-- cic interp. filters
);
end time_domain_path;

architecture rtl of time_domain_path is

	-- data path
	type stereo_data_array is array (0 to L+R) of std_logic_vector(C_AUDIO_DATA_WIDTH-1 downto 0);

	-- L+R framer
	signal framer_valid_s: std_logic;
	signal framer_data_s: std_logic_vector(C_STEREO_DATA_WIDTH-1 downto 0); 
	signal framer_last_s: std_logic;

	-- CIC filters
	signal cic_decim_valid_s: std_logic_vector(L+R downto 0) := (others => '0');
	signal cic_decim_data_s: std_logic_vector(2*C_CIC_OUTPUT_WIDTH-1 downto 0);
	signal cic_decim_last_s: std_logic_vector(L+R downto 0) := (others => '0');

begin

	stream_framer_inst: entity ip_library.axi4s_framer
	generic map (
		G_FRAME_LENGTH => C_OLED_X_WIDTH * 2,
		G_DATA_WIDTH => C_STEREO_DATA_WIDTH
	) port map (
		clk => sys_clk,
		-- stream (in)
		stream_in_valid => data_rx_valid,
		stream_in_data => data_rx_data,
		-- stream (out)
		stream_out_valid => framer_valid_s,
		stream_out_data => framer_data_s,
		stream_out_last => framer_last_s
	);

cic_filters_gen: for i in 0 to L+R generate
	
	-- ##############################
	-- CIC decimation filter
	-- Decimates both channels by 128
	-- reducing sample rate to 24 kHz
	-- ##############################
	cic_decim_filter_inst: entity ip_library.cic_filter
	generic map (
		G_IS_DECIMATOR => '1',
		G_CIC_R => C_CIC_FILTER_R,
		G_CIC_N => C_CIC_FILTER_N,
		G_DATA_WIDTH => C_AUDIO_DATA_WIDTH
	) port map (
		clk => sys_clk,
		-- stream (in)
		data_in_valid => framer_valid_s,
		data_in_data => framer_data_s((i+1)*C_AUDIO_DATA_WIDTH-1 downto i*C_AUDIO_DATA_WIDTH), 
		data_in_last => framer_last_s,
		-- stream (out)
		data_out_valid => cic_decim_valid_s(i),
		data_out_data => cic_decim_data_s((i+1)*C_CIC_OUTPUT_WIDTH-1 downto i*C_CIC_OUTPUT_WIDTH),
		data_out_last => cic_decim_last_s(i)
	);

	-- #################################
	-- CIC interpolation filter
	-- Interpolates both channels by 128
	-- increasing sample rate to 48 MHz
	-- #################################
--	
--	cic_interp_r128_m1_n8_inst: entity ip_library.cic_filter
--	generic map (
--		G_IS_DECIMATOR => '0',
--		G_CIC_R => 128,
--		G_CIC_N => 8,
--		G_DATA_WIDTH => C_AUDIO_DATA_WIDTH
--	) port map (
--		clk => sys_clk,
--		-- stream (in)
--		stream_in_valid => cic_decim_valid_s(i),
--		stream_in_data => cic_decim_data_s(i),
--		stream_in_last => cic_decim_last_s(i),
--		-- stream (out)
--		data_out_valid => cic_interp_valid_s(i),
--		data_out_data => cic_interp_data_s(i),
--		data_out_last => cic_interp_last_s(i)
--	);
--	
--	-- TX data
--	--audio_tx_data_s((i+1)*C_AUDIO_DATA_WIDTH-1 downto i*C_AUDIO_DATA_WIDTH) <= cic_interp_data_s(i);
--
end generate; -- STEREO L+R 

end rtl;
