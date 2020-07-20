library ieee;
use     ieee.numeric_std.all;
use     ieee.std_logic_1164.all;

entity cic_integrator_stage is
generic (
	G_DATA_WIDTH: natural := 16
);
port (
	clk: in std_logic;
	-- data (in) 
	data_in_valid: in std_logic;
	data_in_data: in std_logic_vector(G_DATA_WIDTH-1 downto 0);
	data_in_last: in std_logic;
	-- data (out)
	data_out_valid: out std_logic;
	data_out_data: out std_logic_vector(G_DATA_WIDTH-1 downto 0);
	data_out_last: out std_logic
);
end cic_integrator_stage;

architecture rtl of cic_integrator_stage is

	signal pre_add_valid: std_logic;
	signal pre_add_A_reg, pre_add_B_reg: std_logic_vector(G_DATA_WIDTH-1 downto 0) := (others => '0');
	signal pre_add_A_reg_z1, pre_add_B_reg_z1: std_logic_vector(G_DATA_WIDTH-1 downto 0);
	signal pre_add_data: std_logic_vector(G_DATA_WIDTH-1 downto 0) := (others => '0');
	signal pre_add_last: std_logic;

	signal data_in_reg: std_logic_vector(G_DATA_WIDTH-1 downto 0) := (others => '0');

	signal pre_add_overflow: std_logic;
	signal both_positive, both_negative: std_logic;

	signal reg_valid: std_logic;
	signal reg_data: std_logic_vector(G_DATA_WIDTH-1 downto 0) := (others => '0');
	signal reg_last: std_logic;

begin

	pre_add_A_reg <= data_in_data;
	pre_add_B_reg <= reg_data; 

	sync_presum_stage: process (clk)
	begin
	if rising_edge (clk) then
		pre_add_valid <= '0';
		pre_add_last <= '0';
		
		if data_in_valid = '1' then
			pre_add_valid <= '1';
			pre_add_data <= std_logic_vector (
				signed (pre_add_A_reg)
				+ signed (pre_add_B_reg)
			);

			pre_add_A_reg_z1 <= pre_add_A_reg;
			pre_add_B_reg_z1 <= pre_add_B_reg;

			if data_in_last = '1' then
				pre_add_last <= '1';
			end if;
		end if;
	end if;
	end process;

	pre_add_overflow <= pre_add_data(pre_add_data'high);
	
	both_negative <= '1' when pre_add_A_reg_z1(pre_add_A_reg_z1'high) = '1' 
		and pre_add_B_reg_z1(pre_add_B_reg_z1'high) = '1' 
			else '0';

	both_positive <= '1' when pre_add_A_reg_z1(pre_add_A_reg_z1'high) = '0' 
		and pre_add_B_reg_z1(pre_add_B_reg_z1'high) = '0'
			else '0';

	sync_2s_saturation_logic: process (clk)
	begin
	if rising_edge (clk) then
		reg_valid <= '0';
		reg_last <= '0';

		if pre_add_valid = '1' then
			reg_valid <= '1';
			
			if pre_add_last = '1' then
				reg_last <= '1';
			end if;

			if pre_add_overflow = '1' then 
				if both_negative = '1' then
					-- negative saturation
					reg_data(reg_data'high) <= '1';
					reg_data(reg_data'high-1 downto 0) <= (others => '0');
				else
					-- positive saturation
					reg_data(reg_data'high) <= '0';
					reg_data(reg_data'high-1 downto 0) <= (others => '1');
				end if;
			else
				-- truncated pre add
				reg_data <= pre_add_data(reg_data'high downto 0);
			end if;
		end if;
	end if;
	end process;

	data_out_valid <= reg_valid;
	data_out_data <= reg_data;
	data_out_last <= reg_last;

end rtl;
