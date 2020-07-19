library ieee;
use     ieee.numeric_std.all;
use     ieee.std_logic_1164.all;

entity testbench is
end testbench;

architecture rtl of testbench is

	signal clk: std_logic := '0';
	
	signal cplx_ready, cplx_valid: std_logic := '0';
	signal cplx_data: std_logic_vector(15 downto 0) := x"0101"; 
	signal cplx_last: std_logic := '0';

	signal last_count: natural range 0 to 7 := 0;

	signal magnitude_valid: std_logic;
	signal magnitude_data: std_logic_vector(15 downto 0);
	signal magnitude_last: std_logic;

begin
	
	clk <= not(clk) after 5.0 ns;

	process (clk)
	begin
	if rising_edge (clk) then
		cplx_valid <= not(cplx_valid);
		cplx_last <= '0';
		
		if cplx_valid = '0' then
			if last_count < 7 then
				last_count <= last_count+1;
			else
				last_count <= 0;
				cplx_last <= '1';
			end if;
		end if;

		if cplx_valid = '1' then
			cplx_data(7 downto 0) <= std_logic_vector(
				unsigned(cplx_data(7 downto 0))+1
			);
			
			cplx_data(15 downto 8) <= std_logic_vector(
				unsigned(cplx_data(15 downto 8))+1
			);

		end if;
	end if;
	end process;

	dut: entity work.complex_magnitude
	generic map (
		G_DATA_WIDTH => 8
	) port map (
		clk => clk,
		-- DIN
		cplx_ready => cplx_ready,
		cplx_valid => cplx_valid,
		cplx_data => cplx_data,
		cplx_last => cplx_last,
		-- DOUT
		magnitude_valid => magnitude_valid,
		magnitude_data => magnitude_data,
		magnitude_last => magnitude_last
	);

end rtl;
