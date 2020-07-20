library ieee;
use     ieee.math_real.all;
use     ieee.numeric_std.all;
use     ieee.std_logic_1164.all;

entity cic_decimator is
generic (
	G_CIC_R: positive := 8; -- decimation ratio
	G_CIC_N: positive := 8; -- nb stages
	G_DATA_WIDTH: natural := 16
);
port (
	clk: in std_logic;
	-- data (in) 
	data_in_valid: in std_logic;
	data_in_data: in std_logic_vector(G_DATA_WIDTH-1 downto 0);
	data_in_last: in std_logic;
	-- DATA/out
	data_out_valid: out std_logic;
	data_out_data: out std_logic_vector(G_DATA_WIDTH+G_CIC_R/4-1 downto 0);
	data_out_last: out std_logic
);
end cic_decimator;

architecture rtl of cic_decimator is

	constant C_CIC_BIT_GROWTH: positive := G_CIC_N * natural(ceil(log2(real(G_CIC_R))));
	
	type cic_array_type is array (0 to G_CIC_N-1) of std_logic_vector(G_DATA_WIDTH+C_CIC_BIT_GROWTH-1 downto 0);

	-- integrators
	signal intg_stage_0_valid: std_logic;
	signal intg_stage_0_data: std_logic_vector(G_DATA_WIDTH+C_CIC_BIT_GROWTH-1 downto 0);
	signal intg_stage_0_last: std_logic;
	signal intg_stages_valid: std_logic_vector(G_CIC_N-1 downto 0);
	signal intg_stages_data: cic_array_type := (others => (others => '0'));
	signal intg_stages_last: std_logic_vector(G_CIC_N-1 downto 0);

	-- decim. stage
	signal decim_valid: std_logic := '0';
	signal decim_data: std_logic_vector(G_DATA_WIDTH+C_CIC_BIT_GROWTH-1 downto 0) := (others => '0');
	signal decim_cnt: natural range 0 to G_CIC_R-1 := 0;

	-- comb filter
	signal comb_stages_valid: std_logic_vector(G_CIC_N-1 downto 0);
	signal comb_stages_data: cic_array_type := (others => (others => '0'));

	-- output rounding
	signal round_A_reg: std_logic_vector(G_DATA_WIDTH+C_CIC_BIT_GROWTH-1 downto 0);
	signal round_B_reg: std_logic_vector(G_DATA_WIDTH+C_CIC_BIT_GROWTH-1 downto 0);
	signal round_valid: std_logic;
	signal round_data: std_logic_vector(G_DATA_WIDTH+C_CIC_BIT_GROWTH-1 downto 0);
	
	-- output register
	signal output_reg_valid: std_logic := '0';
	signal output_reg_data: std_logic_vector(G_DATA_WIDTH + G_CIC_R/4-1 downto 0) := (others => '0');
begin

	-------------------
	-- Integrators
	-------------------
	intg_stage_0_valid <= data_in_valid;
	intg_stage_0_data(G_DATA_WIDTH+C_CIC_BIT_GROWTH-1 downto G_DATA_WIDTH) <= (others => data_in_data(data_in_data'high));
	intg_stage_0_data(G_DATA_WIDTH-1 downto 0) <= data_in_data;
	intg_stage_0_last <= data_in_last;
	
	integrator_stage_1_inst: entity work.cic_integrator_stage
	generic map (
		G_DATA_WIDTH => G_DATA_WIDTH + C_CIC_BIT_GROWTH
	) port map (
		clk => clk,
		data_in_valid => intg_stage_0_valid,
		data_in_data => intg_stage_0_data,
		data_in_last => intg_stage_0_last,
		data_out_valid => intg_stages_valid(0),
		data_out_data => intg_stages_data(0),
		data_out_last => intg_stages_last(0)
	);
	
integrator_stages_gen: for n in 1 to G_CIC_N-1 generate
	
	integrator_stage_n_inst: entity work.cic_integrator_stage
	generic map (
		G_DATA_WIDTH => G_DATA_WIDTH + C_CIC_BIT_GROWTH
	) port map (
		clk => clk,
		data_in_valid => intg_stages_valid(n-1),
		data_in_data => intg_stages_data(n-1),
		data_in_last => intg_stages_last(n-1),
		data_out_valid => intg_stages_valid(n),
		data_out_data => intg_stages_data(n),
		data_out_last => intg_stages_last(n)
	);

end generate;

	-------------------
	-- Decimator
	-------------------
	sync_decim_stage: process (clk)
	begin
	if rising_edge (clk) then
		decim_valid <= '0';
		if intg_stages_valid(G_CIC_N-1) = '1' then
			if decim_cnt < G_CIC_R-1 then
				decim_cnt <= decim_cnt+1;
			else
				decim_cnt <= 0;
				decim_valid <= '1';
				decim_data <= intg_stages_data(G_CIC_N-1);
			end if;
		end if;
	end if;
	end process;

	-------------------
	-- Comb filters 
	-------------------
	comb_filter_stage0: entity work.cic_comb_stage
	generic map (
		G_DATA_WIDTH => G_DATA_WIDTH + C_CIC_BIT_GROWTH
	) port map (
		clk => clk,
		data_in_valid => decim_valid,
		data_in_data => decim_data,
		data_out_valid => comb_stages_valid(0),
		data_out_data => comb_stages_data(0)
	);

comb_stages_gen: for n in 1 to G_CIC_N-1 generate

	comb_filter_stage_n: entity work.cic_comb_stage
	generic map (
		G_DATA_WIDTH => G_DATA_WIDTH + C_CIC_BIT_GROWTH
	) port map (
		clk => clk,
		data_in_valid => comb_stages_valid(n-1),
		data_in_data => comb_stages_data(n-1),
		data_out_valid => comb_stages_valid(n),
		data_out_data => comb_stages_data(n)
	);

end generate;

	-- discard non meaningful bits
	-- using proper 2's complement rounding
	-- Output width is Data Input Width + R/4

	--signal Input_value:signed(11 downto 0);
	--signal rounded:signed(6 downto 0);
	--signal input_plus_one_half:signed(11 downto 0);
	--input_plus_one_half<= input_value + "010000";  --note the '1' is in bit 4, we keep bits 5 on up after the add
	--rounded<= input_plus_one_half(11 downto 5);

	round_A_reg <= comb_stages_data(G_CIC_N-1);
	
	round_B_reg(G_DATA_WIDTH + C_CIC_BIT_GROWTH-1 downto G_DATA_WIDTH + G_CIC_R/4) <= (others => '0'); 
	round_B_reg(G_DATA_WIDTH + G_CIC_R/4-1) <= '0'; -- meaningful MSB
	round_B_reg(G_DATA_WIDTH + G_CIC_R/4-2) <= '1';
	round_B_reg(G_DATA_WIDTH + G_CIC_R/4-3 downto 0) <= (others => '0'); -- meaningful LSB

	sync_output_rounding: process (clk)
	begin
	if rising_edge (clk) then
		round_valid <= '0';
		if comb_stages_valid(G_CIC_N-1) = '1' then
			round_valid <= '1';
			round_data <= std_logic_vector (
				signed(round_A_reg) + signed(round_B_reg)
			);

		end if;
	end if;
	end process;

--	sync_output_truncation: process (clk)
--	begin
--	if rising_edge (clk) then
--		output_reg_valid <= '0';
--		if round_valid = '1' then
--			output_reg_valid <= '1';
--			output_reg_data <= round_data(round_data'length-1 downto round_data'length-G_DATA_WIDTH + G_CIC_R/4);
--		end if;
--	end if;
--	end process;

	data_out_valid <= output_reg_valid;
	data_out_data <= output_reg_data;
	data_out_last <= '0';

end rtl;
