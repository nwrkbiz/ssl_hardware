-------------------------------------------------------------------------
-- FSMD.vhd
--
-- Author: Elias Geissler
-- Project: SSL1 Master ESD at FH Hagenberg
-------------------------------------------------------------------------
-- Description: FSMD to read values from MPU9250 over i2c and put data into fifo

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.pkgGlobal.all;
use work.pkgMPU9250.all;

entity FsmdMPU9250 is
	generic(
		gClkFrequency	: natural	:= 50_000_000;
		gI2cFrequency	: natural	:= 400_000;
		gFifoByteWidth	: natural	:= 8
	);
	port(
		iClk 		: in std_ulogic;
		inRstAsync 	: in std_ulogic;
		
		-- i2c interface
		ioSCL		: inout	std_logic;
		ioSDA		: inout std_logic;
		
		-- fifo
		oFifoData	: out std_ulogic_vector(gFifoByteWidth*8-1 downto 0);
		oFifoWrite	: out std_ulogic;
		
		-- regfile interface
		iRegDataFrequency	: in std_ulogic_vector(15 downto 0);
		
		-- strobe and timestamp
		iStrobe		: in std_ulogic;
		iTimeStamp	: in std_ulogic_vector(cTimeStampWidth-1 downto 0)
	);
end entity FsmdMPU9250;

architecture RTL of FsmdMPU9250 is
	
	constant cClkCnt 			: unsigned(7 downto 0) 	:= to_unsigned(gClkFrequency/gI2cFrequency/5 -1,8); -- creates a 400kHz clk
	constant cI2cTimeoutCntMax	: natural				:= gClkFrequency/200_000; -- wait for 5 us
	
		
	type tState is (Idle,
					-- confiuration
					ConfigMPU9250I2cAddr, ConfigMPU9250I2cRegAddr, ConfigMPU9250I2cData, ConfigMPU9250Ack0, ConfigMPU9250Ack1, ConfigMPU9250Ack2,
					ConfigAK8963I2cAddr, ConfigAK8963I2cRegAddr, ConfigAK8963I2cData, ConfigAK8963Ack0, ConfigAK8963Ack1, ConfigAK8963Ack2,
					
					WaitForI2cTransfer,

					-- read accelerometer data 
					AccelerometerI2cAddr, AccelerometerI2cRegAddr, AccelerometerRestartI2cAddr, AccelerometerReadData, AccelerometerSaveData,
					AccelerometerAck0, AccelerometerAck1, AccelerometerAck2,
					
					-- read gyroscope data 
					GyroscopeI2cAddr, GyroscopeI2cRegAddr, GyroscopeRestartI2cAddr, GyroscopeReadData, GyroscopeSaveData,
					GyroscopeAck0, GyroscopeAck1, GyroscopeAck2,
					
					-- read magnetometer data 
					MagnetometerI2cAddr, MagnetometerI2cRegAddr, MagnetometerRestartI2cAddr, MagnetometerReadData, MagnetometerSaveData,
					MagnetometerAck0, MagnetometerAck1, MagnetometerAck2,
					
					WriteDataToFifo
					);
	
	type tData is record
		State 		: tState;
		FreqCount	: natural;
		ReadI2cData	: std_ulogic;
		I2cEnable 	: std_ulogic;
		I2cStart 	: std_ulogic;
		I2cStop 	: std_ulogic;
		I2cRead 	: std_ulogic;
		I2cWrite 	: std_ulogic;
		I2cAckIn 	: std_ulogic;
		I2cDataIn 	: std_ulogic_vector(7 downto 0);
		FifoData	: std_ulogic_vector(gFifoByteWidth*8-1 downto 0);
		FifoWrite	: std_ulogic;
		I2cAckTimeOutCnt	: natural range 0 to cI2cTimeoutCntMax-1;
		ByteCount	: natural;	-- to count the bytes in a burst read
	end record tData;
	
	constant cDefaultData : tData := (
		State 		=> Idle,
		FreqCount	=> 0,
		ReadI2cData	=> '0',
		I2cEnable 	=> '0',
		I2cStart 	=> '0',
		I2cStop 	=> '0',
		I2cRead 	=> '0',
		I2cWrite 	=> '0',
		I2cAckIn 	=> '0',
		I2cDataIn 	=> (others => '0'),
		FifoData	=> (others => '0'),
		FifoWrite	=> '0',
		I2cAckTimeOutCnt	=> 0,
		ByteCount	=> 0
	);
	
	signal R,NxR	: tData;

	signal I2cCmdAck : std_logic;
	signal I2cAckOut : std_logic;
	signal I2cDataOut : std_logic_vector(7 downto 0);
	
begin
	
	Reg: process (iClk, inRstAsync) is
	begin
		if inRstAsync = not('1') then
			R <= cDefaultData;
			
		elsif rising_edge(iClk) then
			R <= NxR;
		end if;
	end process;
	
	FSMD: process (
		R, iRegDataFrequency, iStrobe, iTimeStamp, I2cCmdAck, I2cDataOut, I2cAckOut
	) is	
	begin
		-- defaults
		NxR <= R;
		NxR.I2cEnable 	<= '1';
		NxR.I2cStart	<= '0';
		NxR.I2cRead		<= '0';
		NxR.I2cWrite	<= '0';
		NxR.I2cStop		<= '0';
		NxR.I2cAckIn	<= '1'; -- '0' means always active
		NxR.FifoWrite	<= '0';
		
		
		-- freq count logic
		---------------------------------------------------------------
		if iStrobe = '1' then
			if R.FreqCount = 0 then
				-- reset count and set i2c transfer
				NxR.FreqCount <= to_integer(unsigned(iRegDataFrequency))-1;
				NxR.ReadI2cData <= '1';
			else
				NxR.FreqCount <= R.FreqCount - 1;
			end if;
		end if;
	
	
		-- FSMD start
		---------------------------------------------------------------
		case (R.State) is
			when Idle =>
				--if R.ReadI2cData = '1' then
					NxR.State <= ConfigMPU9250I2cAddr;
				--end if;
			------------------------------------------------------------------------------------------------	
			-- first config the MPU9250 to enable bypass mode to access AK8963 (magnetometer) directly
			------------------------------------------------------------------------------------------------	
			when ConfigMPU9250I2cAddr =>
				NxR.I2cStart	<= '1';
				NxR.I2cWrite	<= '1';
				NxR.I2cDataIn	<= cI2cAddrMPU9250 & cI2cWrite;
				if I2cCmdAck = '1' then
					NxR.I2cStart	<= '0';
					NxR.I2cWrite	<= '0';
					NxR.State		<= ConfigMPU9250Ack0;
					NxR.I2cAckTimeOutCnt <= 0;
				end if;
				
			when ConfigMPU9250Ack0 =>
				if I2cAckOut = '0' then
					NxR.State <= ConfigMPU9250I2cRegAddr;
				else
					-- time out 5 us
					if R.I2cAckTimeOutCnt = cI2cTimeoutCntMax-1 then
						-- go back to write I2c address again
						NxR.State <= ConfigMPU9250I2cAddr;
					else
						NxR.I2cAckTimeOutCnt <= R.I2cAckTimeOutCnt+1;
					end if;
				end if;
				
			-- write reg address on bus
			when ConfigMPU9250I2cRegAddr =>
				NxR.I2cWrite	<= '1';
				NxR.I2cDataIn	<= cI2cRegAddrBypassControl;
				if I2cCmdAck = '1' then
					NxR.I2cWrite	<= '0';
					NxR.State		<= ConfigMPU9250Ack1;
					NxR.I2cAckTimeOutCnt <= 0;
				end if;
				
			when ConfigMPU9250Ack1 =>
				if I2cAckOut = '0' then
					NxR.State <= ConfigMPU9250I2cData;
				else
					-- time out 5 us
					if R.I2cAckTimeOutCnt = cI2cTimeoutCntMax-1 then
						-- go back to write I2c address again
						NxR.State <= ConfigMPU9250I2cAddr;
					else
						NxR.I2cAckTimeOutCnt <= R.I2cAckTimeOutCnt+1;
					end if;
				end if;
				
			when ConfigMPU9250I2cData =>
				NxR.I2cWrite	<= '1';
				NxR.I2cStop		<= '1';
				NxR.I2cDataIn	<= cI2cRegDataBypassControl;
				if I2cCmdAck = '1' then
					NxR.I2cWrite	<= '0';
					NxR.State		<= ConfigMPU9250Ack2;
					NxR.I2cAckTimeOutCnt <= 0;
				end if;
				
			when ConfigMPU9250Ack2 =>
				if I2cAckOut = '0' then
					NxR.State <= ConfigAK8963I2cAddr;
				else
					-- time out 5 us
					if R.I2cAckTimeOutCnt = cI2cTimeoutCntMax-1 then
						-- go back to write I2c address again
						NxR.State <= ConfigMPU9250I2cAddr;
					else
						NxR.I2cAckTimeOutCnt <= R.I2cAckTimeOutCnt+1;
					end if;
				end if;
				
			------------------------------------------------------------------------------------------------	
			-- config the AK8963 to enable continous read mode (100Hz) and set bit resolution to 16 bit
			------------------------------------------------------------------------------------------------
			
			when ConfigAK8963I2cAddr =>
				NxR.I2cStart	<= '1';
				NxR.I2cWrite	<= '1';
				NxR.I2cDataIn	<= cI2cAddrAK8963 & cI2cWrite;
				if I2cCmdAck = '1' then
					NxR.I2cStart	<= '0';
					NxR.I2cWrite	<= '0';
					NxR.State		<= ConfigAK8963Ack0;
					NxR.I2cAckTimeOutCnt <= 0;
				end if;
				
			when ConfigAK8963Ack0 =>
				if I2cAckOut = '0' then
					NxR.State <= ConfigAK8963I2cRegAddr;
				else
					-- time out 5 us
					if R.I2cAckTimeOutCnt = cI2cTimeoutCntMax-1 then
						-- go back to write I2c address again
						NxR.State <= ConfigAK8963I2cAddr;
					else
						NxR.I2cAckTimeOutCnt <= R.I2cAckTimeOutCnt+1;
					end if;
				end if;
				
			-- write reg address on bus
			when ConfigAK8963I2cRegAddr =>
				NxR.I2cWrite	<= '1';
				NxR.I2cDataIn	<= cI2cRegAddrControl1;
				if I2cCmdAck = '1' then
					NxR.I2cWrite	<= '0';
					NxR.State		<= ConfigAK8963Ack1;
					NxR.I2cAckTimeOutCnt <= 0;
				end if;
				
			when ConfigAK8963Ack1 =>
				if I2cAckOut = '0' then
					NxR.State <= ConfigAK8963I2cData;
				else
					-- time out 5 us
					if R.I2cAckTimeOutCnt = cI2cTimeoutCntMax-1 then
						-- go back to write I2c address again
						NxR.State <= ConfigAK8963I2cAddr;
					else
						NxR.I2cAckTimeOutCnt <= R.I2cAckTimeOutCnt+1;
					end if;
				end if;
				
			when ConfigAK8963I2cData =>
				NxR.I2cWrite	<= '1';
				NxR.I2cStop		<= '1';
				NxR.I2cDataIn	<= cI2cRegDataControl1;
				if I2cCmdAck = '1' then
					NxR.I2cWrite	<= '0';
					NxR.State		<= ConfigAK8963Ack2;
					NxR.I2cAckTimeOutCnt <= 0;
				end if;
				
			when ConfigAK8963Ack2 =>
				if I2cAckOut = '0' then
					NxR.State <= WaitForI2cTransfer;
				else
					-- time out 5 us
					if R.I2cAckTimeOutCnt = cI2cTimeoutCntMax-1 then
						-- go back to write I2c address again
						NxR.State <= ConfigAK8963I2cAddr;
					else
						NxR.I2cAckTimeOutCnt <= R.I2cAckTimeOutCnt+1;
					end if;
				end if;	
			
				
			------------------------------------------------------------------------------------------------	
			-- do the read routine
			------------------------------------------------------------------------------------------------
			when WaitForI2cTransfer =>
				if R.ReadI2cData = '1' then
					NxR.State <= AccelerometerI2cAddr;
					NxR.ReadI2cData <= '0';
				end if;
			
			
			------------------------------------------------------------------------------------------------	
			-- read accelerometer data
			------------------------------------------------------------------------------------------------			
			when AccelerometerI2cAddr =>
				NxR.I2cStart	<= '1';
				NxR.I2cWrite	<= '1';
				NxR.I2cDataIn	<= cI2cAddrMPU9250 & cI2cWrite;
				if I2cCmdAck = '1' then
					NxR.I2cStart	<= '0';
					NxR.I2cWrite	<= '0';
					NxR.State		<= AccelerometerAck0;
					NxR.I2cAckTimeOutCnt <= 0;
				end if;
				
			when AccelerometerAck0 =>
				if I2cAckOut = '0' then
					NxR.State <= AccelerometerI2cRegAddr;
				else
					-- time out 5 us
					if R.I2cAckTimeOutCnt = cI2cTimeoutCntMax-1 then
						-- go back to write I2c address again
						NxR.State <= AccelerometerI2cAddr;
					else
						NxR.I2cAckTimeOutCnt <= R.I2cAckTimeOutCnt+1;
					end if;
				end if;
			
			-- write reg address on bus
			when AccelerometerI2cRegAddr =>
				NxR.I2cWrite	<= '1';
				NxR.I2cDataIn	<= cI2cRegAddrAccel_Xout_H;
				if I2cCmdAck = '1' then
					NxR.I2cWrite	<= '0';
					NxR.State		<= AccelerometerAck1;
					NxR.I2cAckTimeOutCnt <= 0;
				end if;
				
			when AccelerometerAck1 =>
				if I2cAckOut = '0' then
					NxR.State <= AccelerometerRestartI2cAddr;
				else
					-- time out 5 us
					if R.I2cAckTimeOutCnt = cI2cTimeoutCntMax-1 then
						-- go back to write I2c address again
						NxR.State <= AccelerometerI2cAddr;
					else
						NxR.I2cAckTimeOutCnt <= R.I2cAckTimeOutCnt+1;
					end if;
				end if;
				
			-- set restart condition with i2c address
			when AccelerometerRestartI2cAddr =>
				NxR.I2cStart	<= '1';
				NxR.I2cWrite	<= '1';
				NxR.I2cDataIn	<= cI2cAddrMPU9250 & cI2cRead;
				if I2cCmdAck = '1' then
					NxR.I2cStart	<= '0';
					NxR.I2cWrite	<= '0';
					NxR.State		<= AccelerometerAck2;
					NxR.I2cAckTimeOutCnt <= 0;
				end if;
				
			when AccelerometerAck2 =>
				if I2cAckOut = '0' then
					NxR.State <= AccelerometerReadData;
					NxR.ByteCount <= 6-1; -- 6 bytes will be read 
				else
					-- time out 5 us
					if R.I2cAckTimeOutCnt = cI2cTimeoutCntMax-1 then
						-- go back to write I2c address again
						NxR.State <= AccelerometerI2cAddr;
					else
						NxR.I2cAckTimeOutCnt <= R.I2cAckTimeOutCnt+1;
					end if;
				end if;
								
			when AccelerometerReadData =>
				NxR.I2cRead		<= '1';
				if R.ByteCount = 0 then 		-- if this is the last byte to read
					NxR.I2cStop		<= '1';		-- send stop
				else							-- else
					NxR.I2cAckIn 	<= '0';		-- send ack to read on
				end if;
				
				if I2cCmdAck = '1' then
					NxR.I2cRead		<= '0';
					NxR.State		<= AccelerometerSaveData;
				end if;
				
			when AccelerometerSaveData	=>
				-- save data according to byte_count
				case R.ByteCount is
					when 5 =>	NxR.FifoData(tFifoRangeAccelerometer_X_H)	<= std_ulogic_vector(I2cDataOut);
					when 4 =>	NxR.FifoData(tFifoRangeAccelerometer_X_L)	<= std_ulogic_vector(I2cDataOut);
					when 3 =>	NxR.FifoData(tFifoRangeAccelerometer_Y_H)	<= std_ulogic_vector(I2cDataOut);
					when 2 =>	NxR.FifoData(tFifoRangeAccelerometer_Y_L)	<= std_ulogic_vector(I2cDataOut);
					when 1 =>	NxR.FifoData(tFifoRangeAccelerometer_Z_H)	<= std_ulogic_vector(I2cDataOut);
					when 0 =>	NxR.FifoData(tFifoRangeAccelerometer_Z_L)	<= std_ulogic_vector(I2cDataOut);
					when others =>
				end case;
					
				
				if R.ByteCount = 0 then
					NxR.State	<= GyroscopeI2cAddr;
				else
					NxR.State	<= AccelerometerReadData;
					NxR.ByteCount <= R.ByteCount -1;
				end if;
				
				
			------------------------------------------------------------------------------------------------	
			-- read gyroscope data
			------------------------------------------------------------------------------------------------			
			when GyroscopeI2cAddr =>
				NxR.I2cStart	<= '1';
				NxR.I2cWrite	<= '1';
				NxR.I2cDataIn	<= cI2cAddrMPU9250 & cI2cWrite;
				if I2cCmdAck = '1' then
					NxR.I2cStart	<= '0';
					NxR.I2cWrite	<= '0';
					NxR.State		<= GyroscopeAck0;
					NxR.I2cAckTimeOutCnt <= 0;
				end if;
				
			when GyroscopeAck0 =>
				if I2cAckOut = '0' then
					NxR.State <= GyroscopeI2cRegAddr;
				else
					-- time out 5 us
					if R.I2cAckTimeOutCnt = cI2cTimeoutCntMax-1 then
						-- go back to write I2c address again
						NxR.State <= GyroscopeI2cAddr;
					else
						NxR.I2cAckTimeOutCnt <= R.I2cAckTimeOutCnt+1;
					end if;
				end if;
			
			-- write reg address on bus
			when GyroscopeI2cRegAddr =>
				NxR.I2cWrite	<= '1';
				NxR.I2cDataIn	<= cI2cRegAddrGyroscope_Xout_H;
				if I2cCmdAck = '1' then
					NxR.I2cWrite	<= '0';
					NxR.State		<= GyroscopeAck1;
					NxR.I2cAckTimeOutCnt <= 0;
				end if;
				
			when GyroscopeAck1 =>
				if I2cAckOut = '0' then
					NxR.State <= GyroscopeRestartI2cAddr;
				else
					-- time out 5 us
					if R.I2cAckTimeOutCnt = cI2cTimeoutCntMax-1 then
						-- go back to write I2c address again
						NxR.State <= GyroscopeI2cAddr;
					else
						NxR.I2cAckTimeOutCnt <= R.I2cAckTimeOutCnt+1;
					end if;
				end if;
				
			-- set restart condition with i2c address
			when GyroscopeRestartI2cAddr =>
				NxR.I2cStart	<= '1';
				NxR.I2cWrite	<= '1';
				NxR.I2cDataIn	<= cI2cAddrMPU9250 & cI2cRead;
				if I2cCmdAck = '1' then
					NxR.I2cStart	<= '0';
					NxR.I2cWrite	<= '0';
					NxR.State		<= GyroscopeAck2;
					NxR.I2cAckTimeOutCnt <= 0;
				end if;
				
			when GyroscopeAck2 =>
				if I2cAckOut = '0' then
					NxR.State <= GyroscopeReadData;
					NxR.ByteCount <= 6-1; -- 6 bytes will be read 
				else
					-- time out 5 us
					if R.I2cAckTimeOutCnt = cI2cTimeoutCntMax-1 then
						-- go back to write I2c address again
						NxR.State <= GyroscopeI2cAddr;
					else
						NxR.I2cAckTimeOutCnt <= R.I2cAckTimeOutCnt+1;
					end if;
				end if;
								
			when GyroscopeReadData =>
				NxR.I2cRead		<= '1';
				if R.ByteCount = 0 then 		-- if this is the last byte to read
					NxR.I2cStop		<= '1';		-- send stop
				else							-- else
					NxR.I2cAckIn 	<= '0';		-- send ack to read on
				end if;
				
				if I2cCmdAck = '1' then
					NxR.I2cRead		<= '0';
					NxR.State		<= GyroscopeSaveData;
				end if;
				
			when GyroscopeSaveData	=>
				-- save data according to byte_count
				case R.ByteCount is
					when 5 =>	NxR.FifoData(tFifoRangeGyroscope_X_H)	<= std_ulogic_vector(I2cDataOut);
					when 4 =>	NxR.FifoData(tFifoRangeGyroscope_X_L)	<= std_ulogic_vector(I2cDataOut);
					when 3 =>	NxR.FifoData(tFifoRangeGyroscope_Y_H)	<= std_ulogic_vector(I2cDataOut);
					when 2 =>	NxR.FifoData(tFifoRangeGyroscope_Y_L)	<= std_ulogic_vector(I2cDataOut);
					when 1 =>	NxR.FifoData(tFifoRangeGyroscope_Z_H)	<= std_ulogic_vector(I2cDataOut);
					when 0 =>	NxR.FifoData(tFifoRangeGyroscope_Z_L)	<= std_ulogic_vector(I2cDataOut);
					when others =>
				end case;
					
				
				if R.ByteCount = 0 then
					NxR.State	<= MagnetometerI2cAddr;
				else
					NxR.State	<= GyroscopeReadData;
					NxR.ByteCount <= R.ByteCount -1;
				end if;
				
				
			------------------------------------------------------------------------------------------------	
			-- read magnetometer data
			------------------------------------------------------------------------------------------------			
			when MagnetometerI2cAddr =>
				NxR.I2cStart	<= '1';
				NxR.I2cWrite	<= '1';
				NxR.I2cDataIn	<= cI2cAddrAK8963 & cI2cWrite;
				if I2cCmdAck = '1' then
					NxR.I2cStart	<= '0';
					NxR.I2cWrite	<= '0';
					NxR.State		<= MagnetometerAck0;
					NxR.I2cAckTimeOutCnt <= 0;
				end if;
				
			when MagnetometerAck0 =>
				if I2cAckOut = '0' then
					NxR.State <= MagnetometerI2cRegAddr;
				else
					-- time out 5 us
					if R.I2cAckTimeOutCnt = cI2cTimeoutCntMax-1 then
						-- go back to write I2c address again
						NxR.State <= MagnetometerI2cAddr;
					else
						NxR.I2cAckTimeOutCnt <= R.I2cAckTimeOutCnt+1;
					end if;
				end if;
			
			-- write reg address on bus
			when MagnetometerI2cRegAddr =>
				NxR.I2cWrite	<= '1';
				NxR.I2cDataIn	<= cI2cRegAddrMagnetometer_Xout_L;
				if I2cCmdAck = '1' then
					NxR.I2cWrite	<= '0';
					NxR.State		<= MagnetometerAck1;
					NxR.I2cAckTimeOutCnt <= 0;
				end if;
				
			when MagnetometerAck1 =>
				if I2cAckOut = '0' then
					NxR.State <= MagnetometerRestartI2cAddr;
				else
					-- time out 5 us
					if R.I2cAckTimeOutCnt = cI2cTimeoutCntMax-1 then
						-- go back to write I2c address again
						NxR.State <= MagnetometerI2cAddr;
					else
						NxR.I2cAckTimeOutCnt <= R.I2cAckTimeOutCnt+1;
					end if;
				end if;
				
			-- set restart condition with i2c address
			when MagnetometerRestartI2cAddr =>
				NxR.I2cStart	<= '1';
				NxR.I2cWrite	<= '1';
				NxR.I2cDataIn	<= cI2cAddrAK8963 & cI2cRead;
				if I2cCmdAck = '1' then
					NxR.I2cStart	<= '0';
					NxR.I2cWrite	<= '0';
					NxR.State		<= MagnetometerAck2;
					NxR.I2cAckTimeOutCnt <= 0;
				end if;
				
			when MagnetometerAck2 =>
				if I2cAckOut = '0' then
					NxR.State <= MagnetometerReadData;
					NxR.ByteCount <= 6-1; -- 6 bytes will be read 
				else
					-- time out 5 us
					if R.I2cAckTimeOutCnt = cI2cTimeoutCntMax-1 then
						-- go back to write I2c address again
						NxR.State <= MagnetometerI2cAddr;
					else
						NxR.I2cAckTimeOutCnt <= R.I2cAckTimeOutCnt+1;
					end if;
				end if;
								
			when MagnetometerReadData =>
				NxR.I2cRead		<= '1';
				if R.ByteCount = 0 then 		-- if this is the last byte to read
					NxR.I2cStop		<= '1';		-- send stop
				else							-- else
					NxR.I2cAckIn 	<= '0';		-- send ack to read on
				end if;
				
				if I2cCmdAck = '1' then
					NxR.I2cRead		<= '0';
					NxR.State		<= MagnetometerSaveData;
				end if;
				
			when MagnetometerSaveData	=>
				-- save data according to byte_count
				case R.ByteCount is
					when 5 =>	NxR.FifoData(tFifoRangeMagnetometer_X_L)	<= std_ulogic_vector(I2cDataOut);
					when 4 =>	NxR.FifoData(tFifoRangeMagnetometer_X_H)	<= std_ulogic_vector(I2cDataOut);
					when 3 =>	NxR.FifoData(tFifoRangeMagnetometer_Y_L)	<= std_ulogic_vector(I2cDataOut);
					when 2 =>	NxR.FifoData(tFifoRangeMagnetometer_Y_H)	<= std_ulogic_vector(I2cDataOut);
					when 1 =>	NxR.FifoData(tFifoRangeMagnetometer_Z_L)	<= std_ulogic_vector(I2cDataOut);
					when 0 =>	NxR.FifoData(tFifoRangeMagnetometer_Z_H)	<= std_ulogic_vector(I2cDataOut);
					when others =>
				end case;
					
				
				if R.ByteCount = 0 then
					-- additionally save timestamp
					NxR.FifoData(tFifoRangeTimeStamp) <= iTimeStamp;
					NxR.State		<= WriteDataToFifo;
				else
					NxR.State	<= MagnetometerReadData;
					NxR.ByteCount <= R.ByteCount -1;
				end if;
				
			when WriteDataToFifo =>
				NxR.FifoWrite 	<= '1';
				NxR.State		<= WaitForI2cTransfer;
				
				
				
			-- TODO: maybe i2c wrappper would be nice with: read or write , i2c_addr, reg_addr, len of burst read/write and output signal to show when to set data to in-/output

			
		end case;
		
	
	end process;

	-- outputs
	oFifoData 	<= R.FifoData;
	oFifoWrite	<= R.FifoWrite;
	
	
	I2cController: entity work.simple_i2c
		port map(
			clk     => iClk,
			ena     => R.I2cEnable,
			nReset  => inRstAsync,
			clk_cnt => cClkCnt,
			start   => R.I2cStart,
			stop    => R.I2cStop,
			read    => R.I2cRead,
			write   => R.I2cWrite,
			ack_in  => R.I2cAckIn,
			Din     => std_logic_vector(R.I2cDataIn),
			cmd_ack => I2cCmdAck,
			ack_out => I2cAckOut,
			Dout    => I2cDataOut,
			SCL     => ioSCL,
			SDA     => ioSDA
		);

end architecture RTL;
