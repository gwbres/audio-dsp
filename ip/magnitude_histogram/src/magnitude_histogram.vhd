library ieee;
use     ieee.math_real.all;
use     ieee.numeric_std.all;
use     ieee.std_logic_1164.all;

entity magnitude_histogram is
generic (
	G_HISTOGRAM_X_PIXELS: positive := 128; -- nb X pixels
	G_HISTOGRAM_Y_PIXELS: positive := 32; -- nb Y pixels
	G_DATA_WIDTH: positive := 16 -- input ||^2 data with
);
port (
	clk: in std_logic;
	-- magnitude (in)
	magnitude_valid: in std_logic;
	magnitude_data: in std_logic_vector(G_DATA_WIDTH-1 downto 0);
	magnitude_last: in std_logic;
	-- histogram (out)
	histogram_eol: out std_logic;
	histogram_eof: out std_logic;
	histogram_pxl: out std_logic_vector(8-1 downto 0)
);
end magnitude_histogram;

architecture rtl of magnitude_histogram is

	constant CLOG2_HISTOGRAM_X_PIXELS: natural := integer(ceil(log2(real(G_HISTOGRAM_X_PIXELS))));
	constant CLOG2_HISTOGRAM_Y_PIXELS: natural := integer(ceil(log2(real(G_HISTOGRAM_Y_PIXELS))));

	constant C_TOTAL_MEMORY_SIZE: natural := CLOG2_HISTOGRAM_X_PIXELS * (CLOG2_HISTOGRAM_Y_PIXELS+1);

	constant BLACK_SQUARE_PXL: std_logic_vector(8-1 downto 0) := (others => '0');
	constant WHITE_SQUARE_PXL: std_logic_vector(8-1 downto 0) := x"0000";

	signal bram_wr_en: std_logic;
	signal bram_waddr: std_logic_vector(CLOG2_HISTOGRAM_X_PIXELS-1 downto 0);
	signal bram_wdata: std_logic_vector(CLOG2_HISTOGRAM_Y_PIXELS+1-1 downto 0); -- +EOL
	
	signal bram_rd_en: std_logic;
	signal bram_raddr: std_logic_vector(CLOG2_HISTOGRAM_X_PIXELS-1 downto 0);
	signal bram_rdata: std_logic_vector(CLOG2_HISTOGRAM_Y_PIXELS+1-1 downto 0); -- +EOL
	signal bram_rd_eol: std_logic;
	signal bram_rd_data: std_logic_vector(CLOG2_HISTOGRAM_Y_PIXELS-1 downto 0); 

	signal restart: std_logic := 0;
	signal restart_ack: std_logic := '0';
	signal store_fft_frame: std_logic := '1';

	signal pix_row_count: natural range 0 to G_HISTOGRAM_Y_PIXELS-1 := 0;
begin

	-- push sane FFT/||^2 frames into buffer
	process (clk)
	begin
	if rising_edge (clk) then
		restart_ack <= '0';

		if magnitude_valid = '1' then
			if magnitude_last = '1' then
				if store_fft_frame = '1' then
					store_fft_frame <= '0';
				else
					if restart = '1' then
						restart_ack <= '1';
						store_fft_frame <= '1';
				end if;
			end if;
		end if;
	end if;
	end process;
	
	-- Xilinx BRAM
	sync_bram_wr_pointer: process (clk)
	begin
	if rising_edge (clk) then
		if bram_wr_en = '1' then
			if bram_wdata(bram_wdata'length-1) = '1' then
				bram_waddr <= (others => '0');
			else
				bram_waddr <= std_logic_vector(
					unsigned(bram_waddr)+1
				);
			end if;
		end if;
	end if;
	end process;

	bram_wr_en <= magnitude_valid and store_fft_frame;
	
	-- store EOL info
	bram_wdata(bram_wdata'length-1) <= magnitude_last;

	-- scale to Y axis
	bram_wdata(bram_wdata'length-2 downto 0) <= 
		magnitude_data(magnitude_data'length-1 downto magnitude_data'length-CLOG2_HISTOGRAM_Y_PIXELS); 
	
	xilinx_simple_bram: xpm_simple_sdpram
	generic map (
		MEMORY_SIZE => CLOG2_HISTOGRAM_X_PIXELS * (CLOG2_HISTOGRAM_Y_PIXELS+1), 
		-- A
		ADDR_WIDTH_A => CLOG2_HISTOGRAM_X_PIXELS,
		WRITE_DATA_WIDTH_A => CLOG2_HISTOGRAM_Y_PIXELS+1,
		BYTE_WRITE_WIDTH_A => (CLOG2_HISTOGRAM_Y_PIXELS+1)/4,
		-- B
		ADDR_WIDTH_B => CLOG2_HISTOGRAM_X_PIXELS,
		READ_DATA_WIDTH_B => (CLOG2_HISTOGRAM_Y_PIXELS+1),
		BYTE_WRITE_WIDTH_B => (CLOG2_HISTOGRAM_Y_PIXELS+1)/4,
		-- other
		AUTO_SLEEP_TIME => 0,
		CLOCKING_MODE => "common_clock",
		ECC_MODE => "no_ecc",
		MEMORY_INIT_FILE => "none",
		MEMORY_INIT_PARAM => "0",
		MEMORY_PRIMITIVE => "auto",
		MEMORY_OPTIMIZATION => "true",
		MESSAGE_CONTROL => 0,
		READ_LATENCY_B => 1,
		READ_RESET_VALUE_B => "0",
		USE_EMBEDDED_CONSTRAINT => 0,
		USE_MEM_INIT => 0,
		WAKEUP_TIME => "disable_sleep",
		WRITE_MODE_B => "no_change"
	) port map (
		-- Wr
		clka => clk,
		wea => x"F",
		ena => bram_wr_en,
		addra => bram_waddr,
		dina => bram_wdata,
		-- Rd
		clkb => clk,
		rstb => rst,
		regceb => '1',
		enb => bram_rd_en,
		doutb => bram_rdata,
		-- Other
		sleep => '0',
		sbiterrb => open,
		dbiterrb => open,
		injectsbiterra => '0',
		injectdbiterra => '0',

	);

	-- RD data
	bram_rd_eol <= bram_rdata(bram_rdata'length-1);
	bram_rd_data <= bram_rdata(bram_rdata'length-2 downto 0);

	-- convert ||^2 to histogram
	process (clk)
	begin
	if rising_edge (clk) then
		bram_rd_ready <= '0';

		histogram_eol <= '0';
		histogram_pxl <= BLACK_SQUARE_PXL;
		histogram_eof <= '0';

		if restart = '0' then
			if bram_rd_valid = '1' then
				bram_rd_ready <= '1';

				if unsigned(bram_rd_data) >= pix_row_count then
					histogram_pxl <= WHITE_SQUARE_PXL;
				end if;
					
				if bram_rd_eol = '1' then
					histogram_eol <= '1';

					bram_rd_addr <= (others => '0');
					if pix_row_count < G_HISTOGRAM_Y_PIXELS-1 then
						pix_row_count <= pix_row_count+1;
					else
						pix_row_count <= 0;
						histogram_eof <= '1';
						restart <= '1';
					end if;
				else
					bram_rd_addr <= std_logic_vector(
						unsigned(bram_rd_addr)+1
					);
				end if;
			end if;

		else -- asking for new buf storage
			if restart_ack = '1' then
				restart <= '0';
			end if;
		end if;
	end if;
	end process;

end rtl;
