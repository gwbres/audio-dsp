library ieee;
use     ieee.numeric_std.all;
use     ieee.std_logic_1164.all;

entity signed_rounding is
generic (
	G_DIN_WIDTH: natural := 20;
	G_DOUT_WIDTH: natural := 16
);
port (
	clk: in std_logic;
	-- data (in) 
	data_in_valid: in std_logic;
	data_in_data: in std_logic_vector(G_DIN_WIDTH-1 downto 0);
	data_in_last: in std_logic;
	-- data (out) 
	data_out_valid: out std_logic;
	data_out_data: out std_logic_vector(G_DOUT_WIDTH-1 downto 0);
	data_out_last: out std_logic
);
end signed_rounding;

architecture rtl of signed_rounding is

	signal lsb_reg: std_logic;
	signal msb_reg: std_logic_vector(G_DOUT_WIDTH-1 downto 0);

	signal round_valid: std_logic;
	signal round_data: std_logic_vector(G_DOUT_WIDTH-1 downto 0) := (others => '0');
	signal round_last: std_logic;
begin

	lsb_reg <= data_in_data(G_DOUT_WIDTH-1);
	msb_reg <= data_in_data(G_DIN_WIDTH-1 downto G_DIN_WIDTH-G_DOUT_WIDTH);
	
	sync_output_rounding: process (clk)
	begin
	if rising_edge (clk) then
		round_valid <= '0';
		round_last <= '0';
		if data_in_valid = '1' then 
			round_valid <= '1';
			if lsb_reg = '1' then
				round_data <= std_logic_vector(signed(msb_reg)+1);
			else
				round_data <= msb_reg;
			end if;

			if data_in_last = '1' then
				round_last <= '1';
			end if;
		end if;
	end if;
	end process;

	data_out_valid <= round_valid;
	data_out_data <= round_data;
	data_out_last <= roud_last;

end rtl;
