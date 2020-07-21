library ieee;
use     ieee.math_real.all;
use     ieee.numeric_std.all;
use     ieee.std_logic_1164.all;

entity histogram_ramp_pattern is
generic (
	G_HISTOGRAM_WIDTH: positive := 128;
	G_HISTOGRAM_HEIGHT: positive := 32
);
port (
	clk: in std_logic;
	-- stream (out)
	data_out_ready: in std_logic;
	data_out_valid: out std_logic;
	data_out_data: out std_logic_vector(integer(ceil(log2(real(G_HISTOGRAM_HEIGHT))))-1 downto 0);
	data_out_last: out std_logic
);
end entity histogram_ramp_pattern;

architecture rtl of histogram_ramp_pattern is

	signal pxl_count: natural range 0 to G_HISTOGRAM_WIDTH-1 := 0;
	constant C_DELTA: natural := G_HISTOGRAM_WIDTH / G_HISTOGRAM_HEIGHT;
	signal mod_count: natural range 0 to C_DELTA-1 := 0;
	
	signal valid_reg: std_logic := '0';
	signal data_reg: std_logic_vector(data_out_data'length-1 downto 0) := (others => '0'); 
	signal last_reg: std_logic := '0';

begin

	process (clk)
	begin
	if rising_edge (clk) then
		valid_reg <= '0';
		last_reg <= '0';
		if data_out_ready = '1' then
			valid_reg <= '1';
			if pxl_count < G_HISTOGRAM_WIDTH-1 then
				pxl_count <= pxl_count+1;
			else
				pxl_count <= 0;
				last_reg <= '1';
			end if;
		end if;
	end if;
	end process;

	process (clk)
	begin
	if rising_edge (clk) then
		if data_out_ready = '1' and valid_reg = '1' then
			if mod_count < C_DELTA-1 then
				mod_count <= mod_count+1;
			else
				mod_count <= 0;
				data_reg <= std_logic_vector(unsigned(data_reg)+1);
			end if;
		end if;
	end if;
	end process;

	data_out_valid <= valid_reg;
	data_out_data <= data_reg;
	data_out_last <= last_reg;

end rtl;
