library ieee;
use     ieee.math_real.all;
use     ieee.numeric_std.all;
use     ieee.std_logic_1164.all;

entity axi4s_switch is
generic (
	G_UPDATE_ON_LAST: std_logic := '0';
	G_NB_STREAMS: positive := 2;
	G_DATA_WIDTH: positive := 16
);
port (
	clk: in std_logic;
	sel: in std_logic_vector(natural(ceil(log2(real(G_NB_STREAMS))))-1 downto 0);
	-- STREAMs /in
	streams_in_valid: in std_logic_vector(G_NB_STREAMS-1 downto 0);
	streams_in_data: in std_logic_vector(G_NB_STREAMS*G_DATA_WIDTH-1 downto 0);
	streams_in_last: in std_logic_vector(G_NB_STREAMS-1 downto 0);
	-- STREAM /out
	stream_out_valid: out std_logic;
	stream_out_data: out std_logic_vector(G_DATA_WIDTH-1 downto 0);
	stream_out_last: out std_logic
);
end axi4s_switch;

architecture rtl of axi4s_switch is

	signal reg_valid: std_logic;
	signal reg_data: std_logic_vector(G_DATA_WIDTH-1 downto 0) := (others => '0');
	signal reg_last: std_logic;

	signal stream_sel_id: integer range 0 to G_NB_STREAMS-1;
begin

update_sel_on_last_impl: if (G_UPDATE_ON_LAST) generate

	process (clk)
	begin
	if rising_edge (clk) then
		if streams_in_valid(stream_sel_id) = '1' then
			if streams_in_last(stream_sel_id) = '1' then
				stream_sel_id <= to_integer(unsigned(sel));
			end if;
		end if;
	end if;
	end process;

else generate
 
 stream_sel_id <= to_integer(unsigned(sel));

end generate;

	process (clk)
	begin
	if rising_edge (clk) then
		reg_valid <= '0';
		reg_last <= '0';
		if streams_in_valid(stream_sel_id) = '1' then
			reg_valid <= '1';
			reg_data <= streams_in_data((stream_sel_id+1)*G_DATA_WIDTH-1 downto stream_sel_id*G_DATA_WIDTH);
			if streams_in_last(stream_sel_id) = '1' then
				reg_last <= '1';
			end if;
		end if;
	end if;
	end process;

	stream_out_valid <= reg_valid;
	stream_out_data <= reg_data;
	stream_out_last <= reg_last;

end rtl;
