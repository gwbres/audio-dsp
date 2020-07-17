library ieee;
use     ieee.std_logic_1164.all;

library xpm;
use     xpm.vcomponents.all;

entity i2s_tx is
generic (
	G_DATA_WIDTH: natural := 24
);
port (
   clk: in std_logic;
	rst: in std_logic;
	-- TX buffer
	almost_empty: out std_logic;
	empty: out std_logic;
	underflow: out std_logic;
	almost_full: out std_logic;
	full: out std_logic;
	overflow: out std_logic;
	----------------------
   -- STEREO DATA
	----------------------
	stereo_in_ready: out std_logic;
	stereo_in_valid: in std_logic;
   stereo_in_data: in std_logic_vector(2*G_DATA_WIDTH-1 downto 0);
	----------------------
   -- I2S
	----------------------
   bclk: in std_logic;
   dout: out std_logic;
   lr: in std_logic
);
end i2s_tx;

architecture rtl of i2s_tx is

	signal fifo_full_s: std_logic;

	signal bclk_z1_s: std_logic := '0';
	signal bclk_rising_s: std_logic;

	signal lr_changed: std_logic := '0';
	signal lr_z1: std_logic;

	signal fifo_data_valid_s: std_logic;
	signal fifo_rd_en_s: std_logic;
	signal fifo_dout_s: std_logic_vector(2*G_DATA_WIDTH-1 downto 0);

	signal pointer_reg: natural range 0 to G_DATA_WIDTH-1 := G_DATA_WIDTH-1;
begin

	stereo_in_ready <= not(fifo_full_s);

	full <= fifo_full_s;

	----------------------------
	-- ASYNC TX Buffer
	----------------------------
	xilinx_async_fifo_inst: xpm_fifo_async
	generic map (
		CDC_SYNC_STAGES => 2,
		DOUT_REST_VALUE => "0",
		ECC_MODE => "no_ecc",
		FIFO_MEMORY_TYPE => "auto",
		FIFO_READ_LATENCY => 1,
		FIFO_WRITE_DEPTH => 16,
		FULL_RESET_VALUE => 0,
		PROG_EMPTY_THRESH => 4,
		PROG_FULL_THRESH => 12,
		READ_DATA_COUNT_WIDTH => 4, -- ceil(log2(16))
		READ_DATA_WIDTH => 2*G_DATA_WIDTH,
		READ_MODE => "std",
		RELATED_CLOCKS => 1,
		USE_ADV_FEATURES => "0707",
		WAKEUP_TIME => 0, -- disable sleep
		WR_DATA_COUNT_WIDTH => 4, -- ceil(log2(16))
		WRITE_DATA_WIDTH => 2*G_DATA_WIDTH
	) port map (
		-- Wr
		wr_clk => clk, 
		rst => rst,
		wr_rst_busy => open,
		wr_en => stereo_in_valid,
		din => stereo_in_data,
		wr_data_count => open,
		-- Rd
		rd_rst_busy => open,
		rd_clk => bclk,
		data_valid => fifo_data_valid_s,
		rd_en => fifo_rd_en_s,
		dout => fifo_dout_s,
		rd_data_count => open,
		-- other
		sleep => '0',
		injectsbiterr => '0',
		injectdbiterr => '0',
		sbiterr => open,
		dbiterr => open,
		full => fifo_full_s,
		empty => empty,
		overflow => overflow,
		underflow => underflow,
		prog_full => open,
		prog_empty => open,
		wr_ack => open,
		almost_full => almost_full,
		almost_empty => almost_empty
	);

	-------------------------------
	-- L/R changes detector 
	-------------------------------
	process (bclk)
	begin
	if rising_edge (bclk) then
		lr_z1 <= lr;
	end if;
	end process;

	lr_changed <= lr_z1 xor lr;

	---------------------------
	-- I2S TX
	---------------------------

	tx_fifo_reader: process (bclk)
	begin
	if rising_edge (bclk) then

		fifo_rd_en_s <= '0';

		-- read on L/R falling edge
		if lr_changed = '1' then
			if lr = '0' then
				fifo_rd_en_s <= '1';	
			end if;
		end if;

	end if;
	end process;

	i2s_tx_sync: process (bclk)
	begin
	if rising_edge (bclk) then
		if lr_changed = '1' then
			if lr = '0' then
				pointer_reg <= 2*G_DATA_WIDTH-1;
			end if;
		else
			if pointer_reg > 0 then
				pointer_reg <= pointer_reg-1;
			end if;
		end if;
	end if;
	end process;
	
	dout <= fifo_dout_s(pointer_reg); 

end rtl;
