library ieee;
use     ieee.std_logic_1164.all;

entity i2c_master is
generic (
	G_USE_PULL_UP: std_logic := '0'; -- '0': uses pull down resistor
	G_REF_CLK_FREQUENCY: natural := 100000000;
	G_I2C_CLK_FREQUENCY: natural := 1000000
);
port (
	clk: in std_logic;
	i2c_request: in std_logic;
	i2c_addr: in std_logic_vector(6 downto 0);
	i2c_rwn: in std_logic;
	i2c_length: in std_logic_vector(1 downto 0);
	i2c_wdata: in std_logic_vector(23 downto 0);
	i2c_rdata: out std_logic_vector(23 downto 0);
	i2c_busy: out std_logic;
	i2c_done: out std_logic;
	i2c_ack: out std_logic_vector(3 downto 0);
	scl: inout std_logic;
	sda: inout std_logic
);
end entity i2c_master;

architecture rtl of i2c_master is

	signal tick: std_logic;
	signal tick_cpt: natural range 0 to G_REF_CLK_FREQUENCY/G_I2C_CLK_FREQUENCY/2-1 := 0;

	constant ACK: std_logic := '0';
	constant NACK: std_logic := '1';

	type fsm_states is (idle, start, bus_activity_monitor, 
		addr, addr_ack, 
		write, slave_ack, read, 
		master_ack, master_nack, stop);

	signal state_reg, state_next: fsm_states := idle;
	signal sda_i_reg: std_logic;
	signal scl_i_reg: std_logic;
	signal sda_o_reg, sda_o_next: std_logic;
	signal scl_o_reg, scl_o_next: std_logic;
	
	signal i2c_busy_reg, i2c_busy_next: std_logic;
	signal i2c_done_reg, i2c_done_next: std_logic;
	
	constant DATA_SIZE: natural := 24;
	signal data_ptr_reg, data_ptr_next: natural range 0 to DATA_SIZE-1;
	signal addr_ptr_reg, addr_ptr_next: natural range 0 to 7;
	signal dev_addr_next, dev_addr_reg: std_logic_vector(7 downto 0);

	signal wdata_next, wdata_reg: std_logic_vector(DATA_SIZE-1 downto 0);
	signal rdata_next, rdata_reg: std_logic_vector(DATA_SIZE-1 downto 0);
	signal rwn_reg, rwn_next: std_logic;
	signal ack_next, ack_reg: std_logic_vector(3 downto 0);

	signal bus_activity_reg, bus_activity_next: std_logic_vector(2 downto 0);
begin
	
	sync_iic_tick_gen: process(clk)
	begin
	if rising_edge(clk) then
		tick <= '0';
		if tick_cpt < G_REF_CLK_FREQUENCY/G_I2C_CLK_FREQUENCY/2-1 then
			tick_cpt <= tick_cpt+1;
		else
			tick_cpt <= 0;
			tick <= '1';
		end if;
	end if;
	end process sync_iic_tick_gen;

	sync_iic_fsm: process(clk)
	begin
	if rising_edge(clk) then
		state_reg <= state_next;
		sda_o_reg <= sda_o_next;
		scl_o_reg <= scl_o_next;
		data_ptr_reg <= data_ptr_next;
		i2c_busy_reg <= i2c_busy_next;
		i2c_done_reg <= i2c_done_next;
		rwn_reg <= rwn_next;
		wdata_reg <= wdata_next;
		rdata_reg <= rdata_next;
		dev_addr_reg <= dev_addr_next;
		ack_reg <= ack_next;
		data_ptr_reg <= data_ptr_next;
		addr_ptr_reg <= addr_ptr_next;
		bus_activity_reg <= bus_activity_next;
	end if;
	end process sync_iic_fsm;
	
	sda_i_reg <= sda;
	scl_i_reg <= scl;

	iic_fsm_behav: process(state_reg, 
		sda_i_reg, sda_o_reg,
		scl_i_reg, scl_o_reg,
		i2c_request, i2c_addr, i2c_rwn, i2c_wdata,
		bus_activity_reg,
		i2c_busy_reg, i2c_length,
		dev_addr_reg, addr_ptr_reg,
		wdata_reg, rdata_reg, data_ptr_reg,
		ack_reg, rwn_reg, tick)
	begin

	state_next <= state_reg;

	sda_o_next <= sda_o_reg;
	scl_o_next <= scl_o_reg;

	data_ptr_next <= data_ptr_reg;
	addr_ptr_next <= addr_ptr_reg;

	i2c_busy_next <= i2c_busy_reg;
	i2c_done_next <= '0';

	dev_addr_next <= dev_addr_reg;
	rwn_next <= rwn_reg;
	wdata_next <= wdata_reg;
	rdata_next <= rdata_reg;
	ack_next <= ack_reg;

	bus_activity_next <= bus_activity_reg;

	case state_reg is
		when idle =>
			scl_o_next <= '1'; -- idle
			sda_o_next <= '1'; -- idle
			i2c_busy_next <= '0';
			if i2c_request = '1' then
				state_next <= bus_activity_monitor;
				bus_activity_next <= (others => '0'); -- reset
				i2c_busy_next <= '1'; -- request pending
				rwn_next <= i2c_rwn; -- command
				dev_addr_next <= i2c_addr&i2c_rwn; -- command
				addr_ptr_next <= 7;
				wdata_next <= i2c_wdata;
				ack_next <= (others => '0'); -- reset buffer
				if i2c_length = "01" then data_ptr_next <= 7; -- single byte
				elsif i2c_length = "10" then data_ptr_next <= 15; -- two bytes
				elsif i2c_length = "11" then data_ptr_next <= 23; -- three bytes
				else data_ptr_next <= 7;
				end if;
			end if;
	
		when bus_activity_monitor =>
			if bus_activity_reg(2) = '1' then
				state_next <= start;
				sda_o_next <= '0';
			else
				if scl_i_reg = '0' then -- activity
					bus_activity_next <= (others => '0'); -- reset
				else
					if tick = '1' then
						bus_activity_next <= bus_activity_reg(1 downto 0)&'1';
					end if;
				end if;
			end if;

		when start =>
			if scl_o_reg = '1' then
				if tick = '1' then
					scl_o_next <= not(scl_o_reg);
				end if;
			else
				state_next <= addr;
			end if;

		when addr =>
			sda_o_next <= dev_addr_reg(addr_ptr_reg);
			if tick = '1' then
				scl_o_next <= not(scl_o_reg);
				if scl_o_reg = '1' then
					if addr_ptr_reg = 0 then
						state_next <= addr_ack;
						sda_o_next <= '1'; -- idle
					else
						addr_ptr_next <= addr_ptr_reg-1;
					end if;
				end if;
			end if;

		when addr_ack =>
			if tick = '1' then
				scl_o_next <= not(scl_o_reg);
				if scl_o_reg = '1' then
					ack_next <= ack_reg(2 downto 0)&sda_i_reg;
					if sda_i_reg = NACK then
						state_next <= stop;
						sda_o_next <= '0';
					else
						if rwn_reg = '0' then
							state_next <= write;
						else
							state_next <= read;
						end if;
					end if;
				end if;
			end if;

		when write =>
			sda_o_next <= wdata_reg(data_ptr_reg);
			if tick = '1' then
				scl_o_next <= not(scl_o_reg);
				if scl_o_reg = '1' then
					if data_ptr_reg = 16 then
						state_next <= slave_ack;
					elsif data_ptr_reg = 8 then
						state_next <= slave_ack;
					elsif data_ptr_reg = 0 then
						state_next <= slave_ack;
					else
						data_ptr_next <= data_ptr_reg-1;
					end if;
				end if;
			end if;

		when slave_ack =>
			sda_o_next <= '1'; -- idle
			if tick = '1' then
				scl_o_next <= not(scl_o_reg);
				if scl_o_reg = '1' then
					ack_next <= ack_reg(2 downto 0)&sda_i_reg;
					if sda_i_reg = NACK then
						state_next <= stop;
						sda_o_next <= '0';
					else
						if data_ptr_reg = 0 then
							state_next <= stop;
							sda_o_next <= '0';
						else
							data_ptr_next <= data_ptr_reg-1;
							state_next <= write;
						end if;
					end if;
				end if;
			end if;

		when read =>
			if tick = '1' then
				scl_o_next <= not(scl_o_reg);
				if scl_o_reg = '1' then
					rdata_next <= rdata_reg(DATA_SIZE-2 downto 0)&sda_i_reg;
					if data_ptr_reg = 16 then
						sda_o_next <= ACK;
						state_next <= master_ack;
					elsif data_ptr_reg = 8 then
						sda_o_next <= ACK;
						state_next <= master_ack;
					elsif data_ptr_reg = 0 then
						sda_o_next <= NACK;
						state_next <= master_nack;
					else
						data_ptr_next <= data_ptr_reg-1;
					end if;
				end if;
			end if;

		when master_ack =>
			if tick = '1' then
				scl_o_next <= not(scl_o_reg);
				if scl_o_reg = '1' then
					state_next <= read;
					data_ptr_next <= data_ptr_reg-1;
					sda_o_next <= '1'; -- back to idle
				end if;
			end if;

		when master_nack =>
			if tick = '1' then
				scl_o_next <= not(scl_o_reg);
				if scl_o_reg = '1' then
					state_next <= stop;
					sda_o_next <= '0';
				end if;
			end if;

		when stop =>
			if tick = '1' then
				if scl_o_reg = '0' then
					scl_o_next <= not(scl_o_reg);
				else
					state_next <= idle;
					i2c_done_next <= '1';
				end if;
			end if;

	end case;
	end process iic_fsm_behav;

pull_up_resistor_gen: if (G_USE_PULL_UP_RESISTOR) generate
	scl <= '0' when scl_o_reg = '0' else 'Z';
	sda <= '0' when sda_o_reg = '0' else 'Z';
else
	scl <= '1' when scl_o_reg = '1' else 'Z';
	sda <= '1' when sda_o_reg = '1' else 'Z';
end generate;
	
	i2c_ack <= ack_reg; 
	i2c_rdata <= rdata_reg; 
	i2c_busy <= i2c_busy_reg;
	i2c_done <= i2c_done_reg;

end rtl;
