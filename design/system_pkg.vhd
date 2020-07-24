library ieee;
use     ieee.math_real.all;
use     ieee.std_logic_1164.all;

package system_pkg is

	-- Audio
	constant L: natural := 0;
	constant R: natural := 1;
	constant C_AUDIO_DATA_WIDTH: natural := 24;
	constant C_STEREO_DATA_WIDTH: natural := 2 * C_AUDIO_DATA_WIDTH;

	-- CIC filters
	constant C_CIC_FILTER_R: positive := 128;
	constant C_CIC_FILTER_M: positive := 1; -- fixed
	constant C_CIC_FILTER_N: positive := 6;
	constant C_CIC_OUTPUT_WIDTH: positive := C_AUDIO_DATA_WIDTH + C_CIC_FILTER_R / 4;

	-- Histrogram / OLED
	constant C_OLED_X_WIDTH: natural := 128;
	constant C_OLED_Y_HEIGHT: natural := 32;

	constant C_LOG2_OLED_X_WIDTH: natural := integer(ceil(log2(real(C_OLED_X_WIDTH))));
	constant C_LOG2_OLED_Y_HEIGHT: natural := integer(ceil(log2(real(C_OLED_Y_HEIGHT))));

end package system_pkg;

package body system_pkg is
end package body system_pkg;
