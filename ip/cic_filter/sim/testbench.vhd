library ieee;
use     ieee.numeric_std.all;
use     ieee.std_logic_1164.all;

entity testbench is
end testbench;

architecture rtl of testbench is

	signal clk: std_logic := '0';

	constant C_CIC_R: natural := 8;
	constant C_CIC_N: natural := 2;
	constant C_DATA_WIDTH: natural := 8;

	-- data (in)
	signal data_in_valid: std_logic := '0';
	signal data_in_data: std_logic_vector(C_DATA_WIDTH-1 downto 0) := std_logic_vector(to_unsigned(1, C_DATA_WIDTH));
	signal data_in_last: std_logic;

	-- data (out)
	signal data_out_valid: std_logic;
	signal data_out_data: std_logic_vector(C_DATA_WIDTH+C_CIC_R/4-1 downto 0);
	signal data_out_last: std_logic;
begin
	
	clk <= not(clk) after 5.0 ns;

	process (clk)
	begin
	if rising_edge (clk) then
		data_in_valid <= not(data_in_valid);
		data_in_last <= '0';
		if data_in_valid = '1' then
			data_in_data <= std_logic_vector(unsigned(data_in_data)+1);
		end if;
	end if;
	end process;

	dut: entity work.cic_filter
	generic map (
		G_IS_DECIMATOR => '1',
		G_CIC_R => C_CIC_R,
		G_CIC_N => C_CIC_N,
		G_DATA_WIDTH => C_DATA_WIDTH
	) port map (
		clk => clk,
		-- data (in)
		data_in_valid => data_in_valid,
		data_in_data => data_in_data,
		data_in_last => data_in_last,
		-- data (out)
		data_out_valid => data_out_valid,
		data_out_data => data_out_data,
		data_out_last => data_out_last
	);

end rtl;
