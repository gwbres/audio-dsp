library ieee;
use     ieee.std_logic_1164.all;

entity axi4s_reframer is
generic (
	G_FRAME_LENGTH: positive := 1024;
	G_DATA_WIDTH: positive := 8
);
port (
	clk: in std_logic;
	-- stream (in)
	stream_in_valid: in std_logic;
	stream_in_data: in std_logic_vector(G_DATA_WIDTH-1 downto 0);
	stream_in_last: in std_logic;
	-- stream (out)
	stream_out_valid: out std_logic;
	stream_out_data: out std_logic_vector(G_DATA_WIDTH-1 downto 0);
	stream_out_last: out std_logic
);
end axi4s_reframer;

architecture rtl of axi4s_reframer is

	signal wait_for_tlast: std_logic := '1';

	signal valid_reg: std_logic := '0';
	signal data_reg: std_logic_vector(G_DATA_WIDTH-1 downto 0) := (others => '0');
	signal last_counter: natural range 0 to G_FRAME_LENGTH-1 := 0;
	signal last_reg: std_logic := '0';
begin

	process (clk)
	begin
	if rising_edge (clk) then
		valid_reg <= '0';
		last_reg <= '0';

		if wait_for_tlast = '1' then
			if stream_in_valid = '1' then
				if stream_in_last = '1' then
					wait_for_tlast <= '0';
				end if;
			end if;
		else
			if stream_in_valid = '1' then
				valid_reg <= '1';
				data_reg <= stream_in_data;
				if last_counter < G_FRAME_LENGTH-1 then
					last_counter <= last_counter+1;
				else
					last_reg <= '1';
					last_counter <= 0;
					wait_for_tlast <= '1';
				end if;
			end if;
		end if;
	end if;
	end process;

	stream_out_valid <= valid_reg;
	stream_out_data <= data_reg;
	stream_out_last <= last_reg;

end rtl;
