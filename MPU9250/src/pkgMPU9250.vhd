-------------------------------------------------------------------------
-- pkgMPU9250.vhd
--
-- Author: Elias Geissler
-- Project: SSL1 Master ESD at FH Hagenberg
-------------------------------------------------------------------------
-- Description: this package provides some constant and types specific for the operation with APDS9301 (light sensor)

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package pkgMPU9250 is
	
	-- register file address constants
	constant cRegFileNumberOfBytes			: natural := 37;
	constant cRegAddrAccelerometer_X_L 		: natural := 0;
	constant cRegAddrAccelerometer_X_H 		: natural := 1;
	constant cRegAddrAccelerometer_Y_L 		: natural := 2;
	constant cRegAddrAccelerometer_Y_H 		: natural := 3;
	constant cRegAddrAccelerometer_Z_L 		: natural := 4;
	constant cRegAddrAccelerometer_Z_H 		: natural := 5;
	constant cRegAddrGyroscope_X_L 			: natural := 6;
	constant cRegAddrGyroscope_X_H 			: natural := 7;
	constant cRegAddrGyroscope_Y_L 			: natural := 8;
	constant cRegAddrGyroscope_Y_H 			: natural := 9;
	constant cRegAddrGyroscope_Z_L 			: natural := 10;
	constant cRegAddrGyroscope_Z_H 			: natural := 11;
	constant cRegAddrMagnetometer_X_L 		: natural := 12;
	constant cRegAddrMagnetometer_X_H 		: natural := 13;
	constant cRegAddrMagnetometer_Y_L 		: natural := 14;
	constant cRegAddrMagnetometer_Y_H 		: natural := 15;
	constant cRegAddrMagnetometer_Z_L 		: natural := 16;
	constant cRegAddrMagnetometer_Z_H 		: natural := 17;
	constant cRegAddrTimeStamp_0 			: natural := 18;
	constant cRegAddrTimeStamp_1 			: natural := 19;
	constant cRegAddrTimeStamp_2 			: natural := 20;
	constant cRegAddrTimeStamp_3 			: natural := 21;
	constant cRegAddrFrequenzy_L			: natural := 22;
	constant cRegAddrFrequenzy_H			: natural := 23;
	constant cRegAddrToleranceEnable		: natural := 24; -- bit 0: X-axis; 1:Y; 2:Z
	constant cRegAddrTolerance_X_Top_L		: natural := 25;
	constant cRegAddrTolerance_X_Top_H		: natural := 26;
	constant cRegAddrTolerance_X_Bot_L		: natural := 27;
	constant cRegAddrTolerance_X_Bot_H		: natural := 28;
	constant cRegAddrTolerance_Y_Top_L		: natural := 29;
	constant cRegAddrTolerance_Y_Top_H		: natural := 30;
	constant cRegAddrTolerance_Y_Bot_L		: natural := 31;
	constant cRegAddrTolerance_Y_Bot_H		: natural := 32;
	constant cRegAddrTolerance_Z_Top_L		: natural := 33;
	constant cRegAddrTolerance_Z_Top_H		: natural := 34;
	constant cRegAddrTolerance_Z_Bot_L		: natural := 35;
	constant cRegAddrTolerance_Z_Bot_H		: natural := 36;
	
	
	-- fifo width
	constant cFifoByteWidth		: natural := 22;
	constant cFifoStages		: natural := 5000;	-- max freq is 1kHz - to save data up to 5 secs 5000 stages are needed
	
	-- fifo range types
	subtype tFifoRangeAccelerometer_X_L 		is natural range 7   downto 0;
	subtype tFifoRangeAccelerometer_X_H 		is natural range 15  downto 8;
	subtype tFifoRangeAccelerometer_Y_L 		is natural range 23  downto 16;
	subtype tFifoRangeAccelerometer_Y_H 		is natural range 31  downto 24;
	subtype tFifoRangeAccelerometer_Z_L 		is natural range 39  downto 32;
	subtype tFifoRangeAccelerometer_Z_H 		is natural range 47  downto 40;
	subtype tFifoRangeGyroscope_X_L		 		is natural range 55  downto 48;
	subtype tFifoRangeGyroscope_X_H		 		is natural range 63  downto 56;
	subtype tFifoRangeGyroscope_Y_L		 		is natural range 71  downto 64;
	subtype tFifoRangeGyroscope_Y_H		 		is natural range 79  downto 72;
	subtype tFifoRangeGyroscope_Z_L		 		is natural range 87  downto 80;
	subtype tFifoRangeGyroscope_Z_H		 		is natural range 95  downto 88;
	subtype tFifoRangeMagnetometer_X_L		 	is natural range 103 downto 96;
	subtype tFifoRangeMagnetometer_X_H		 	is natural range 111 downto 104;
	subtype tFifoRangeMagnetometer_Y_L		 	is natural range 119 downto 112;
	subtype tFifoRangeMagnetometer_Y_H		 	is natural range 127 downto 120;
	subtype tFifoRangeMagnetometer_Z_L		 	is natural range 135 downto 128;
	subtype tFifoRangeMagnetometer_Z_H		 	is natural range 143 downto 136;	
	subtype tFifoRangeTimeStamp_0 				is natural range 151 downto 144;
	subtype tFifoRangeTimeStamp_1 				is natural range 159 downto 152;
	subtype tFifoRangeTimeStamp_2 				is natural range 167 downto 160;
	subtype tFifoRangeTimeStamp_3 				is natural range 175 downto 168;
	
	subtype tFifoRangeTimeStamp		is natural range tFifoRangeTimeStamp_3'high downto tFifoRangeTimeStamp_0'low;
	
	-- default i2c read frequency is 1 ms (1kHz)
	constant cDefaultI2cReadFreqNat	: natural := 1;
	constant cDefaultI2cReadFreq	: std_ulogic_vector(15 downto 0) := std_ulogic_vector(to_unsigned(cDefaultI2cReadFreqNat,16));
	
	-- i2c address of MPU9250
	constant cI2cAddrMPU9250				: std_ulogic_vector(6 downto 0)	:= b"110_1000";	
	-- i2c address of AK8963
	constant cI2cAddrAK8963					: std_ulogic_vector(6 downto 0)	:= b"000_1100";
	
	type tI2cRegPacket is record
		I2cAddr		: std_ulogic_vector(6 downto 0);
		I2cRegAddr	: std_ulogic_vector(7 downto 0);
		I2cRegData	: std_ulogic_vector(7 downto 0);
	end record;
	
	constant cI2cRegsToConfigure : natural := 5;
	type tI2cConfig is array (0 to cI2cRegsToConfigure-1) of tI2cRegPacket;
	
	constant cI2cConfig	: tI2cConfig := (
		-- mpu
		0 => (I2cAddr => cI2cAddrMPU9250, I2cRegAddr => x"6A", I2cRegData => x"01"),   	-- reset digital path and sensor regs 
		1 => (I2cAddr => cI2cAddrMPU9250, I2cRegAddr => x"1B", I2cRegData => x"11"),   	-- gyro full scale: +1000dps          
		2 => (I2cAddr => cI2cAddrMPU9250, I2cRegAddr => x"1A", I2cRegData => x"18"),   	-- accel full scale: +-8g             
		3 => (I2cAddr => cI2cAddrMPU9250, I2cRegAddr => x"37", I2cRegData => x"02"),   	-- enable bypass mode      
		
		-- ak
		4 => (I2cAddr => cI2cAddrAK8963 , I2cRegAddr => x"0A", I2cRegData => x"12")    -- enable continous read mode (100Hz) and set bit resolution to 16 bit                                 
	);                                                                                                                       	
	
	-- this is the address of the accelerometer data will be read (6 byte read)
	constant cI2cRegAddrAccel_Xout_H		: std_ulogic_vector(7 downto 0)	:= x"3B";
	-- this is the address of the gyroscope data will be read (6 byte read)
	constant cI2cRegAddrGyroscope_Xout_H	: std_ulogic_vector(7 downto 0)	:= x"43";
	
	-- this is the address of the magnetometer data will be read (6 byte read)
	constant cI2cRegAddrMagnetometer_Xout_L	: std_ulogic_vector(7 downto 0)	:= x"03";

	
end package pkgMPU9250;
