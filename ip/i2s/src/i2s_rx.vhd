library ieee;
use     ieee.std_logic_1164.all;

entity i2s_rx is
generic (
	G_DATA_WIDTH: natural := 24
);
port (
   clk: in std_logic;
	----------------------
   -- STEREO DATA
	----------------------
	stereo_valid: out std_logic;
   stereo_data: out std_logic_vector(2*G_DATA_WIDTH-1 downto 0);
	----------------------
   -- I2S
	----------------------
   bclk: in std_logic;
   din: in std_logic;
   lr: in std_logic
);
end i2s_rx;

architecture rtl of i2s_rx is

	signal bclk_rsync_reg: std_logic_vector(2 downto 0) := (others => '0');
	signal din_rsync_reg: std_logic_vector(2 downto 0) := (others => '0');
	signal lr_rsync_reg: std_logic_vector(2 downto 0) := (others => '0');

	signal bclk_rsync: std_logic;
	signal din_rsync: std_logic;
	signal lr_rsync: std_logic;

	signal bclk_z1_s: std_logic := '0';
	signal bclk_rising_s: std_logic;

	signal lr_delayed_s: std_logic := '0';
	signal lr_delayed_z1_s: std_logic := '0';
	signal lr_delayed_changed_s: std_logic;

	signal valid_reg: std_logic := '0';
	signal bit_count_reg: natural range 0 to G_DATA_WIDTH-1 := G_DATA_WIDTH-1;
	signal data_r_reg, data_l_reg: std_logic_vector(G_DATA_WIDTH-1 downto 0) := (others => '0');
begin

	----------------------------
	-- I2S => sys_clk resync.
	----------------------------
	process (clk)
	begin
	if rising_edge (clk) then
		bclk_rsync_reg <= bclk_rsync_reg(bclk_rsync_reg'high-1 downto 0) & bclk;
		din_rsync_reg <= din_rsync_reg(din_rsync_reg'high-1 downto 0) & din;
		lr_rsync_reg <= lr_rsync_reg(lr_rsync_reg'high-1 downto 0) & lr;
	end if;
	end process;

	bclk_rsync <= bclk_rsync_reg(bclk_rsync_reg'high);
	din_rsync <= din_rsync_reg(din_rsync_reg'high);
	lr_rsync <= lr_rsync_reg(lr_rsync_reg'high);
	
	----------------------------
	-- BCLK rising edge detector
	----------------------------
	process (clk)
	begin
	if rising_edge (clk) then
		bclk_rising_s <= '0';
		bclk_z1_s <= bclk_rsync;
		if bclk_rsync = '1' and bclk_z1_s = '0' then
			bclk_rising_s <= '1';
		end if;
	end if;
	end process;

	-------------------------------
	-- shift L/R signal by one BCLK 
	-------------------------------
	process (clk)
	begin
	if rising_edge (clk) then
		if bclk_rising_s = '1' then
			lr_delayed_s <= lr_rsync;
		end if;

		lr_delayed_z1_s <= lr_delayed_s;
	end if;
	end process;

	lr_delayed_changed_s <= lr_delayed_s xor lr_delayed_z1_s;

	---------------------------
	-- I2S RX
	---------------------------
	sync_i2s_rx: process (clk)
	begin
	if rising_edge (clk) then
		valid_reg <= '0';

		if lr_delayed_changed_s = '1' then
			bit_count_reg <= G_DATA_WIDTH-1;
			-- valid when L+R done
			if lr_delayed_s = '0' then
				valid_reg <= '1';
			end if;
		end if;

		if bclk_rising_s = '1' then -- sampling on rising edge
			-- stereo sampling
			if lr_delayed_s = '1' then
				data_r_reg(bit_count_reg) <= din_rsync;
			else
				data_l_reg(bit_count_reg) <= din_rsync;
			end if;

			-- pointer / MSBF
			if bit_count_reg = 0 then
				bit_count_reg <= G_DATA_WIDTH-1;
			else
				bit_count_reg <= bit_count_reg-1;
			end if;
		end if;
	end if;
	end process;

	stereo_valid <= valid_reg;
	stereo_data <= data_l_reg & data_r_reg;

end rtl;
