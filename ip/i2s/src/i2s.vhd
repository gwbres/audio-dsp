library ieee;
use     ieee.std_logic_1164.all;

entity i2s is
generic (
	G_DATA_WIDTH: natural := 24
);
port (
   clk: in std_logic;
	----------------------
   -- STEREO DATA/in
	----------------------
	stereo_in_ready: out std_logic;
	stereo_in_valid: in std_logic;
   stereo_in_data: in std_logic_vector(2*G_DATA_WIDTH-1 downto 0);
	----------------------
   -- STEREO DATA/out
	----------------------
	stereo_out_valid: out std_logic;
   stereo_out_data: out std_logic_vector(2*G_DATA_WIDTH-1 downto 0);
	----------------------
   -- I2S
	----------------------
   i2s_bclk: in std_logic;
   i2s_din: in std_logic;
   i2s_dout: out std_logic;
   i2s_lr: in std_logic
);
end i2s;

architecture rtl of i2s is

begin
	
	---------------------------
	-- I2S RX
	---------------------------
	i2s_rx_inst: entity work.i2s_rx
	generic map (
		G_DATA_WIDTH => G_DATA_WIDTH
	port map (
		clk => clk,
		stereo_valid => stereo_out_valid,
		stereo_data => stereo_out_data,
		i2s_bclk => i2s_bclk,
		i2s_din => i2s_din,
		i2s_lr => i2s_lr
	);

	--------------------------
	-- I2S TX 
	--------------------------
	i2s_tx_inst: entity work.i2s_tx
	generic map (
		G_DATA_WIDTH => G_DATA_WIDTH
	port map (
		clk => clk,
		stereo_ready => stereo_in_ready,
		stereo_valid => stereo_in_valid,
		stereo_data => stereo_in_data,
		i2s_bclk => i2s_bclk,
		i2s_dout => i2s_dout,
		i2s_lr => i2s_lr
	);

end rtl;
