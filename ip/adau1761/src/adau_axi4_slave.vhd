library ieee;
use     ieee.std_logic_1164.all;

entity adau_axi4_slave is
port (
	clk: in std_logic;
	-- s_axi4
	s_axi_aclk: in std_logic;
	s_axi_awaddr: in std_logic_vector( ADDR_WIDTH-1 downto 0 );
	s_axi_awprot: in std_logic_vector( 2 downto 0 );
	s_axi_awvalid: in std_logic;
	s_axi_awready: out std_logic;
	s_axi_wdata: in std_logic_vector( 31 downto 0 );
	s_axi_wstrb: in std_logic_vector( 3 downto 0 );
	s_axi_wvalid: in std_logic;
	s_axi_wready: out std_logic;
	s_axi_bresp: out std_logic_vector( 1 downto 0 );
	s_axi_bvalid: out std_logic;
	s_axi_bready: in std_logic;
	s_axi_araddr: in std_logic_vector( ADDR_WIDTH-1 downto 0 );
	s_axi_arprot: in std_logic_vector( 2 downto 0 );
	s_axi_arvalid: in std_logic;
	s_axi_arready: out std_logic;
	s_axi_rresp: out std_logic_vector( 1 downto 0 );
	s_axi_rvalid: out std_logic;
	s_axi_rready: in std_logic;
	-- i2c
	i2c_request: out std_logic;
	i2c_rwn: out std_logic;
	i2c_rdata: in std_logic_vector(7 downto 0);
	i2c_wdata: out std_logic_vector(7 downto 0);
	i2c_busy: in std_logic;
	i2c_done: in std_logic;
	i2c_ack: in std_logic_vector(3 downto 0)
);
end adau_axi4_slave;

architecture rtl of adau_axi4_slave is

	signal axi_awaddr_s: std_logic_vector(3 downto 0) := (others => '0'); 
	signal axi_awready_s: std_logic;
	signal axi_wready_s: std_logic;
	signal axi_bresp_s: std_logic_vector(1 downto 0);
	signal axi_bvalid_s: std_logic;
	signal axi_araddr_s: std_logic_vector(ADDR_WIDTH-1 downto 0) := (others => '0');
	signal axi_arready_s: std_logic;
	signal axi_rresp_s: std_logic_vector(1 downto 0);
	signal axi_rvalid_s: std_logic;

	signal write_request_s, read_request_s: std_logic := '0';

	signal i2c_request_s: std_logic;
	signal i2c_addr_s: std_logic_vector( downto 0);
	signal i2c_wdata_s, i2c_rdata_s: std_logic_vector( downto 0);
	signal i2c_busy_s, i2c_done_s: std_logic;
	signal i2c_ack_s: std_logic_vector(3 downto 0);
begin
	
	awready_sync: process (s_axi_aclk)
	begin
	if rising_edge (s_axi_aclk) then
		axi_awready <= '0';
		if axi_awready = '0' 
			and s_axi_awvalid = '1' 
				and s_axi_wvalid = '1' then
					axi_awready <= '1';
		end if;
	end if;	
	end process awready_sync;

	awaddr_sync: process(s_axi_aclk)
	begin
	if rising_edge (s_axi_aclk) then
		axi_awaddr <= axi_awaddr;
		if axi_awready = '0' 
			and s_axi_awvalid = '1' 
				and s_axi_wvalid = '1' then
					axi_awaddr <= s_axi_awaddr;
		end if;
	end if;
	end process awaddr_sync;

	wready_sync: process (s_axi_aclk)
	begin
	if rising_edge (s_axi_aclk) then
		axi_wready <= '0';
		if axi_wready = '0' 
			and s_axi_wvalid = '1' 
				and s_axi_awvalid = '1' then
					axi_wready <= '1';
		end if;
	end if;
	end process wready_sync; 

	bresp_sync: process (s_axi_aclk)
	begin
	if rising_edge (s_axi_aclk) then
		axi_bresp <= "00";
		axi_bvalid <= '0';
		if axi_awready = '1' 
			and s_axi_awvalid = '1' 
				and axi_wready = '1' 
					and s_axi_wvalid = '1' 
						and axi_bvalid = '0' then
							axi_bvalid <= '1';
		end if;
	end if;
	end process bresp_sync; 

	araddr_sync: process (s_axi_aclk)
	begin
	if rising_edge (s_axi_aclk) then
		axi_arready <= '0';
		axi_araddr <= axi_araddr;
		if axi_arready = '0' 
			and s_axi_arvalid = '1' then
				axi_arready <= '1';
				axi_araddr  <= s_axi_araddr;           
		end if;
	end if;
	end process araddr_sync; 

	rresp_sync: process (s_axi_aclk)
	begin
	if rising_edge (s_axi_aclk) then
		axi_rvalid <= '0';
		axi_rresp <= "00";
		if axi_arready = '1' 
			and s_axi_arvalid = '1' 
				and axi_rvalid = '0' then
					axi_rvalid <= '1';
		end if;
	end if;
	end process rresp_sync;
	
	read_request_s <= axi_arready and s_axi_arvalid and (not axi_rvalid); 
	
	-- SYNC read FSM
	read_state <= i2c_read when s_axi_araddr = IIC_DATA_REG
		else i2c_status when s_axi_araddr = IIC_STATUS_REG
		else pll_status when s_axi_araddr = PLL_STATUS_REG
		else idle;

	process (s_axi_aclk)
	begin
	if rising_edge (s_axi_aclk) then
		if read_request_s = '1' then
			case read_state is
				
				WHEN I2C_READ => 
					s_axi_rdata_s(31 downto 8) <= (others => '0');
					s_axi_rdata_s(7 downto 0) <= i2c_rdata(7 downto 0);
				
				WHEN I2C_STATUS => 
					s_axi_rdata_s(31 downto 6) <= (others => '0');
					s_axi_rdata_s(5 downto 2) <= i2c_ack;
					s_axi_rdata_s(1) <= i2c_done;
					s_axi_rdata_s(0) <= i2c_busy;

				WHEN PLL_STATUS =>
					s_axi_rdata_s(31 downto 1) <= (others => '0');
					s_axi_rdata_s(0) <= pll_locked;

				WHEN OTHERS =>
			end case;
		end if;
	end if;

	write_request_s <= axi_wready and s_axi_wvalid and axi_awready and s_axi_awvalid; 
	
	-- SYNC write FSM
	write_state <= i2c_write when s_axi_awaddr = IIC_DATA_REG
		else i2c_status when s_axi_awaddr = IIC_STATUS_REG
		else idle;

	process (s_axi_aclk)
	begin
	if rising_edge (s_axi_aclk) then
		i2c_request_s <= '0';
		if write_request_s = '1' then
			case write_state is 
				WHEN I2C_WRITE =>
					i2c_request_s <= '1';
					i2c_wdata_s <= s_axi_wdata(23 downto 0);
					
				WHEN I2C_STATUS =>
					i2c_addr <= s_axi_wdata(9 downto 3);
					i2c_length_s <= s_axi_wdata(2 downto 1);
					i2c_rwn_s <= s_axi_wdata(0);

				WHEN OTHERS =>
			end case;
		end if;
	end if;
	end process;
	
	s_axi_awready <= axi_awready_s; 
	s_axi_wready <= axi_wready_s;
	s_axi_bresp <= axi_bresp_s;
	s_axi_bvalid <= axi_bvalid_s;	
	s_axi_arready <= axi_arready_s;
	s_axi_rresp <= axi_rresp_s;
	s_axi_rvalid <= axi_rvalid_s;

end rtl;
