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

	signal add_valid: std_logic;
	signal add_data: std_logic_vector(G_DATA_WIDTH+1-1 downto 0) := (others => '0');
	signal data_in_reg: std_logic_vector(G_DATA_WIDTH-1 downto 0) := (others => '0');

	signal sign_bits_high: std_logic;

	signal reg_valid: std_logic;
	signal reg_data, reg_olddata: std_logic_vector(G_DATA_WIDTH-1 downto 0) := (others => '0');
begin

	sync_presum_stage: process (clk)
	begin
	if rising_edge (clk) then
		add_valid <= '0';
		if data_in_valid = '1' then
			add_valid <= '1';
			add_data <= std_logic_vector (
				signed ('0' & data_in_data)
				+ signed ('0' & reg_data)
			);

			data_in_reg <= data_in_data;
		end if;
	end if;
	end process;

	sign_bits_high <= data_in_reg(data_in_reg'high) and reg_data(reg_data'high);

	sync_2s_saturation_logic: process (clk)
	begin
	if rising_edge (clk) then
		reg_valid <= '0';
		if add_valid = '1' then
			reg_valid <= '1';
			if add_data(add_data'high) = '1' then
				if sign_bits_high = '1' then
					-- 2's (negative) saturation
					reg_data(reg_data'high) <= '1';
					reg_data(reg_data'high-1 downto 0) <= (others => '0');
				else
					-- 2's (positive) saturation
					reg_data(reg_data'high) <= '0';
					reg_data(reg_data'high-1 downto 0) <= (others => '1');
				end if;
			else
				reg_data <= add_data(G_DATA_WIDTH-1 downto 0); 
			end if;
		end if;
	end if;
	end process;

	data_out_valid <= reg_valid;
	data_out_data <= reg_data;

end rtl;
