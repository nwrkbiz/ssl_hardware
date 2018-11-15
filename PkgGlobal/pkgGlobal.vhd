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


-- range types for regfile
type FirstByte 	is range 7 	downto 0;
type SecondByte is range 15 downto 8;
type ThirdByte 	is range 23 downto 16;
type FourthByte is range 31 downto 24;

-- avalon MM bus constants
constant cAvalonDataWidth	: natural := 32;
constant cAvalonAddrWidth	: natural := 8;

-- internal regfile read/write constants
constant cAddrWidth			: natural := 8;
constant cDataWidth			: natural := 8;

		
end package pkgGlobal;
