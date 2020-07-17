library ieee;
use     ieee.std_logic_1164.all;

entity i2s is
generic (
	G_DATA_WIDTH: natural := 24
);
port (
   clk: in std_logic;
	rst: in std_logic;
	----------------------
	-- TX buffer
	----------------------
	tx_almost_empty: out std_logic;
	tx_empty: out std_logic;
	tx_underflow: out std_logic;
	tx_almost_full: out std_logic;
	tx_full: out std_logic;
	tx_overflow: out std_logic;
	----------------------
   -- Stereo Stream (in)
	----------------------
	stereo_in_ready: out std_logic;
	stereo_in_valid: in std_logic;
   stereo_in_data: in std_logic_vector(2*G_DATA_WIDTH-1 downto 0);
	----------------------
   -- Stereo Stream (out)
	----------------------
	stereo_out_valid: out std_logic;
   stereo_out_data: out std_logic_vector(2*G_DATA_WIDTH-1 downto 0);
	----------------------
   -- I2S
	----------------------
   bclk: in std_logic;
   din: in std_logic;
   dout: out std_logic;
   lr: in std_logic
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
	) port map (
		clk => clk,
		-- stereo stream
		stereo_valid => stereo_out_valid,
		stereo_data => stereo_out_data,
		-- i2s
		bclk => bclk,
		din => din,
		lr => lr
	);

	--------------------------
	-- I2S TX 
	--------------------------
	i2s_tx_inst: entity work.i2s_tx
	generic map (
		G_DATA_WIDTH => G_DATA_WIDTH
	) port map (
		clk => clk,
		rst => rst,
		-- status
		almost_empty => tx_almost_empty,
		empty => tx_empty,
		underflow => tx_underflow,
		almost_full => tx_almost_full,
		full => tx_full,
		overflow => tx_overflow,
		-- stereo stream
		stereo_ready => stereo_in_ready,
		stereo_valid => stereo_in_valid,
		stereo_data => stereo_in_data,
		-- i2s
		bclk => bclk,
		dout => dout,
		lr => lr
	);

end rtl;
