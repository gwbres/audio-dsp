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
	oled_sclk: out std_logic;
	oled_sdin: out std_logic;
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

	-- L+R framer
	signal framer_valid_s: std_logic_vector(L+R downto 0) := (others => '0');
	signal framer_data_s: std_logic_vector(C_STEREO_DATA_WIDTH-1 downto 0) := (others => '0'); 
	signal framer_last_s: std_logic_vector(L+R downto 0) := (others => '0');

	-- CIC filters
	signal cic_decim_valid_s: std_logic_vector(L+R downto 0) := (others => '0');
	signal cic_decim_data_s: std_logic_vector(C_STEREO_DATA_WIDTH-1 downto 0) := (others => '0'); 
	signal cic_decim_last_s: std_logic_vector(L+R downto 0) := (others => '0');
	
	signal cic_decim_valid_s: std_logic_vector(L+R downto 0) := (others => '0');
	signal cic_decim_data_s: std_logic_vector(C_STEREO_DATA_WIDTH-1 downto 0) := (others => '0'); 
	signal cic_decim_last_s: std_logic_vector(L+R downto 0) := (others => '0');

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
	--audio_tx_data_s <= cic_interp_data_s(L) & cic_interp_data_s(R);
	
	-- #######################
	-- Time domain
	-- #######################
	--time_domain_inst: entity work.time_domain_path
	--port map (
	--	sys_clk => sys_clk,
	--	-- codec rx
	--	data_rx_valid => audio_rx_valid_s,
	--	data_rx_data => audio_rx_data_s,
	--	-- cic decim. filters
	--	cic_decim_valid_out => cic_decim_valid_s,
	--	cic_decim_data_out => cic_decim_data_s,
	--	cic_decim_last_out => cic_decim_last_s
	--	-- cic interp. filters
	--);

	-- #######################
	-- Frequency domain
	-- #######################
	frequency_domain_inst: entity work.frequency_data_path
	port map (
		sys_clk => sys_clk,
		-- demux
		demux_sel => (others => '0'),
		-- cic filters
		cic_valid_in => cic_decim_valid_s,
		cic_data_in => cic_decim_data_s,
		cic_last_in => cic_decim_last_s,
		-- oled
		oled_sclk => oled_sclk,
		oled_sdin => oled_sdin,
		oled_dc => oled_dc,
		oled_res => oled_res,
		oled_vbat => oled_vbat,
		oled_vdd => oled_vdd
	);
	
end rtl;
