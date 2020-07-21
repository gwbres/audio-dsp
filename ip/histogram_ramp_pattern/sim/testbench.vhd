library ieee;
use     ieee.std_logic_1164.all;

entity testbench is
end testbench;

architecture rtl of testbench is

	signal clk: std_logic := '0';

	signal data_out_ready: std_logic;
	signal data_out_valid: std_logic;
	signal data_out_data: std_logic_vector(4 downto 0);
	signal data_out_last: std_logic;
begin
	
	clk <= not(clk) after 5.0 ns;

	dut: entity work.histogram_ramp_pattern
	generic map (
		G_HISTOGRAM_WIDTH => 128,
		G_HISTOGRAM_HEIGHT => 32
	) port map (
		clk => clk,
		data_out_ready => data_out_ready,
		data_out_valid => data_out_valid,
		data_out_data => data_out_data,
		data_out_last => data_out_last
	);

	fake_ready_out_gen: process
	begin
		data_out_ready <= '1';
		wait until rising_edge (data_out_valid);
		--data_out_ready <= '0';
		--wait until rising_edge (clk);
		--wait until rising_edge (clk);
	end process;

end rtl;
