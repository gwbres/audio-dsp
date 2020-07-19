library ieee;
use     ieee.numeric_std.all;
use     ieee.std_logic_1164.all;

entity complex_magnitude is
generic (
	G_DATA_WIDTH: natural := 16
);
port (
	clk: in std_logic;
	-- complex/in
	cplx_ready: out std_logic;
	cplx_valid: in std_logic;
	cplx_data: in std_logic_vector(2*G_DATA_WIDTH-1 downto 0);
	cplx_last: in std_logic;
	-- magnitude/out
	magnitude_valid: out std_logic;
	magnitude_data: out std_logic_vector(2*G_DATA_WIDTH-1 downto 0);
	magnitude_last: out std_logic
);
end complex_magnitude;

architecture rtl of complex_magnitude is

	signal ab_reg_valid: std_logic := '0';
	signal a_reg, b_reg: std_logic_vector(2*G_DATA_WIDTH-1 downto 0) := (others => '0');
	signal ab_reg_last: std_logic := '0';

	signal c_reg_valid: std_logic := '0';
	signal c_reg: std_logic_vector(2*G_DATA_WIDTH-1 downto 0) := (others => '0');
	signal c_reg_last: std_logic := '0';
begin

	cplx_ready <= '1';

	process (clk)
	begin
	if rising_edge (clk) then
		ab_reg_valid <= '0';
		ab_reg_last <= '0';

		if cplx_valid = '1' then
			ab_reg_valid <= '1';
			
			a_reg <= std_logic_vector(
				signed(cplx_data(2*G_DATA_WIDTH-1 downto G_DATA_WIDTH))
				* signed(cplx_data(2*G_DATA_WIDTH-1 downto G_DATA_WIDTH))
			);
			
			b_reg <= std_logic_vector(
				signed(cplx_data(G_DATA_WIDTH-1 downto 0))
				* signed(cplx_data(G_DATA_WIDTH-1 downto 0))
			);

			if cplx_last = '1' then
				ab_reg_last <= '1';
			end if;

		end if;
	end if;
	end process;

	process (clk)
	begin
	if rising_edge (clk) then
		c_reg_valid <= '0';
		c_reg_last <= '0';
		if ab_reg_valid = '1' then
			c_reg_valid <= '1';
			c_reg <= std_logic_vector(signed(a_reg)+signed(b_reg));

			if ab_reg_last = '1' then
				c_reg_last <= '1';
			end if;
		end if;
	end if;
	end process;

	magnitude_valid <= c_reg_valid;
	magnitude_data <= c_reg;
	magnitude_last <= c_reg_last;

end rtl;
