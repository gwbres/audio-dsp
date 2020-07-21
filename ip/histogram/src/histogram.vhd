library ieee;
use     ieee.math_real.all;
use     ieee.numeric_std.all;
use     ieee.std_logic_1164.all;

library xpm;
use     xpm.vcomponents.all;

entity histogram is
generic (
	G_HISTOGRAM_WIDTH: positive := 128; 
	G_HISTOGRAM_HEIGHT: positive := 32
);
port (
	clk: in std_logic;
	rst: in std_logic;
	-- magnitude (in)
	magnitude_ready: out std_logic;
	magnitude_valid: in std_logic;
	magnitude_data: in std_logic_vector(integer(ceil(log2(real(G_HISTOGRAM_HEIGHT))))-1 downto 0);
	magnitude_last: in std_logic;
	-- oled ctrl
	oled_disp_on_ready: in std_logic;
	oled_disp_on_start: out std_logic;
	oled_disp_off_ready: in std_logic;
	oled_disp_off_start: out std_logic;
	-- oled wdata
	oled_wr_ready: in std_logic;
	oled_wr_start: out std_logic;
	oled_wr_addr: out std_logic_vector(8 downto 0);
	oled_wr_data: out std_logic_vector(7 downto 0)
);
end histogram;

architecture rtl of histogram is

	-- OLED ctrl
	signal oled_init_done_s: std_logic;
	signal oled_disp_on_start_s: std_logic := '1';
	
	constant C_LOG2_HISTOGRAM_WIDTH: natural := integer(log2(real(G_HISTOGRAM_WIDTH)));
	constant C_LOG2_HISTOGRAM_HEIGHT: natural := integer(log2(real(G_HISTOGRAM_HEIGHT)));

	constant C_RAM_ADDR_WIDTH: natural := C_LOG2_HISTOGRAM_WIDTH;
	constant C_RAM_DATA_WIDTH: natural := C_LOG2_HISTOGRAM_HEIGHT+1; -- store EOL
	constant C_RAM_MEMORY_SIZE: natural := G_HISTOGRAM_WIDTH * C_RAM_DATA_WIDTH; -- (bits) 

	signal bram_wr_en: std_logic;
	signal bram_waddr: std_logic_vector(C_RAM_ADDR_WIDTH-1 downto 0) := (others => '0');
	signal bram_wdata: std_logic_vector(C_RAM_DATA_WIDTH-1 downto 0); 
	
	signal bram_rd_en: std_logic := '0';
	signal bram_raddr: std_logic_vector(C_RAM_ADDR_WIDTH-1 downto 0) := (others => '0');
	signal bram_rdata: std_logic_vector(C_RAM_DATA_WIDTH-1 downto 0);
	signal bram_rd_eol: std_logic;
	signal bram_rd_data: std_logic_vector(C_RAM_DATA_WIDTH-2 downto 0); 

	signal bram_rd_en_z1: std_logic := '0';
	signal bram_rd_eol_z1: std_logic := '0';
	signal bram_rd_data_z1: std_logic_vector(C_RAM_DATA_WIDTH-2 downto 0) := (others => '0');

	signal restart_s: std_logic := '0';
	signal restart_ack_s: std_logic := '0';
	signal store_fft_frame: std_logic := '1';

	signal line_count: natural range 0 to G_HISTOGRAM_HEIGHT-1 := 0;

	constant BLACK_PXL: std_logic_vector(8-1 downto 0) := (others => '0');
	constant WHITE_PXL: std_logic_vector(8-1 downto 0) := (others => '1');

	signal oled_wr_start_s: std_logic;
	signal oled_wr_data_s: std_logic_vector(7 downto 0) := BLACK_PXL;
	signal oled_wr_addr_s: std_logic_vector(8 downto 0) := (others => '0');
begin

	magnitude_ready <= '0';

	oled_init_done_s <= '1'; --not(oled_disp_on_start_s);
	oled_disp_on_start <= '1'; --oled_disp_on_start_s;
	oled_disp_off_start <= '0';

	-- push sane FFT/||^2 frames into buffer
	process (clk)
	begin
	if rising_edge (clk) then
		restart_ack_s <= '0';

		if magnitude_valid = '1' then
			if magnitude_last = '1' then
				if store_fft_frame = '1' then
					store_fft_frame <= '0';
				else
					if restart_s = '1' then
						restart_ack_s <= '1';
						store_fft_frame <= '1';
					end if;
				end if;
			end if;
		end if;
	end if;
	end process;
	
	-- Xilinx BRAM
	bram_wr_en <= magnitude_valid and store_fft_frame;
	
	-- store EOL info
	bram_wdata(bram_wdata'length-1) <= magnitude_last;

	-- keep MSB: resize/fit to Y axis
	bram_wdata(bram_wdata'length-2 downto 0) <= 
		magnitude_data(magnitude_data'length-1 downto magnitude_data'length-C_LOG2_HISTOGRAM_HEIGHT); 
	
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

	xilinx_simple_bram: xpm_memory_sdpram
	generic map (
		MEMORY_SIZE => C_RAM_MEMORY_SIZE, 
		-- A
		ADDR_WIDTH_A => C_RAM_ADDR_WIDTH,
		WRITE_DATA_WIDTH_A => C_RAM_DATA_WIDTH,
		BYTE_WRITE_WIDTH_A => C_RAM_DATA_WIDTH, 
		-- B
		ADDR_WIDTH_B => C_RAM_ADDR_WIDTH,
		READ_DATA_WIDTH_B => C_RAM_DATA_WIDTH,
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
		wea => (others => '1'),
		ena => bram_wr_en,
		addra => bram_waddr,
		dina => bram_wdata,
		-- Rd
		clkb => clk,
		rstb => rst,
		regceb => '1',
		enb => bram_rd_en,
		addrb => bram_raddr,
		doutb => bram_rdata,
		-- Other
		sleep => '0',
		sbiterrb => open,
		dbiterrb => open,
		injectsbiterra => '0',
		injectdbiterra => '0'
	);

	-- RD data
	bram_rd_eol <= bram_rdata(bram_rdata'high);
	bram_rd_data <= bram_rdata(bram_rdata'high-1 downto 0);

	bram_rd_logic: process (clk)
	begin
	if rising_edge (clk) then
		oled_wr_start_s <= '0';
		if store_fft_frame = '0' then -- Wr/not busy
			if restart_s = '0' then -- reading allowed
				if oled_wr_ready = '1' then -- oled.ctrl ready
					bram_rd_en <= '1';
					oled_wr_start_s <= '1';
				end if;
			end if;
		end if;
	end if;
	end process;

	bram_latency_proc: process (clk)
	begin
	if rising_edge (clk) then
		bram_rd_en_z1 <= bram_rd_en;
		if bram_rd_en = '1' then
			bram_raddr <= std_logic_vector(unsigned(bram_raddr)+1);
			bram_rd_eol_z1 <= bram_rd_eol;
			bram_rd_data_z1 <= bram_rd_data;
		end if;
	end if;
	end process;

	sync_mag2hist_mapping: process (clk)
	begin
	if rising_edge (clk) then
		
		if oled_init_done_s = '1' then -- streaming is allowed
			if restart_s = '0' then 
				if bram_rd_en_z1 = '1' then -- reading sample

					if unsigned(bram_rd_data_z1) >= line_count-1 then
						oled_wr_data_s <= WHITE_PXL;
					else
						oled_wr_data_s <= BLACK_PXL;
					end if;
					
					if bram_rd_eol_z1 = '1' then -- EOL
						if line_count < G_HISTOGRAM_HEIGHT-1 then
							line_count <= line_count+1;
						else
							restart_s <= '1';
						end if;
					end if;
				end if;
			else
				if restart_ack_s = '1' then
					restart_s <= '0';
				end if;
			end if;
		end if;
	end if;
	end process;

	oled_wr_start <= oled_wr_start_s;
	oled_wr_addr <= oled_wr_addr_s;
	oled_wr_data <= oled_wr_data_s;

end rtl;
