library ieee;
use     ieee.numeric_std.all;
use     ieee.std_logic_1164.all;

entity cic_filter is
generic (
	G_IS_DECIMATOR: std_logic := '1'; -- '0': interpolation filter
	G_CIC_R: positive := 8; -- decimation ratio
	G_CIC_N: positive := 8; -- nb stages
	G_CIC_M: positive := 1; -- time delay =1 or 2
	G_DATA_WIDTH: natural := 16
);
port (
	clk: in std_logic;
	-- DATA/in
	data_in_valid: in std_logic;
	data_in_data: in std_logic_vector(G_DATA_WIDTH-1 downto 0);
	-- DATA/out
	data_out_valid: out std_logic;
	data_out_data: out std_logic_vector(G_DATA_WIDTH-1 downto 0)
);
end cic_filter;

architecture rtl of cic_filter is

begin

g_cic_decimation_filter_gen: generate if (G_IS_DECIMATOR) generate
	
	cic_decim_filter_inst: entity work.cic_decimator
	generic map (
		G_CIC_R => G_CIC_R,
		G_CIC_N => G_CIC_N,
		G_CIC_M => G_CIC_M,
		G_DATA_WIDTH => G_DATA_WIDTH
	) port map (
		clk => clk,
		data_in_valid => data_in_valid,
		data_in_data => data_in_data,
		data_out_valid => data_out_valid,
		data_out_data => data_out_data
	);

else

	cic_interp_filter_inst: entity work.cic_interpolator
	generic map (
		G_CIC_R => G_CIC_R,
		G_CIC_N => G_CIC_N,
		G_CIC_M => G_CIC_M,
		G_DATA_WIDTH => G_DATA_WIDTH
	) port map (
		clk => clk,
		data_in_valid => data_in_valid,
		data_in_data => data_in_data,
		data_out_valid => data_out_valid,
		data_out_data => data_out_data
	);

end if;

end rtl;
