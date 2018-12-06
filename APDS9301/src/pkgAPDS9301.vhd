-------------------------------------------------------------------------
-- pkgAPDS9301.vhd
--
-- Author: Elias Geissler
-- Project: SSL1 Master ESD at FH Hagenberg
-------------------------------------------------------------------------
-- Description: this package provides some constant and types specific for the operation with APDS9301 (light sensor)

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package pkgAPDS9301 is
	
	-- register file address constants
	constant cRegFileNumberOfBytes	: natural := 9;
	constant cRegAddrLight_L 		: natural := 0;
	constant cRegAddrLight_H 		: natural := 1;
	constant cRegAddrTimeStamp_0 	: natural := 2;
	constant cRegAddrTimeStamp_1 	: natural := 3;
	constant cRegAddrTimeStamp_2 	: natural := 4;
	constant cRegAddrTimeStamp_3 	: natural := 5;
	constant cRegAddrFrequenzy_L	: natural := 6;
	constant cRegAddrFrequenzy_H	: natural := 7;
	constant cRegAddrConfig			: natural := 8;
	
	-- fifo width
	constant cFifoByteWidth		: natural := 8;
	constant cFifoStages		: natural := 8;
	
	-- fifo range types
	subtype tFifoRangeLight_L 		is natural range 7  downto 0;
	subtype tFifoRangeLight_H 		is natural range 15 downto 8;
	subtype tFifoRangeTimeStamp_0 	is natural range 23 downto 16;
	subtype tFifoRangeTimeStamp_1 	is natural range 31 downto 24;
	subtype tFifoRangeTimeStamp_2 	is natural range 39 downto 32;
	subtype tFifoRangeTimeStamp_3 	is natural range 47 downto 40;
	
	subtype tFifoRangeTimeStamp		is natural range 47 downto 16;
	
	-- default i2c read frequency is 400 ms
	constant cDefaultI2cReadFreqNat	: natural := 100;
	constant cDefaultI2cReadFreq	: std_ulogic_vector(15 downto 0) := std_ulogic_vector(to_unsigned(cDefaultI2cReadFreqNat,16));
	
	-- i2c constants
	constant cI2cAddr				: std_ulogic_vector(6 downto 0)	:= b"010_1001";
	constant cI2cRegAddrControl		: std_ulogic_vector(7 downto 0)	:= x"80";
	constant cI2cRegAddrLight_Ch0_L	: std_ulogic_vector(7 downto 0)	:= x"8C";
	
	constant cI2cRegControlData		: std_ulogic_vector(7 downto 0) := x"03";

	
end package pkgAPDS9301;
