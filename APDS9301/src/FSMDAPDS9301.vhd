-------------------------------------------------------------------------
-- FsmdAPDS9301.vhd
--
-- Author: Elias Geissler
-- Project: SSL1 Master ESD at FH Hagenberg
-------------------------------------------------------------------------
-- Description: FSMD to read values from APDS9301 over i2c and put data into fifo

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.pkgGlobal.all;
use work.pkgAPDS9301.all;

entity FsmdAPDS9301 is
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
		iRegDataConfig		: in std_ulogic_vector(7 downto 0);
		-- this signal starts a i2c write to config register of the HDC1000
		iWriteConfigReg		: in std_ulogic;
		
		-- strobe and timestamp
		iStrobe		: in std_ulogic;
		iTimeStamp	: in std_ulogic_vector(cTimeStampWidth-1 downto 0)
	);
end entity FsmdAPDS9301;

architecture RTL of FsmdAPDS9301 is
	
	constant cClkCnt 			: unsigned(7 downto 0) 	:= to_unsigned(gClkFrequency/gI2cFrequency/5 -1,8); -- creates a 400kHz clk
	constant cI2cTimeoutCntMax	: natural				:= gClkFrequency/200_000; -- wait for 5 us
	
		
	type tState is (Idle,
					PowerUpI2cAddr, PowerUpRegAddr, PowerUpWriteData,
					PowerUpAck0, PowerUpAck1, PowerUpAck2,
					WaitForI2cTransfer,
					I2cAddr0, I2cAddr1, RegAddrLight_Ch0_L,
					ReadDataLight_Ch0_L, ReadDataLight_Ch0_H, ReadDataLight_Ch1_L, ReadDataLight_Ch1_H,
					SaveDataLight_Ch0_L, SaveDataLight_Ch0_H, SaveDataLight_Ch1_L, SaveDataLight_Ch1_H,
					WaitOnAck0, WaitOnAck1, WaitOnAck2,
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
					NxR.State <= PowerUpI2cAddr;
				--end if;
				
			when PowerUpI2cAddr =>
				NxR.I2cStart	<= '1';
				NxR.I2cWrite	<= '1';
				NxR.I2cDataIn	<= cI2cAddr & cI2cWrite;
				if I2cCmdAck = '1' then
					NxR.I2cStart	<= '0';
					NxR.I2cWrite	<= '0';
					NxR.State		<= PowerUpAck0;
					NxR.I2cAckTimeOutCnt <= 0;
				end if;
				
			when PowerUpAck0 =>
				if I2cAckOut = '0' then
					NxR.State <= PowerUpRegAddr;
				else
					-- time out 5 us
					if R.I2cAckTimeOutCnt = cI2cTimeoutCntMax-1 then
						-- go back one state to write I2c address again
						NxR.State <= PowerUpI2cAddr;
					else
						NxR.I2cAckTimeOutCnt <= R.I2cAckTimeOutCnt+1;
					end if;
				end if;
				
			-- write reg address on bus
			when PowerUpRegAddr =>
				NxR.I2cWrite	<= '1';
				NxR.I2cDataIn	<= cI2cRegAddrControl;
				if I2cCmdAck = '1' then
					NxR.I2cWrite	<= '0';
					NxR.State		<= PowerUpAck1;
					NxR.I2cAckTimeOutCnt <= 0;
				end if;
				
			when PowerUpAck1 =>
				if I2cAckOut = '0' then
					NxR.State <= PowerUpWriteData;
				else
					-- time out 5 us
					if R.I2cAckTimeOutCnt = cI2cTimeoutCntMax-1 then
						-- go back one state to write I2c address again
						NxR.State <= PowerUpI2cAddr;
					else
						NxR.I2cAckTimeOutCnt <= R.I2cAckTimeOutCnt+1;
					end if;
				end if;
				
			when PowerUpWriteData =>
				NxR.I2cWrite	<= '1';
				NxR.I2cStop		<= '1';
				NxR.I2cDataIn	<= cI2cRegControlData;
				if I2cCmdAck = '1' then
					NxR.I2cWrite	<= '0';
					NxR.State		<= PowerUpAck2;
					NxR.I2cAckTimeOutCnt <= 0;
				end if;
				
			when PowerUpAck2 =>
				if I2cAckOut = '0' then
					NxR.State <= WaitForI2cTransfer;
				else
					-- time out 5 us
					if R.I2cAckTimeOutCnt = cI2cTimeoutCntMax-1 then
						-- go back one state to write I2c address again
						NxR.State <= PowerUpI2cAddr;
					else
						NxR.I2cAckTimeOutCnt <= R.I2cAckTimeOutCnt+1;
					end if;
				end if;
				
			-- after power up is done i2c reads are done with a specific frequency
			when WaitForI2cTransfer =>
				if R.ReadI2cData = '1' then
					NxR.State <= I2cAddr0;
					NxR.ReadI2cData <= '0';
				end if;
			
			-- start reading the ADC channels
			-- write i2c address on bus				
			when I2cAddr0 =>
				NxR.I2cStart	<= '1';
				NxR.I2cWrite	<= '1';
				NxR.I2cDataIn	<= cI2cAddr & cI2cWrite;
				if I2cCmdAck = '1' then
					NxR.I2cStart	<= '0';
					NxR.I2cWrite	<= '0';
					NxR.State		<= WaitOnAck0;
					NxR.I2cAckTimeOutCnt <= 0;
				end if;
				
			when WaitOnAck0 =>
				if I2cAckOut = '0' then
					NxR.State <= RegAddrLight_Ch0_L;
				else
					-- time out 5 us
					if R.I2cAckTimeOutCnt = cI2cTimeoutCntMax-1 then
						-- go back one state to write I2c address again
						NxR.State <= I2cAddr0;
					else
						NxR.I2cAckTimeOutCnt <= R.I2cAckTimeOutCnt+1;
					end if;
				end if;
			
			-- write reg address on bus
			when RegAddrLight_Ch0_L =>
				NxR.I2cWrite	<= '1';
				NxR.I2cDataIn	<= cI2cRegAddrLight_Ch0_L;
				if I2cCmdAck = '1' then
					NxR.I2cWrite	<= '0';
					NxR.State		<= WaitOnAck1;
					NxR.I2cAckTimeOutCnt <= 0;
				end if;
				
			when WaitOnAck1 =>
				if I2cAckOut = '0' then
					NxR.State <= I2cAddr1;
				else
					-- time out 5 us
					if R.I2cAckTimeOutCnt = cI2cTimeoutCntMax-1 then
						-- go back one state to write I2c address again
						NxR.State <= I2cAddr0;
					else
						NxR.I2cAckTimeOutCnt <= R.I2cAckTimeOutCnt+1;
					end if;
				end if;
				
			-- set restart condition with i2c address (now with read)
			when I2cAddr1 =>
				NxR.I2cStart	<= '1';
				NxR.I2cWrite	<= '1';
				NxR.I2cDataIn	<= cI2cAddr & cI2cRead;
				if I2cCmdAck = '1' then
					NxR.I2cStart	<= '0';
					NxR.I2cWrite	<= '0';
					NxR.State		<= WaitOnAck2;
					NxR.I2cAckTimeOutCnt <= 0;
				end if;
				
			when WaitOnAck2 =>
				if I2cAckOut = '0' then
					NxR.State <= ReadDataLight_Ch0_L;
				else
					-- time out 5 us
					if R.I2cAckTimeOutCnt = cI2cTimeoutCntMax-1 then
						-- go back one state to write I2c address again
						NxR.State <= I2cAddr0;
					else
						NxR.I2cAckTimeOutCnt <= R.I2cAckTimeOutCnt+1;
					end if;
				end if;
					
			----------------------------------------------------------------------------------------
			-- read data of channel 0 low byte			
			----------------------------------------------------------------------------------------
			when ReadDataLight_Ch0_L =>
				NxR.I2cRead		<= '1';
				NxR.I2cAckIn 	<= '0'; -- send ACK to make sure APDS9301 sends another byte of data from the next address
				if I2cCmdAck = '1' then
					NxR.I2cRead		<= '0';
					NxR.State		<= SaveDataLight_Ch0_L;
				end if;
				
			when SaveDataLight_Ch0_L =>
				-- save data from last state
				NxR.FifoData(tFifoRangeLight_Ch0_L)	<= std_ulogic_vector(I2cDataOut);
				NxR.State		<= ReadDataLight_Ch0_H;
			
			----------------------------------------------------------------------------------------
			-- read data of channel 0 high byte			
			----------------------------------------------------------------------------------------	
			when ReadDataLight_Ch0_H =>
				NxR.I2cRead		<= '1';
				NxR.I2cAckIn 	<= '0'; -- send ACK to make sure APDS9301 sends another byte of data from the next address
				if I2cCmdAck = '1' then
					NxR.I2cRead		<= '0';
					NxR.State		<= SaveDataLight_Ch0_H;
				end if;
				
			when SaveDataLight_Ch0_H =>
				-- save data from last state
				NxR.FifoData(tFifoRangeLight_Ch0_H)	<= std_ulogic_vector(I2cDataOut);
				NxR.State		<= ReadDataLight_Ch1_L;
			
			----------------------------------------------------------------------------------------
			-- read data of channel 1 low byte			
			----------------------------------------------------------------------------------------	
			when ReadDataLight_Ch1_L =>
				NxR.I2cRead		<= '1';
				NxR.I2cAckIn 	<= '0'; -- send ACK to make sure APDS9301 sends another byte of data from the next address
				if I2cCmdAck = '1' then
					NxR.I2cRead		<= '0';
					NxR.State		<= SaveDataLight_Ch1_L;
				end if;
				
			when SaveDataLight_Ch1_L =>
				-- save data from last state
				NxR.FifoData(tFifoRangeLight_Ch1_L)	<= std_ulogic_vector(I2cDataOut);
				NxR.State		<= ReadDataLight_Ch1_H;
			
			----------------------------------------------------------------------------------------
			-- read data of channel 1 high byte			
			----------------------------------------------------------------------------------------	
			when ReadDataLight_Ch1_H =>
				NxR.I2cRead		<= '1';
				NxR.I2cStop		<= '1'; -- send stop condition
				if I2cCmdAck = '1' then
					NxR.I2cRead		<= '0';
					NxR.State		<= SaveDataLight_Ch1_H;
				end if;
				
			when SaveDataLight_Ch1_H =>
				-- save data from last state
				NxR.FifoData(tFifoRangeLight_Ch1_H)	<= std_ulogic_vector(I2cDataOut);
				-- additionally save timestamp
				NxR.FifoData(tFifoRangeTimeStamp) <= iTimeStamp;
				NxR.State		<= WriteDataToFifo;
				
			when WriteDataToFifo =>
				NxR.FifoWrite 	<= '1';
				NxR.State		<= WaitForI2cTransfer;
				
					
			-- after the complete i2c tranfser there is some time to do other stuff like reconfiguring the sensor, etc.
			-- make sure to end up in WaitForI2cTransfer after this stuff
			-- TODO: write to config register if necessary (feature)
			
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
