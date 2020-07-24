library ieee;
use     ieee.std_logic_1164.all;

library unisim;
use     unisim.vcomponents.all;

library work;
use     work.system_pkg.all;

library ip_library;

entity frequency_data_path is
port (
	sys_clk: in std_logic;
	-- #####################
	-- DEMUX
	-- #####################
	demux_sel: in std_logic_vector(2 downto 0);
	-- #####################
	-- CIC filters
	-- #####################
	cic_valid_in: in std_logic_vector(L+R downto 0);
	cic_data_in: in std_logic_vector(C_STEREO_DATA_WIDTH-1 downto 0);
	cic_last_in: in std_logic_vector(L+R downto 0);
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
end frequency_data_path;

architecture rtl of frequency_data_path is

	-- FFT Demux
	type fft_sel_reg_type is array (0 to L+R) of std_logic_vector(2 downto 0);
	signal fft_sel_reg: fft_sel_reg_type := (others => (others => '0'));

	signal fft_demux_valid_s: std_logic_vector(L+R downto 0) := (others => '0');
	signal fft_demux_data_s: std_logic_vector(C_STEREO_DATA_WIDTH-1 downto 0) := (others => '0'); 
	signal fft_demux_last_s: std_logic_vector(L+R downto 0) := (others => '0');

	signal fft_demux_round_valid_s: std_logic_vector(L+R downto 0) := (others => '0');
	signal fft_demux_round_data_s: std_logic_vector(2*C_FFT_DATA_WIDTH-1 downto 0) := (others => '0'); 
	signal fft_demux_round_last_s: std_logic_vector(L+R downto 0) := (others => '0');

	-- ############################
	-- Xilinx FFT N=256
	-- Dual channel core
	-- ############################
	component xilinx_fft256 is
	port (
		aclk: in std_logic;
		-- config
		s_axis_config_tready: out std_logic;
		s_axis_config_tvalid: in std_logic;
		s_axis_config_tdata: in std_logic_vector(39 downto 0);
		-- s_axis_data
		s_axis_data_tready: out std_logic;
		s_axis_data_tvalid: in std_logic;
		s_axis_data_tdata: in std_logic_vector(63 downto 0);
		s_axis_data_tlast: in std_logic;
		-- m_axis_data
		m_axis_data_tready: out std_logic;
		m_axis_data_tvalid: in std_logic;
		m_axis_data_tdata: in std_logic_vector(63 downto 0);
		m_axis_data_tlast: in std_logic;
		-- flags
		event_frame_started: out std_logic;
		event_tlast_unexpected: out std_logic;
		event_tlast_missing: out std_logic;
		event_status_channel_halt: out std_logic;
		event_data_in_channel_halt: out std_logic;
		event_data_out_channel_halt: out std_logic
	);
	end component xilinx_fft256;

	-- FFT/config
	signal fft_config_ready_s: std_logic;
	signal fft_config_valid_s: std_logic := '0';
	signal fft_config_data_s: std_logic_vector(39 downto 0) := (others => '0');

	-- FFT/in
	signal fft_data_in_ready_s: std_logic;
	signal fft_data_in_valid_s: std_logic;
	signal fft_data_in_data_s: std_logic_vector(4*C_FFT_DATA_WIDTH-1 downto 0) := (others => '0');
	signal fft_data_in_last_s: std_logic;
	
	-- FFT/out
	signal fft_data_out_ready_s: std_logic;
	signal fft_data_out_valid_s: std_logic;
	signal fft_data_out_data_s: std_logic_vector(4*C_FFT_DATA_WIDTH-1 downto 0) := (others => '0');
	signal fft_data_out_last_s: std_logic;
	
	-- FFT/reframer
	signal fft_reframed_valid_s: std_logic;
	signal fft_reframed_data_s: std_logic_vector(4*C_FFT_DATA_WIDTH-1 downto 0); 
	signal fft_reframed_last_s: std_logic;

	-- ||^2
	signal cplx_magnitude_valid_s: std_logic_vector(L+R downto 0) := (others => '0');
	signal cplx_magnitude_data_s: std_logic_vector(2*(C_FFT_DATA_WIDTH*2+1)-1 downto 0); 
	signal cplx_magnitude_last_s: std_logic_vector(L+R downto 0) := (others => '0');
	
	-- histogram
   signal cplx_magn_resized_valid_s: std_logic_vector(L+R downto 0) := (others => '0');
   signal cplx_magn_resized_data_s: std_logic_vector(2*(C_LOG2_OLED_Y_HEIGHT)-1 downto 0) := (others => '0');
   signal cplx_magn_resized_last_s: std_logic_vector(L+R downto 0) := (others => '0');

	-- OLED
	signal oled_write_ready: std_logic;
	signal oled_write_valid: std_logic;
	signal oled_write_addr: std_logic_vector(8 downto 0);
	signal oled_write_data: std_logic_vector(7 downto 0);

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

--fft_input_data_gen: for i in 0 to L+R generate
--
--	latch_fft_sel_on_tlast: process (sys_clk)
--	begin
--	if rising_edge (sys_clk) then
--		case fft_sel_reg(i) is
--			WHEN "000" =>
--			 	if cic_valid_in(i) = '1' then
--			 		if cic_last_in(i) = '1' then
--			 			fft_sel_reg(i) <= "000"; --demux_sel;
--			 		end if;
--				end if;
--		 
--			WHEN OTHERS =>
--				if cic_valid_in(i) = '1' then
--					if cic_last_in(i) = '1' then
--						fft_sel_reg(i) <= "000"; --demux_sel;
--					end if;
--				end if;
--		end case;
--	end if;
--	end process;
--	
--	sync_fft_data_sel: process (sys_clk)
--	begin
--	if rising_edge (sys_clk) then
--		fft_demux_valid_s(i) <= '0';
--		fft_demux_last_s(i) <= '0';
--
--		case fft_sel_reg(i) is
--			WHEN "000" =>
--				if cic_valid_in(i) = '1' then
--					fft_demux_valid_s(i) <= '1';
--					
--					fft_demux_data_s((i+1)*C_AUDIO_DATA_WIDTH-1 downto i*C_AUDIO_DATA_WIDTH) 
--						<= cic_data_in((i+1)*C_AUDIO_DATA_WIDTH-1 downto i*C_AUDIO_DATA_WIDTH);
--					
--					if cic_last_in(i) = '1' then
--						fft_demux_last_s(i) <= '1';
--					end if;
--				end if;
--
--			WHEN OTHERS => 
--		end case;
--	end if;
--	end process;
--	
--	fft_demux_data_scaler_inst: entity ip_library.signed_rounding
--	generic map (
--		G_DIN_WIDTH => C_AUDIO_DATA_WIDTH, 
--		G_DOUT_WIDTH => C_FFT_DATA_WIDTH 
--	) port map (
--		clk => sys_clk,
--		-- data (in)
--		data_in_valid => fft_demux_valid_s(i),
--		data_in_data => fft_demux_data_s((i+1)*C_AUDIO_DATA_WIDTH-1 downto i*C_AUDIO_DATA_WIDTH),
--		data_in_last => fft_demux_last_s(i),
--		-- data (out)
--		data_out_valid => fft_demux_round_valid_s(i),
--		data_out_data => fft_demux_round_data_s((i+1)*C_FFT_DATA_WIDTH-1 downto i*C_FFT_DATA_WIDTH),
--		data_out_last => fft_demux_round_last_s(i)
--	);
--
--end generate; -- fft(in)
--
--	sync_xfft_config_ctrl: process (sys_clk)
--	begin
--	if rising_edge (sys_clk) then
--		fft_config_valid_s <= '0';
--		if fft_config_ready_s = '1' then
--			fft_config_valid_s <= '1';
--			fft_config_data_s(39 downto 33) <= (others => '0');
--			-- scaling
--			fft_config_data_s(33 downto 18) <= x"AAA2"; -- CH1
--			fft_config_data_s(17 downto  2) <= x"AAA2"; -- CH0
--			-- FWD
--			fft_config_data_s(1) <= '1'; 
--			fft_config_data_s(0) <= '1';
--		end if;
--	end if;
--	end process;
--
--	sync_xfft_input_format: process (sys_clk)
--	begin
--	if rising_edge (sys_clk) then
--		fft_data_in_valid_s <= '0';
--		fft_data_in_last_s <= '0';
--		if fft_data_in_ready_s = '1' then
--			if fft_demux_round_valid_s(L) = '1' and fft_demux_round_valid_s(R) = '1' then
--				fft_data_in_valid_s <= '1';
--				
--				-- CH1: img
--				fft_data_in_data_s((L+4)*C_FFT_DATA_WIDTH-1 downto (L+4)*C_FFT_DATA_WIDTH) <= (others => '0');
--				-- CH1: real
--				fft_data_in_data_s((L+3)*C_FFT_DATA_WIDTH-1 downto (L+3)*C_FFT_DATA_WIDTH) <=
--					fft_demux_round_data_s((L+3)*C_FFT_DATA_WIDTH-1 downto (L+3)*C_FFT_DATA_WIDTH);
--
--				-- CH0: img
--				fft_data_in_data_s((L+2)*C_FFT_DATA_WIDTH-1 downto (L+1)*C_FFT_DATA_WIDTH) <= (others => '0');
--				-- CH0: real
--				fft_data_in_data_s((L+1)*C_FFT_DATA_WIDTH-1 downto L*C_FFT_DATA_WIDTH) <=
--					fft_demux_round_data_s((L+1)*C_FFT_DATA_WIDTH-1 downto L*C_FFT_DATA_WIDTH);
--				
--				if fft_demux_round_last_s(L) = '1' and fft_demux_round_last_s(R) = '1' then
--					fft_data_in_last_s <= '1';
--				end if;
--			end if;
--		end if;
--	end if;
--	end process;
--
--	-- ##########################
--	-- Xilinx FFT
--	-- ##########################
--	--xlnx_fft_core_inst: xilinx_fft256
--	--port map (
--	--	aclk => sys_clk,
--	--	-- config
--	--	s_axis_config_tready => fft_config_ready_s,
--	--	s_axis_config_tvalid => fft_config_valid_s,
--	--	s_axis_config_tdata => fft_config_data_s,
--	--	-- data (in)
--	--	s_axis_data_tready => fft_data_in_ready_s,
--	--	s_axis_data_tvalid => fft_data_in_valid_s,
--	--	s_axis_data_tdata => fft_data_in_data_s,
--	--	s_axis_data_tlast => fft_data_in_last_s,
--	--	-- data (out)
--	--	m_axis_data_tready => fft_data_out_ready_s,
--	--	m_axis_data_tvalid => fft_data_out_valid_s,
--	--	m_axis_data_tdata => fft_data_out_data_s,
--	--	m_axis_data_tlast => fft_data_out_last_s,
--	--	-- flags
--	--	event_frame_started => open,
--	--	event_tlast_unexpected => open,
--	--	event_tlast_missing => open,
--	--	event_status_channel_halt => open,
--	--	event_data_in_channel_halt => open,
--	--	event_data_out_channel_halt => open
--	--);
--
--	fft_data_out_ready_s <= '1';
--	
--	-- dicard symetric upper frequencies
--	xilinx_fft_reframer_inst: entity ip_library.axi4s_reframer
--	generic map (
--		G_FRAME_LENGTH => C_OLED_X_WIDTH,
--		G_DATA_WIDTH => fft_data_out_data_s'length 
--	) port map (
--		clk => sys_clk,
--		-- stream (in)
--		stream_in_valid => fft_data_out_valid_s,
--		stream_in_data => fft_data_out_data_s, 
--		stream_in_last => fft_data_out_last_s,
--		-- stream (out)
--		stream_out_valid => fft_reframed_valid_s,
--		stream_out_data => fft_reframed_data_s,
--		stream_out_last => fft_reframed_last_s
--	);

fft_output_gen: for i in 0 to L+R generate

	-- #####################
	-- |complex|^2 
	-- #####################
	--cplx_magnitude_chx_inst: entity ip_library.complex_magnitude
	--generic map (
	--	G_DATA_WIDTH => C_FFT_DATA_WIDTH 
	--) port map (
	--	clk => sys_clk,
	--	-- complex (in)
	--	cplx_valid => fft_reframed_valid_s,
	--	cplx_data => fft_reframed_data_s(),
	--	cplx_last => fft_reframed_last_s,
	--	-- magnitude (out)
	--	magnitude_valid => cplx_magnitude_valid_s(i),
	--	magnitude_data => cplx_magnitude_data_s(i),
	--	magnitude_last => cplx_magnitude_last_s(i)
	--);

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
		data_out_data => cplx_magn_resized_data_s((i+1)*C_LOG2_OLED_Y_HEIGHT-1 downto i*C_LOG2_OLED_Y_HEIGHT),
		data_out_last => cplx_magn_resized_last_s(i)
	);

end generate; -- fft(out) 
	
	-- #########################
	-- ||^2 -> histogram
	-- #########################
	magn_2_histogram_chx_inst: entity ip_library.histogram
	generic map (
		G_HISTOGRAM_WIDTH => C_OLED_X_WIDTH,
		G_HISTOGRAM_HEIGHT => C_OLED_Y_HEIGHT
	) port map (
		clk => sys_clk,
		rst => '0',
		-- magnitude (in)
		magnitude_valid => cplx_magn_resized_valid_s(0),
		magnitude_data => cplx_magn_resized_data_s(C_LOG2_OLED_Y_HEIGHT-1 downto 0),
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

	-- #########################
	-- oled display
	-- #########################
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
