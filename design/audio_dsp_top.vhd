library ieee;
use     ieee.std_logic_1164.all;

library work;
use     work.system_pkg.all;

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
	adau_addr0: out std_logic;
	adau_addr1: out std_logic;
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
	signal audio_rx_data_s: std_logic_vector(C_STEREO_DATA_WIDTH-1 downto 0);
	signal audio_tx_valid_s: std_logic;
	signal audio_tx_data_s: std_logic_vector(C_STEREO_DATA_WIDTH-1 downto 0);

	-- data path
	type stereo_data_array is array (0 to L+R) of std_logic_vector(C_AUDIO_DATA_WIDTH-1 downto 0);

	signal framer_valid_s: std_logic_vector(L+R downto 0) := (others => '0');
	signal framer_data_s: stereo_data_array := (others => (others => '0'));
	signal framer_last_s: std_logic_vector(L+R downto 0) := (others => '0');

	signal cic_valid_s: std_logic_vector(L+R downto 0) := (others => '0');
	signal cic_data_s: stereo_data_array := (others => (others => '0'));

	signal fft_demux_valid_s: std_logic_vector(L+R downto 0) := (others => '0');
	signal fft_demux_data_s: stereo_data_array := (others => (others => '0'));

	type fft_sel_reg_type is array (0 to L+R) of std_logic_vector(2 downto 0);
	signal fft_sel_reg: fft_sel_reg_type := (others => (others => '0'));
	
	signal fft_reframed_valid_s: std_logic_vector(L+R downto 0) := (others => '0');
	signal fft_reframed_data_s: stereo_data_array := (others => (others => '0'));
	signal fft_reframed_last_s: std_logic_vector(L+R downto 0) := (others => '0');

	signal fft_valid_s: std_logic_vector(L+R downto 0) := (others => '0');
	signal fft_data_s: stereo_data_array := (others => (others => '0'));
	signal fft_last_s: std_logic_vector(L+R downto 0) := (others => '0');
	
	signal fft_reframed_valid_s: std_logic_vector(L+R downto 0) := (others => '0');
	signal fft_reframed_data_s: stereo_data_array := (others => (others => '0'));
	signal fft_reframed_last_s: std_logic_vector(L+R downto 0) := (others => '0');

	signal cplx_magnitude_valid_s: std_logic_vector(L+R downto 0) := (others => '0');
	signal cplx_magnitude_data_s: stereo_data_array := (others => (others => '0'));
	signal cplx_magnitude_last_s: std_logic_vector(L+R downto 0) := (others => '0');
	
	type histogram_data_array is array (0 to L+R) of std_logic_vector(C_OLED_Y_HEIGHT-1 downto 0);
	signal histogram_eol: std_logic_vector(L+R downto 0) := (others => '0');
	signal histogram_eof: std_logic_vector(L+R downto 0) := (others => '0');
	signal histogram_pxl: histogram_data_array := (others => (others => '0'));
begin

	-- ######################
	-- Audio Codec (Adau1761)
	-- ######################
	adau1761_drv_inst: entity ip_library.adau1761_top
	port map (
		clk100 => clk100,
		clk48 => clk48_s,
		clk48_rst => clk48_rst_s,
		mclk => open, --adau_mclk,
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
		stereo_in_ready => open,
		stereo_in_valid => audio_rx_valid_s,
		stereo_in_data => audio_rx_data_s,
		-- stereo (out)
		stereo_out_valid => audio_tx_valid_s,
		stereo_out_data => audio_tx_data_s
	);

	-- TX data
	-- loopback demo
	audio_tx_valid_s <= audio_rx_valid_s;
	audio_tx_data_s <= audio_rx_data_s;
	
	--audio_tx_valid_s <= and_reduce(cic_interp_valid_s);

--stereo_data_path_gen: for i in 0 to L+R generate
--
--	stream_framer_inst: entity ip_library.axi4s_framer
--	generic map (
--		G_FRAME_LENGTH => C_OLED_X_WIDTH,
--		G_DATA_WIDTH => C_AUDIO_DATA_WIDTH
--	) port map (
--		clk => clk100,
--		-- stream (in)
--		data_in_valid => audio_rx_valid_s,
--		data_in_data => audio_rx_data_s(C_AUDIO_DATA_WIDTH*(i+1)-1 downto C_AUDIO_DATA_WIDTH*i),
--		-- stream (out)
--		data_out_valid => framer_valid_s(i),
--		data_out_data => framer_data_s(i),
--		data_out_last => framer_last_s(i)
--	);
--
--	-- ##############################
--	-- CIC decimation filter
--	-- Decimates both channels by 128
--	-- reducing sample rate to 24 kHz
--	-- ##############################
--	
--	cic_decim_r128_m1_n8_inst: entity ip_library.cic_filter
--	generic map (
--		G_IS_DECIMATOR => '1',
--		G_CIC_R => 128,
--		G_CIC_N => 8,
--		G_DATA_WIDTH => C_AUDIO_DATA_WIDTH
--	) port map (
--		clk => clk100,
--		-- stream (in)
--		data_in_valid => framer_valid_s(i),
--		data_in_data => framer_data_s(i), 
--		data_in_last => framer_last_s(i)
--		-- stream (out)
--		data_out_valid => cic_decim_valid_s(i),
--		data_out_data => cic_decim_data_s(i),
--		data_out_last => cic_decim_last_s(i)
--	);
--
--	-- #################################
--	-- CIC interpolation filter
--	-- Interpolates both channels by 128
--	-- increasing sample rate to 48 MHz
--	-- #################################
--	
--	cic_interp_r128_m1_n8_inst: entity ip_library.cic_filter
--	generic map (
--		G_IS_DECIMATOR => '0',
--		G_CIC_R => 128,
--		G_CIC_N => 8,
--		G_DATA_WIDTH => C_AUDIO_DATA_WIDTH
--	) port map (
--		clk => clk100,
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
--	-- ######################
--	-- Frequency Domain (L+R)
--	-- ######################
--
--	latch_fft_sel_on_tlast: process (clk100)
--	begin
--	if rising_edge (clk100) then
--		case fft_sel_reg is
--			WHEN "000" =>
--				if cic_valid_s(i) = '1' then
--					if cic_last_s(i) = '1' then
--						fft_sel_reg(i) <= "000";
--					end if;
--				end if;
--			
--			WHEN OTHERS =>
--				if cic_valid_s(i) = '1' then
--					if cic_last_s(i) = '1' then
--						fft_sel_reg(i) <= "000";
--					end if;
--				end if;
--		end case;
--	end if;
--	
--	sync_fft_data_sel: process (clk100)
--	begin
--	if rising_edge (clk100) then
--		case fft_sel_reg is
--			WHEN "000" =>
--				if cic_valid_s(i) = '1' then
--					fft_demux_valid_s(i) <= '1';
--					fft_demux_data_s(i) <= cic_data_s(i);
--				end if;
--
--			WHEN OTHERS => 
--				if cic_valid_s(i) = '1' then
--					fft_demux_valid_s(i) <= '1';
--					fft_demux_data_s(i) <= cic_data_s(i);
--				end if;
--		end case;
--	end if;
--	end process;
--
--	-- ##########################
--	-- Xilinx FFT
--	-- processes a single channel
--	-- ##########################
--	xlnx_fft_chx_inst: xilinx_fft128
--	port map (
--		clk => clk100,
--	);
--
--	-- Discard upper symetric spectrum
--	axi4s_reframer_inst: entity ip_library.axi4s_reframer
--	generic map (
--		G_FRAME_LENGTH => 128/2,
--		G_DATA_WIDTH => G_DATA_WIDTH
--	) port map (
--		clk => clk100,
--		-- stream (in)
--		stream_in_valid => fft_valid_s(i),
--		stream_in_data => fft_data_s(i),
--		stream_in_last => fft_last_s(i),
--		-- stream (out)
--		stream_out_valid => fft_reframed_valid_s(i),
--		stream_out_data => fft_reframed_data_s(i),
--		stream_out_last => fft_reframed_last_s(i)
--	);
--
--	-- #####################
--	-- Calculate magnitude 
--	-- #####################
--	cplx_magnithde_chx_inst: entity ip_library.complex_magnitude
--	generic map (
--		G_DATA_WIDTH => G_DATA_WIDTH
--	) port map (
--		clk => clk100,
--		-- complex (in)
--		cplx_ready => fft_reframed_ready_s(i),
--		cplx_valid => fft_reframed_valid_s(i),
--		cplx_data => fft_reframed_data_s(i),
--		cplx_last => fft_reframed_last_s(i),
--		-- magnitude (out)
--		magnitude_valid => cplx_magnitude_valid_s(i),
--		magnitude_data => cplx_magnitude_data_s(i),
--		magnitude_last => cplx_magnitude_last_s(i)
--	);
--
--	magn_2_histogram_chx_inst: entity ip_library.histogram
--	generic map (
--		G_HISTOGRAM_X_PIXELS => C_OLED_X_WIDTH,
--		G_HISTOGRAM_Y_PIXELS => C_OLED_Y_HEIGHT,
--		G_DATA_WIDTH => G_DATA_WIDTH
--	) port map (
--		clk => clk100,
--		-- magnitude (in)
--		magnitude_valid => cplx_magnitude_valid_s(i),
--		magnitude_data => cplx_magnitude_data_s(i),
--		magnitude_last => cplx_magnitude_last_s(i),
--		-- histogram (out)
--		histogram_eof => histogram_eof(s),
--		histogram_eol => histogram_eol(s),
--		histogram_pxl => histogram_pxl(s)
--	);
--
--end generate; -- STEREO L+R 

	--histogram_left_right_merger: entity ip_library.histogram_merge
	--generic map (
	--) port map (
	--);

	--oled_ctrl_inst: entity ip_library.oled_ctrl
	--generic map (
	--) port map (
	--);

end rtl;
