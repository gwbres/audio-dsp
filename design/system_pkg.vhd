library ieee;
use     ieee.std_logic_1164.all;

package system_pkg is

	-- Audio
	constant L: natural := 0;
	constant R: natural := 1;
	constant C_AUDIO_DATA_WIDTH: natural := 24;
	constant C_STEREO_DATA_WIDTH: natural := 2 * C_AUDIO_DATA_WIDTH;

	-- Histrogram / OLED
	constant C_OLED_X_WIDTH: natural := 128;
	constant C_OLED_Y_HEIGHT: natural := 5;

end package system_pkg;

package body system_pkg is
end package body system_pkg;
