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
	signal integrator_reg_valid: std_logic_vector(G_CIC_N-1 downto 0);
	signal integrator_z1_reg, integrator_reg_data: pipe_reg_type := (others => (others => '0'));

	signal comb_reg_valid: std_logic_vector(G_CIC_N-1 downto 0);
	signal comb_reg_data: pipe_reg_type := (others => (others => '0'));
	type comb_zM_type is array (0 to G_CIC_M-1) of pipe_reg_type;
	signal comb_zM_reg: comb_zM_type := (others => (others => (others => '0')));
begin

	-------------------
	-- Integrators
	-------------------
	sync_integrator_stage0: process (clk)
	begin
	if rising_edge (clk) then
		integrator_reg_valid(0) <= '0';
		if data_in_valid = '1' then
			integrator_reg_valid(0) <= '1';
			integrator_z1_reg(0) <= data_in_data;
			integrator_reg_data <= std_logic_vector(
				signed(integrator_z1_reg(0))
				signed(data_in_data)
			)(G_DATA_WIDTH+1-1 downto 1); -- keep MSB only
		end if;
	end if;
	end process;

sync_integrators_gen: for i in 1 to G_CIC_N-1 generate
	sync_integrator_stage0: process (clk)
	begin
	if rising_edge (clk) then
		integrator_reg_valid(i) <= '0';
		if integrator_reg_valid(i-1) = '1' then
			integrator_reg_valid(i) <= '1';
			integrator_z1_reg(i) <= integrator_reg_data(i-1);
			integrator_reg_data <= std_logic_vector(
				signed(integrator_z1_reg(i))
				signed(integrator_reg_data(i-1))
			)(G_DATA_WIDTH+1-1 downto 1); -- keep MSB only
		end if;
	end if;
	end process;
end generate;

	-- decimation
	sync_decim_stage: process (clk)
	begin
	if rising_edge (clk) then
		decim_valid <= '0';
		if integrator_reg_valid(G_CIC_N-1) = '1' then
			if decim_cnt < G_CIC_R-1 then
				decim_cnt <= decim_cnt+1;
			else
				decim_cnt <= 0;
				decim_valid <= '1';
				decim_data <= integrator_reg_data(G_CIC_N-1);
			end if;
		end if;
	end if;
	end process;

	-- comb filter stage0
	process (clk)
	begin
	if rising_edge (clk) then
		if decim_valid = '1' then
			comb_zM_reg(0)(0) <= decim_data;
		end if;
	end process;

stage0_zm_gen: for m in 1 to G_CIC_M-1 generate
	process (clk)
	begin
	if rising_edge (clk) then
		comb_zM_reg(m)(0) <= comb_zM_reg(m-1)(0);
	end if;
	end process;
end generate;

	sync_comb_stage0: process (clk)
	begin
	if rising_edge (clk) then
		comb_reg_valid(0) <= '0';
		if decim_valid = '1' then
			comb_reg_valid(0) <= '1';
			comb_reg_data(0) <= std_logic_vector(
				signed(decim_data)
				- signed(comb_zM_reg(G_CIC_M-1)(0))
			)(G_DATA_WIDTH-1 downto 0); -- keep MSB only
	end if;
	end process;

	-- comb filter
comb_filter_gen: for n in 1 to G_CIC_N-1 generate

	zm0_reg: process (clk)
	begin
	if rising_edge (clk) then
		if comb_reg_valid(n-1) = '1' then
			comb_zM_reg(0)(n) <= comb_reg_data(n-1);
		end if;
	end if;
	end process;

	stage_i_zm_gen: for m in 1 to G_CIC_M-1 generate
		zmi_reg: process (clk)
		begin
		if rising_edge (clk) then
			comb_zM_reg(m)(n) <= comb_zM_reg(m-1)(n);
		end if;
		end process;
	end generate;

	sync_comb_filter_stage: process (clk)
	if rising_edge (clk) then
		comb_reg_valid(n) <= '0';
		if comb_reg_valid(n-1) = '1' then
			comb_reg_valid(n) <= '1';
			comb_reg_data(n) <= std_logic_vector(
				signed(comb_reg_data(n))
				- signed(comb_zM_reg(G_CIC_M-1)(n))
			)(G_DATA_WIDTH-1 downto 1); -- MSB only
		end if;
	end if;
	end process;

end generate; -- comb filter gen

end rtl;
