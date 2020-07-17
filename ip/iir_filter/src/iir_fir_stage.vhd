library ieee;
use     ieee.numeric_std.all;
use     ieee.std_logic_1164.all;

entity iir_fir_stage is
generic (
	G_DATA_WIDTH: positive := 8
);
port (
	clk: in std_logic;
	-- coef interface
	coef_valid: in std_logic;
	coef_data: in std_logic_vector(G_DATA_WIDTH-1 downto 0);
	-- stream (in)
	data_in_valid: in std_logic;
	data_in_data: in std_logic_vector(G_DATA_WIDTH-1 downto 0);
	data_in_last: in std_logic;
	-- stream (out)
	data_out_valid: out std_logic;
	data_out_data: out std_logic_vector(G_DATA_WIDTH-1 downto 0);
	data_out_last: out std_logic
);
end iir_fir_stage;

architecture rtl of iir_fir_stage is

	type fir_array_type is array (0 to 9) of std_logic_vector(G_DATA_WIDTH-1 downto 0);
	signal fir_queue_reg: fir_array_type := (others => (others => '0');
	signal fir_b_taps_reg: fir_array_type := (others => (others => '0');

begin
	
	sync_fir_pipeline_entry: process (clk)
	begin
	if rising_edge (clk) then
		if data_in_valid = '1' then
			fir_queue_reg(0) <= data_in_data;
		end if;
	end if;
	end process;

pipeline_gen: for i in 1 to 9 generate
	
	sync_fir_pipeline_stage: process (clk)
	begin
	if rising_edge (clk) then
		if data_in_valid = '1' then
			fir_queue_reg(i) <= fir_queue_reg(i-1);
		end if;
	end if;
	end process;

end generate;

	sync_fir_tap0: process (clk)
	begin
	if rising_edge (clk) then
		if data_in_valid = '1' then
			fir_b_taps_reg(0) <= std_logic_vector(
				signed(fir_coef_reg(0)) * signed(data_in_data)
			);
		end if;		
	end if;
	end process;

taps_gen: for i in 1 to 9 generate

	sync_fir_tap: process (clk)
	begin
	if rising_edge (clk) then
		if data_in_valid = '1' then
			fir_b_taps_reg(i) <= std_logic_vector(
				signed(fir_coef_reg(i)) * signed(fir_queue_reg(i))
			);
		end if;
	end if;
	end process;

end generate;


adder_tree_gen: for i in 0 to 8 generate
	
	sync_add_tree_stage: process (clk)
	begin
	if rising_edge (clk) then
		if data_in_valid = '1' then
			add_tree_reg(i) <= std_logic_vector (
				signed(fir_b_taps_reg(i)) + signed(fir_b_taps_reg(i+1))
			);
		end if;
	end if;
	end process;

end generate;

	-- FIR output stage
	process (clk)
	begin
	if rising_edge (clk) then
		data_out_valid <= '0';
		data_out_last <= '0';
		if data_in_valid = '1' then
			data_out_valid <= '1';
			data_out_data <= add_tree_reg(8);
			if data_in_last = '1' then
				data_out_last <= '1';
			end if;
		end if;
	end if;
	end process;

end rtl;
