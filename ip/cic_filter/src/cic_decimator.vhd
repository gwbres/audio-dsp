library ieee;
use     ieee.numeric_std.all;
use     ieee.std_logic_1164.all;

entity cic_decimator is
generic (
	G_CIC_R: positive := 8; -- decimation ratio
	G_CIC_N: positive := 8; -- nb stages
	G_CIC_M: positive := 1; -- time delay =1 or 2
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
end cic_decimator;

architecture rtl of cic_decimator is

	type pipe_reg_type is array (0 to G_CIC_N-1) of std_logic_vector(G_DATA_WIDTH-1 downto 0);

	signal intg_stages_valid: std_logic_vector(G_CIC_N-1 downto 0);
	signal intg_stages_data: pipe_reg_type := (others => (others => '0'));

	signal decim_valid: std_logic := '0';
	signal decim_data: std_logic_vector(G_DATA_WIDTH-1 downto 0) := (others => '0');
	signal decim_cnt: natural range 0 to G_CIC_R-1 := 0;

	signal comb_stages_valid: std_logic_vector(G_CIC_N-1 downto 0);
	signal comb_stages_data: pipe_reg_type := (others => (others => '0'));
begin

	-------------------
	-- Integrators
	-------------------
	integrator_stage0: entity work.cic_integrator_stage
	generic map (
		G_DATA_WIDTH => G_DATA_WIDTH
	) port map (
		clk => clk,
		data_in_valid => data_in_valid,
		data_in_data => data_in_data,
		data_out_valid => intg_stages_valid(0),
		data_out_data => intg_stages_data(0)
	);

integrator_stages_gen: for n in 1 to G_CIC_N-1 generate
	
	integrator_stage_n: entity work.cic_integrator_stage
	generic map (
		G_DATA_WIDTH => G_DATA_WIDTH
	) port map (
		clk => clk,
		data_in_valid => intg_stages_valid(n-1),
		data_in_data => intg_stages_data(n-1)
		data_out_valid => intg_stages_valid(n),
		data_out_data => intg_stages_data(n)
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
		G_DATA_WIDTH => G_DATA_WIDTH
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
		G_DATA_WIDTH => G_DATA_WIDTH
	) port map (
		clk => clk,
		data_in_valid => comb_stages_valid(n-1),
		data_in_data => comb_stages_data(n-1),
		data_out_valid => comb_stages_valid(n),
		data_out_data => comb_stages_data(n)
	);

end generate;

	data_out_valid <= comb_stages_valid(G_CIC_N-1);
	data_out_data <= comb_stages_data(G_CIC_N-1);

end rtl;
