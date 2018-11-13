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
		
end package pkgGlobal;
