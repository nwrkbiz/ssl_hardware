-------------------------------------------------------------------------
-- FSMD.vhd
--
-- Author: Elias Geissler
-- Project: SSL1 Master ESD at FH Hagenberg
-------------------------------------------------------------------------
-- Description: FSMD to read values from HDC1000 over i2c and put data into fifo

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.pkgGlobal.all;
use work.pkgHDC1000.all;

entity FSMD is
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
		iRegDataConfig		: in std_ulogic_vector(15 downto 0);
		-- this signal starts a i2c write to config register of the HDC1000
		iWriteConfigReg		: in std_ulogic;
		
		-- strobe and timestamp
		iStrobe		: in std_ulogic;
		iTimeStamp	: in std_ulogic_vector(cTimeStampWidth-1 downto 0);
		
		-- data ready from HDC1000
		inDataReady	: in std_ulogic
	);
end entity FSMD;

architecture RTL of FSMD is
	
	constant cClkCnt 			: unsigned(7 downto 0) 	:= to_unsigned(gClkFrequency/gI2cFrequency/5 -1,8); -- creates a 400kHz clk
	constant cI2cTimeoutCntMax	: natural				:= gClkFrequency/200_000; -- wait for 5 us
	
		type tState is (Idle, WaitForI2cTransfer,
						TriggerMeasurementI2cAddr, TriggerMeasurementWaitOnAck0, 
						TriggerMeasurementI2cRegAddr, TriggerMeasurementWaitOnAck1, 
						WaitForDataRdyReset, WaitForDataRdySet, 
						ReadDataI2cAddr, ReadDataWaitOnAck,
						ReadDataTempData_H, SaveTempData_H, ReadDataTempData_L, SaveTempData_L, 
						ReadDataHumidData_H, SaveHumidData_H, ReadDataHumidData_L, SaveHumidData_L,
						WriteDataToFifo);
	
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
		I2cAckTimeOutCnt	=> 0
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
		R, iRegDataFrequency, iStrobe, inDataReady, iTimeStamp, I2cCmdAck, I2cDataOut, I2cAckOut
	) is	
	begin
		-- defaults
		NxR <= R;
		NxR.I2cEnable 	<= '1';
		NxR.I2cStart	<= '0';
		NxR.I2cRead		<= '0';
		NxR.I2cWrite	<= '0';
		NxR.I2cStop		<= '0';
		NxR.I2cAckIn	<= '0'; -- '0' means always active
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
				NxR.State <= WaitForI2cTransfer;
				
			when WaitForI2cTransfer =>
				if R.ReadI2cData = '1' then
					NxR.State <= TriggerMeasurementI2cAddr;
					NxR.ReadI2cData <= '0';
				end if;
				
			-- to trigger a temp+ humidity measurement, regaddr 0x00 have to be written to the chip	
			when TriggerMeasurementI2cAddr =>
				-- set start condition and i2c addr
				NxR.I2cStart	<= '1';
				NxR.I2cDataIn	<= cI2cAddr & cI2cWrite;
				NxR.I2cWrite	<= '1';
				if I2cCmdAck = '1' then
					NxR.I2cStart	<= '0';
					NxR.I2cWrite	<= '0';
					NxR.State		<= TriggerMeasurementWaitOnAck0;
					NxR.I2cAckTimeOutCnt <= 0;
				end if;
				
			when TriggerMeasurementWaitOnAck0 =>
				if I2cAckOut = '0' then
					NxR.State <= TriggerMeasurementI2cRegAddr;
				else
					-- timeout 5 us
					if R.I2cAckTimeOutCnt = cI2cTimeoutCntMax-1 then
						-- go back to write I2c address again
						NxR.State <= TriggerMeasurementI2cAddr;
					else
						NxR.I2cAckTimeOutCnt <= R.I2cAckTimeOutCnt+1;
					end if;
				end if;
				
			when TriggerMeasurementI2cRegAddr =>
				NxR.I2cWrite	<= '1';
				NxR.I2cStop		<= '1';
				NxR.I2cDataIn	<= cI2cRegAddrTemp;
				if I2cCmdAck = '1' then
					NxR.I2cWrite	<= '0';
					NxR.I2cStop		<= '0';
					NxR.State		<= TriggerMeasurementWaitOnAck1;
					NxR.I2cAckTimeOutCnt <= 0;
				end if;
				
			when TriggerMeasurementWaitOnAck1 =>
				if I2cAckOut = '0' then
					NxR.State <= WaitForDataRdyReset;
				else
					-- timeout 5 us
					if R.I2cAckTimeOutCnt = cI2cTimeoutCntMax-1 then
						-- go back to write I2c address again
						NxR.State <= TriggerMeasurementI2cAddr;
					else
						NxR.I2cAckTimeOutCnt <= R.I2cAckTimeOutCnt+1;
					end if;
				end if;
				
			when WaitForDataRdyReset =>
				if inDataReady = not('0') then
					NxR.State	<= WaitForDataRdySet;
				end if;
				
			when WaitForDataRdySet =>
				if inDataReady = not('1') then
					NxR.State	<= ReadDataI2cAddr;
				end if;
				
			when ReadDataI2cAddr =>
				NxR.I2cStart	<= '1';
				NxR.I2cWrite	<= '1';
				NxR.I2cDataIn	<= cI2cAddr & cI2cRead;
				if I2cCmdAck = '1' then
					NxR.I2cStart	<= '0';
					NxR.I2cWrite	<= '0';
					NxR.State		<= ReadDataWaitOnAck;
					NxR.I2cAckTimeOutCnt <= 0;
				end if;
				
			when ReadDataWaitOnAck =>
				if I2cAckOut = '0' then
					NxR.State <= ReadDataTempData_H;
				else
					-- time out 5 us
					if R.I2cAckTimeOutCnt = cI2cTimeoutCntMax-1 then
						-- go back one state to write I2c address again
						NxR.State <= ReadDataI2cAddr;
					else
						NxR.I2cAckTimeOutCnt <= R.I2cAckTimeOutCnt+1;
					end if;
				end if;
			
			when ReadDataTempData_H =>
				-- DataOut is available 1 clock cycle later as I2cCmdAck
				NxR.I2cRead		<= '1';
				if I2cCmdAck = '1' then
					NxR.I2cRead		<= '0';
					NxR.State		<= SaveTempData_H;
				end if;
				
			when SaveTempData_H =>
				-- save data from last state
				NxR.FifoData(tFifoRangeTemp_H)	<= std_ulogic_vector(I2cDataOut);
				NxR.State	<= ReadDataTempData_L;
				
			when ReadDataTempData_L =>
				NxR.I2cRead		<= '1';
				if I2cCmdAck = '1' then
					NxR.I2cRead		<= '0';
					NxR.State		<= SaveTempData_L;
				end if;
				
			when SaveTempData_L	=>
				-- save data from last state
				NxR.FifoData(tFifoRangeTemp_L)	<= std_ulogic_vector(I2cDataOut);
				NxR.State		<= ReadDataHumidData_H;
				
			when ReadDataHumidData_H =>
				NxR.I2cRead		<= '1';
				if I2cCmdAck = '1' then
					NxR.I2cRead		<= '0';
					NxR.State		<= SaveHumidData_H;
				end if;
				
			when SaveHumidData_H	=>
				-- save data from last state
				NxR.FifoData(tFifoRangeHumidity_H)	<= std_ulogic_vector(I2cDataOut);
				NxR.State		<= ReadDataHumidData_L;
				
			when ReadDataHumidData_L =>			
				NxR.I2cRead		<= '1';
				NxR.I2cStop		<= '1';	-- last read -> stop is needed
				if I2cCmdAck = '1' then
					NxR.I2cRead		<= '0';
					NxR.State		<= SaveHumidData_L;
				end if;
				
			when SaveHumidData_L	=>
				-- save data from last state
				NxR.FifoData(tFifoRangeHumidity_L)	<= std_ulogic_vector(I2cDataOut);
				-- save time stamp
				NxR.FifoData(tFiforangeTimeStamp)	<= iTimeStamp;
				NxR.State		<= WriteDataToFifo;
				
			when WriteDataToFifo =>
				NxR.FifoWrite 	<= '1';
				NxR.State		<= WaitForI2cTransfer;
				
				
				
			-- after the complete i2c tranfser there is some time to do other stuff like reconfiguring the sensor, etc.
			-- make sure to end up in WaitForI2cTransfer after this stuff
			-- TODO: write to config register if necessary
			
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
