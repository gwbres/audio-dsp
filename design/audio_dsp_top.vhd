library ieee;
use     ieee.std_logic_1164.all;

library unisim;
use     unisim.vcomponents.all;

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
	adau_dout: out std_logic;
	-- #####################
	-- OLED
	-- #####################
	oled_sdin: out std_logic;
	oled_sclk: out std_logic;
	oled_dc: out std_logic;
	oled_res: out std_logic;
	oled_vbat: out std_logic;
	oled_vdd: out std_logic
);
end audio_dsp_top;

architecture rtl of audio_dsp_top is

	-- sys clk
	signal sys_clk: std_logic;
	signal sys_clk_rst_reg: std_logic_vector(15 downto 0) := (others => '1');
	signal sys_clk_rst: std_logic;

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

	-- ######################
	-- Frequency domain
	-- ######################
	--component xilinx_fft256_single_channel is
	--port (
	--	aclk: in std_logic;
	--	-- config
	--	s_axis_config_tready: out std_logic;
	--	s_axis_config_tvalid: in std_logic;
	--	s_axis_config_tdata: in std_logic_vector(15 downto 0);
	--	-- s_axis_data
	--	s_axis_data_tready: out std_logic;
	--	s_axis_data_tvalid: in std_logic;
	--	s_axis_data_tdata: in std_logic_vector(31 downto 0);
	--	s_axis_data_tlast: in std_logic;
	--	-- m_axis_data
	--	m_axis_data_tready: out std_logic;
	--	m_axis_data_tvalid: in std_logic;
	--	m_axis_data_tdata: in std_logic_vector(31 downto 0);
	--	m_axis_data_tlast: in std_logic;
	--	-- flags
	--	event_frame_started: out std_logic;
	--	event_tlast_unexpected: out std_logic;
	--	event_tlast_missing: out std_logic;
	--	event_status_channel_halt: out std_logic;
	--	event_data_in_channel_halt: out std_logic;
	--	event_data_out_channel_halt: out std_logic
	--);
	--end component xilinx_fft128_single_channel;

	type fft_sel_reg_type is array (0 to L+R) of std_logic_vector(2 downto 0);
	signal fft_sel_reg: fft_sel_reg_type := (others => (others => '0'));
	
	signal fft_reframed_valid_s: std_logic_vector(L+R downto 0) := (others => '0');
	signal fft_reframed_data_s: stereo_data_array := (others => (others => '0'));
	signal fft_reframed_last_s: std_logic_vector(L+R downto 0) := (others => '0');

	signal fft_valid_s: std_logic_vector(L+R downto 0) := (others => '0');
	signal fft_data_s: stereo_data_array := (others => (others => '0'));
	signal fft_last_s: std_logic_vector(L+R downto 0) := (others => '0');

	signal cplx_magnitude_valid_s: std_logic_vector(L+R downto 0) := (others => '0');
	signal cplx_magnitude_data_s: stereo_data_array := (others => (others => '0'));
	signal cplx_magnitude_last_s: std_logic_vector(L+R downto 0) := (others => '0');
	
	type stereo_histogram_dtype is array (0 to L+R) of std_logic_vector(C_LOG2_OLED_Y_HEIGHT-1 downto 0);
   signal cplx_magn_resized_valid_s: std_logic_vector(L+R downto 0) := (others => '0');
   signal cplx_magn_resized_data_s: stereo_histogram_dtype := (others => (others => '0'));
   signal cplx_magn_resized_last_s: std_logic_vector(L+R downto 0) := (others => '0');

	signal oled_write_ready: std_logic;
	signal oled_write_valid: std_logic;
	signal oled_write_addr: std_logic_vector(8 downto 0);
	signal oled_write_data: std_logic_vector(7 downto 0);

    -- OLED
	component OLEDCtrl is
	port (
		clk: in std_logic;
		-- oled.wr
		write_ready: out std_logic;
		write_start: in std_logic;
		write_ascii_data: in std_logic_vector(7 downto 0);
		write_base_addr: in std_logic_vector(8 downto 0);
		-- oled.ctrl
		update_ready: out std_logic;
		update_start: in std_logic;
		disp_on_ready: out std_logic;
		disp_on_start: in std_logic;
		disp_off_ready: out std_logic;
		disp_off_start: in std_logic;
		toggle_disp_ready: out std_logic;
		toggle_disp_start: in std_logic;
		-- oled
		sdin: out std_logic;
		sclk: out std_logic;
		dc: out std_logic;
		res: out std_logic;
		vbat: out std_logic;
		vdd: out std_logic
	);
	end component OLEDCtrl;
	
begin

	sys_clk_buf: IBUFG
	port map (
		I => clk100,
		O => sys_clk
	);
	
	-- sys clock reset bit gen.
	process (sys_clk)
	begin
	if rising_edge (sys_clk) then
		if sys_clk_rst_reg(sys_clk_rst_reg'high) = '1' then
			sys_clk_rst_reg <= sys_clk_rst_reg(sys_clk_rst_reg'length-1 downto 1) & '0';
		end if;
	end if;
	end process;

	sys_clk_rst <= sys_clk_rst_reg(sys_clk_rst_reg'high);
	
	-- ######################
	-- Audio Codec (Adau1761)
	-- ######################
	adau1761_drv_inst: entity ip_library.adau1761_top
	port map (
		sys_clk => sys_clk,
		sys_clk_rst => sys_clk_rst,
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

stereo_data_path_gen: for i in 0 to L+R generate

--	stream_framer_inst: entity ip_library.axi4s_framer
--	generic map (
--		G_FRAME_LENGTH => C_OLED_X_WIDTH,
--		G_DATA_WIDTH => C_AUDIO_DATA_WIDTH
--	) port map (
--		clk => sys_clk,
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
--		clk => sys_clk,
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
--	-- ######################
--	-- Frequency Domain (L+R)
--	-- ######################
--
--	latch_fft_sel_on_tlast: process (sys_clk)
--	begin
--	if rising_edge (sys_clk) then
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
--	sync_fft_data_sel: process (sys_clk)
--	begin
--	if rising_edge (sys_clk) then
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
--	xlnx_fft_chx_inst: xilinx_fft256_single_channel
--	port map (
--		aclk => sys_clk,
--		-- config
--		s_axis_config_tready => fft_config_ready_s(i),
--		s_axis_config_tvalid => fft_config_valid_s(i),
--		s_axis_config_tdata => fft_config_data_s(i),
--		-- data (in)
--		s_axis_data_tready => fft_data_in_ready_s(i),
--		s_axis_data_tvalid => fft_data_in_valid_s(i),
--		s_axis_data_tdata => fft_data_in_data_s(i),
--		s_axis_data_tlast => fft_data_in_last_s(i),
--		-- data (out)
--		m_axis_data_tready => fft_data_out_ready_s(i),
--		m_axis_data_tvalid => fft_data_out_valid_s(i),
--		m_axis_data_tdata => fft_data_out_data_s(i),
--		m_axis_data_tlast => fft_data_out_last_s(i),
--		-- flags
--		event_frame_started => open,
--		event_tlast_unexpected => open,
--		event_tlast_missing => open,
--		event_status_channel_halt => open,
--		event_data_in_channel_halt => open,
--		event_data_out_channel_halt => open
--	);
--
--	-- Discard upper symetric spectrum
--	axi4s_reframer_inst: entity ip_library.axi4s_reframer
--	generic map (
--		G_FRAME_LENGTH => C_OLED_X_WIDTH,
--		G_DATA_WIDTH => G_DATA_WIDTH
--	) port map (
--		clk => sys_clk,
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
--		clk => sys_clk,
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
--	rescale_magn_y_axis: entity ip_library.signed_rounding
--	generic map (
--		G_DIN_WIDTH => G_DATA_WIDTH,
--		G_DOUT_WIDTH => C_OLED_Y_HEIGHT
--	) port map (
--		clk => sys_clk,
--		-- data (in)
--		data_in_valid => cplx_magnitude_valid_s(i),
--		data_in_data => cplx_magnitude_data_s(i),
--		data_in_last => cplx_magnitude_last_s(i),
--		-- data (out)
--		data_out_valid => cplx_magn_resized_valid_s(i),
--		data_out_data => cplx_magn_resized_data_s(i),
--		data_out_last => cplx_magn_resize_last_s(i)
--	);

	histogram_pattern_gen_inst: entity ip_library.histogram_ramp_pattern
	generic map (
		G_HISTOGRAM_WIDTH => C_OLED_X_WIDTH,
		G_HISTOGRAM_HEIGHT => C_OLED_Y_HEIGHT
	) port map (
		clk => sys_clk,
		-- stream (out)
		data_out_ready => '1', 
		data_out_valid => cplx_magn_resized_valid_s(i),
		data_out_data => cplx_magn_resized_data_s(i),
		data_out_last => cplx_magn_resized_last_s(i)
	);

end generate; -- STEREO L+R 

	magn_2_histogram_chx_inst: entity ip_library.histogram
	generic map (
		G_HISTOGRAM_WIDTH => C_OLED_X_WIDTH,
		G_HISTOGRAM_HEIGHT => C_OLED_Y_HEIGHT
	) port map (
		clk => sys_clk,
		rst => '0',
		-- magnitude (in)
		magnitude_valid => cplx_magn_resized_valid_s(0),
		magnitude_data => cplx_magn_resized_data_s(0),
		magnitude_last => cplx_magn_resized_last_s(0),
		-- oled ctrl
		oled_disp_on_ready => '0',
		oled_disp_on_start => open,
		oled_disp_off_ready => '0',
		oled_disp_off_start => open,
		-- oled wdata
		oled_wr_ready => '0',
		oled_wr_start => open,
		oled_wr_addr => open,
		oled_wr_data => open
	);

	oled_ctrl_inst: OLEDCtrl
	port map (
		clk => sys_clk,
		-- oled.wr
		write_ready => oled_write_ready,
		write_start => oled_write_valid,
		write_ascii_data => oled_write_data,
		write_base_addr => oled_write_addr,
		-- oled.ctrl
		update_ready => open,
		update_start => '0',
		disp_on_ready => open,
		disp_on_start => '0',
		disp_off_ready => open,
		disp_off_start => '0',
		toggle_disp_ready => open,
		toggle_disp_start => '0',
		-- oled
		sdin => oled_sdin,
		sclk => oled_sclk,
		dc => oled_dc,
		res => oled_res,
		vbat => oled_vbat,
		vdd => oled_vdd
	);

end rtl;