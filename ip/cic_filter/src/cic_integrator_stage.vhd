library ieee;
use     ieee.numeric_std.all;
use     ieee.std_logic_1164.all;

entity cic_integrator_stage is
generic (
	G_DATA_WIDTH: natural := 16
);
port (
	clk: in std_logic;
	-- DATA/in
	data_in_valid: in std_logic;
	data_in_data: in std_logic_vector(G_DATA_WIDTH-1 downto 0);
	-- DATA/out
	data_out_valid: out std_logic;
	data_out_data: out std_logic_vector(G_DATA_WIDTH-1 downto 0)
);
end cic_integrator_stage;

architecture rtl of cic_integrator_stage is

	signal reg_valid: std_logic;
	signal reg_data, reg_olddata: std_logic_vector(G_DATA_WIDTH-1 downto 0) := (others => '0');
begin

	sync_integrator_stage: process (clk)
	begin
	if rising_edge (clk) then
		reg_valid <= '0';
		
		if data_in_valid = '1' then
			reg_valid <= '1';
			
			reg_data <= std_logic_vector(
				signed(data_in_data)
				+signed(reg_olddata)
			);

			reg_olddata <= reg_data;
		end if;
	end if;
	end process;

	data_out_valid <= reg_valid;
	data_out_data <= reg_data;

end rtl;
