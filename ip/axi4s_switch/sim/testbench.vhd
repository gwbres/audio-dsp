library ieee;
use     ieee.numeric_std.all;
use     ieee.std_logic_1164.all;

entity testbench is
end testbench;

architecture rtl of testbench is

	signal clk: std_logic := '0';
	
	signal sel: std_logic_vector(0 downto 0);
	signal streams_in_valid: std_logic_vector(2-1 downto 0) := (others => '0');
	signal streams_in_data: std_logic_vector(2*8-1 downto 0) := (others => '0');
	signal streams_in_last: std_logic_vector(2-1 downto 0) := (others => '0');

	signal mod_count: natural range 0 to 3 := 0;
	
	type last_counters is array (0 to 2-1) of natural; 
	signal last_count: last_counters := (others => 0);

	signal stream_out_valid: std_logic;
	signal stream_out_data: std_logic_vector(8-1 downto 0);
	signal stream_out_last: std_logic;
begin
	
	clk <= not(clk) after 5.0 ns;

	stream_0_sim: process (clk)
	begin
	if rising_edge (clk) then
		streams_in_valid(0) <= not(streams_in_valid(0));
		streams_in_last(0) <= '0';

		if streams_in_valid(0) = '0' then
			if last_count(0) < 7 then
				last_count(0) <= last_count(0)+1;
			else
				last_count(0) <= 0;
				streams_in_last(0) <= '1';
			end if;
		end if;
		
		if streams_in_valid(0) = '1' then
			streams_in_data(7 downto 0) <= std_logic_vector (
				unsigned(streams_in_data(7 downto 0))+1
			);

		end if;
	end if;
	end process;
	
	stream_1_sim: process (clk)
	begin
	if rising_edge (clk) then
		streams_in_valid(1) <= '0';
		streams_in_last(1) <= '0';

		if streams_in_valid(0) = '1' then
			if mod_count < 3 then
				mod_count <= mod_count+1;
			else
				mod_count <= 0;

				streams_in_valid(1) <= '1';
				
				streams_in_data(15 downto 8) <= std_logic_vector (
					unsigned(streams_in_data(15 downto 8))+1
				);
				
				if last_count(1) < 7 then
					last_count(1) <= last_count(1)+1;
				else
					last_count(1) <= 0;
					streams_in_last(1) <= '1';
				end if;
			end if;

			end if;
	end if;
	end process;

	stream_sel_sim: process
	begin
		sel(0) <= '0'; 
		wait for 500 ns;
		wait until rising_edge (clk);
		sel(0) <= '1'; 
		wait for 500 ns;
		wait until rising_edge (clk);
	end process;

	dut: entity work.axi4s_switch
	generic map (
		G_UPDATE_ON_LAST => '0',
		G_NB_STREAMS => 2,
		G_DATA_WIDTH => 8
	) port map (
		clk => clk,
		sel => sel,
		-- DIN
		streams_in_valid => streams_in_valid,
		streams_in_data => streams_in_data,
		streams_in_last => streams_in_last,
		-- DOUT
		stream_out_valid => stream_out_valid,
		stream_out_data => stream_out_data,
		stream_out_last => stream_out_last
	);

end rtl;
