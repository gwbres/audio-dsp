----------------------------------------------------------------------------------
-- Engineer: Mike Field <hamster@snap.net.nz>
-- 
-- Description: A controller to send I2C commands to the ADAU1761 codec
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity i2c is
    Port ( clk : in  STD_LOGIC;
            i2c_sda_i : IN std_logic;      
            i2c_sda_o : OUT std_logic;      
            i2c_sda_t : OUT std_logic;      
            i2c_scl : out  STD_LOGIC;
            sw : in std_logic_vector(1 downto 0);
            active : out std_logic_vector(1 downto 0));
end i2c;

architecture Behavioral of i2c is

   signal inst_address : std_logic_vector(9 downto 0);          
   signal inst_data    : std_logic_vector(8 downto 0);
   signal sw_full       :std_logic_vector(15 downto 0) := (others => '0');
   signal active_full : std_logic_vector(15 downto 0) := (others => '0');
begin
   sw_full(1 downto 0) <= sw;
   active <= active_full(1 downto 0);
	codec_config_data_inst: entity work.codec_config_data
	PORT MAP(
		clk     => clk,
		address => inst_address,
		data    => inst_data
	);

	Inst_i3c2: entity work.i3c2 GENERIC MAP (
      clk_divide => "01111000"   -- 120 (48,000/120 = 400kHz I2C clock)
   ) PORT MAP(
		clk => clk,
		inst_address => inst_address,
		inst_data    => inst_data,
		i2c_scl      => i2c_scl,
		i2c_sda_i      => i2c_sda_i,
		i2c_sda_o      => i2c_sda_o,
		i2c_sda_t      => i2c_sda_t,
		inputs       => sw_full,
		outputs      => active_full,
		reg_addr     => open,
		reg_data     => open,
		reg_write    => open,
        debug_scl    => open,
        debug_sda    => open,
		error        => open
	);

end Behavioral;
