library ieee;
use     ieee.std_logic_1164.all;

entity iir_filter is
generic (
	G_DATA_WIDTH: positive := 8
);
port (
	clk: in std_logic;
	-- stream (in)
	data_in_ready: out std_logic;
	data_in_valid: in std_logic;
	data_in_data: in std_logic_vector(G_DATA_WIDTH-1 downto 0);
	data_in_last: in std_logic;
	-- stream (out)
	data_out_valid: out std_logic;
	data_out_data: out std_logic_vector(G_DATA_WIDTH-1 downto 0);
	data_out_last: out std_logic
);
end iir_filter;

architecture rtl of iir_filter is

	signal fir_valid_s: std_logic;
	signal fir_data_s: std_logic_vector(G_DATA_WIDTH-1 downto 0);
	signal fir_last_s: std_logic;

	constant iir_array_type is array (0 to 9) of std_logic_vector(G_DATA_WIDTH-1 downto 0);
	signal 
begin

	data_in_ready <= '1';

	fir_stage_inst: entity work.iir_fir_stage
	port map (
		clk => clk,
		data_in_valid => data_in_valid,
		data_in_data => data_in_data,
		data_in_last => data_in_last,
		data_out_valid => fir_valid_s,
		data_out_data => fir_data_s,
		data_out_last => fir_last_s 
	);

	

end rtl;
