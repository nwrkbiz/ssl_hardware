-------------------------------------------------------------------------
-- pkgHDC1000.vhd
--
-- Author: Elias Geissler
-- Project: SSL1 Master ESD at FH Hagenberg
-------------------------------------------------------------------------
-- Description: this package provides some constant and types specific for the operation with HDC1000 (temp and humidity sensor)

package pkgHDC1000 is
	
	-- register file address constants
	constant cRegAddrTemp_L 		: natural := 0;
	constant cRegAddrTemp_H 		: natural := 1;
	constant cRegAddrHumidity_L 	: natural := 2;
	constant cRegAddrHumidity_H 	: natural := 3;
	constant cRegAddrTimeStamp_0 	: natural := 4;
	constant cRegAddrTimeStamp_1 	: natural := 5;
	constant cRegAddrTimeStamp_2 	: natural := 6;
	constant cRegAddrTimeStamp_3 	: natural := 7;
	constant cRegAddrFrequenzy_L	: natural := 8;
	constant cRegAddrFrequenzy_H	: natural := 9;
	constant cRegAddrConfig_L		: natural := 10;
	constant cRegAddrConfig_H		: natural := 11;
	
	-- fifo range types
	subtype tFifoRangeTemp_L 		is natural range 0  to 7;
	subtype tFifoRangeTemp_H 		is natural range 8  to 15;
	subtype tFifoRangeHumidity_L 	is natural range 16 to 23;
	subtype tFifoRangeHumidity_H 	is natural range 24 to 31;
	subtype tFifoRangeTimeStamp_0 	is natural range 32 to 39;
	subtype tFifoRangeTimeStamp_1 	is natural range 40 to 47;
	subtype tFifoRangeTimeStamp_2 	is natural range 48 to 55;
	subtype tFifoRangeTimeStamp_3 	is natural range 56 to 63;

	
end package pkgHDC1000;
