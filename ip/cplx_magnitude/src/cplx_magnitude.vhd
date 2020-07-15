library ieee;
use     ieee.std_logic_1164.all;

entity cplx_magnitude is
generic (
	G_DATA_WIDTH: natural := 16
);
port (
	clk: in std_logic;
	-- complex/in
	cplx_ready: out std_logic;
	cplx_valid: in std_logic;
	cplx_data: in std_logic_vector(2*G_DATA_WIDTH-1 downto 0);
	-- magnitude/out
	magnitude_valid: out std_logic;
	magnitude_data: out std_logic_vector(2*G_DATA_WIDTH+1-1 downto 0)
);
end cplx_magnitude;

architecture rtl of cplx_magnitude is

	signal ab_reg_valid: std_logic;
	signal a_reg, b_reg: std_logic_vector(2*G_DATA_WIDTH-1 downto 0);

	signal c_reg_valid: std_logic;
	signal c_reg: std_logic_vector(2*G_DATA_WIDTH+1-1 downto 0);
begin

	cplx_ready <= '1';

	process (clk)
	begin
	if rising_edge (clk) then
		ab_reg_valid <= '0';

		if cplx_valid = '1' then
			ab_reg_valid <= '1';
			
			a_reg <= std_logic_vector(
				signed(cplx_data(2*G_DATA_WIDTH-1 downto G_DATA_WIDTH)
				* signed(cplx_data(2*G_DATA_WIDTH-1 downto G_DATA_WIDTH)
			);
			
			b_reg <= std_logic_vector(
				signed(cplx_data(G_DATA_WIDTH-1 downto 0)
				* signed(cplx_data(G_DATA_WIDTH-1 downto 0)
			);

		end if;
	end if;
	end process;

	process (clk)
	begin
	if rising_edge (clk) then
		c_reg_valid <= '0';
		if ab_reg_valid = '1' then
			c_reg_valid <= '1';
			c_reg <= std_logic_vector(signed(a_reg)+signed(b_reg));
		end if;
	end if;
	end process;

	magnitude_valid <= c_reg_valid;
	magnitude_data <= c_reg;

end rtl;
