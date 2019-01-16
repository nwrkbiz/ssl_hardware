-------------------------------------------------------------------------
-- pkgGlobal.vhd
--
-- Author: Elias Geissler
-- Project: SSL1 Master ESD at FH Hagenberg
-------------------------------------------------------------------------
-- Description: this package provides some global constant and types

library ieee;
use ieee.std_logic_1164.all;


package pkgGlobal is

constant cActivated 	: std_ulogic := '1';
constant cInactivated 	: std_ulogic := '0';
constant cnActivated 	: std_ulogic := not('1');
constant cnInactivated 	: std_ulogic := not('0');

-- avalon MM bus constants
constant cAvalonDataWidth	: natural := 8;
constant cAvalonAddrWidth	: natural := 6; -- the sensor with the largest regfile contains 46 registers

-- internal regfile read/write constants
constant cAddrWidth			: natural := 8;
constant cDataWidth			: natural := 8;

constant cTimeStampWidth	: natural := 32;

-- i2c constants
constant cI2cWrite	: std_ulogic	:= '0';
constant cI2cRead	: std_ulogic	:= '1';

subtype tByte is std_ulogic_vector(7 downto 0);
		
end package pkgGlobal;
