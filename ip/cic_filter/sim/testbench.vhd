library ieee;
use     ieee.numeric_std.all;
use     ieee.std_logic_1164.all;

library std;
use     std.textio.all;

entity testbench is
end testbench;

architecture rtl of testbench is

	signal clk: std_logic := '0';

	constant C_CIC_R: natural := 8;
	constant C_CIC_N: natural := 2;
	constant C_DATA_WIDTH: natural := 16;

	-- data (in)
	signal data_in_valid: std_logic := '0';
	signal data_in_data: std_logic_vector(C_DATA_WIDTH-1 downto 0) := std_logic_vector(to_unsigned(1, C_DATA_WIDTH));
	signal data_in_last: std_logic := '0';

	signal tlast_count: natural range 0 to 7 := 0;

	-- data (out)
	signal data_out_valid: std_logic;
	signal data_out_data: std_logic_vector(C_DATA_WIDTH+C_CIC_R/4-1 downto 0);
	signal data_out_last: std_logic;
begin
	
	clk <= not(clk) after 5.0 ns;

	process (clk)
		file fd: text open read_mode is "stimulus.txt";
		variable row: line;
		variable v_slv: std_logic_vector(C_DATA_WIDTH-1 downto 0);
	begin
	if rising_edge (clk) then
		readline(fd, row);
		hread(row, v_slv);
		data_in_data <= v_slv;
		data_in_valid <= '1';

		if tlast_count < 7 then
			tlast_count <= tlast_count+1;
			data_in_last <= '0';
		else
			tlast_count <= 0;
			data_in_last <= '1';
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

	process (clk)
		file fd: text open write_mode is "output.txt";
		variable row: line;
	begin
	if rising_edge (clk) then
		if data_out_valid = '1' then
			write(row, data_out_data);
			writeline(fd, row);
		end if;
	end if;
	end process;

end rtl;
