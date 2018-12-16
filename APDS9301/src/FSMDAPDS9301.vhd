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
	
	constant cI2cMaxBurst	: natural := 4;
	type tI2cData is array (0 to cI2cMaxBurst-1) of std_ulogic_vector(7 downto 0);	
		
	type tState is (Idle, ConfigControlReg, WaitForI2cTransfer, WriteDataToFifo,
					ReadData_CH0, SaveData_CH0, ReadData_CH1, SaveData_CH1
					);
	
	type tData is record
		State 		: tState;
		FreqCount	: natural;
		ReadI2cData	: std_ulogic;
		
		I2cAddr			: std_ulogic_vector(6 downto 0);
		I2cRegAddr		: std_ulogic_vector(7 downto 0);
		I2cRead 		: std_ulogic;
		I2cWrite 		: std_ulogic;
		I2cDataIn 		: tI2cData;
		I2cBurstCount	: natural range 0 to cI2cMaxBurst;
		
		FifoData	: std_ulogic_vector(gFifoByteWidth*8-1 downto 0);
		FifoWrite	: std_ulogic;
	end record tData;
	
	constant cDefaultData : tData := (
		State 		=> Idle,
		FreqCount	=> 0,
		ReadI2cData	=> '0',
		
		I2cAddr			=> (others => '0'),
		I2cRegAddr		=> (others => '0'),
		I2cRead 		=> '0',
		I2cWrite 		=> '0',
		I2cDataIn 		=> (others => (others =>'0')),
		I2cBurstCount	=> 0,
		
		FifoData	=> (others => '0'),
		FifoWrite	=> '0'
	);
	
	signal R,NxR	: tData;
	
	signal I2cDataInVec, I2cDataOutVec	: std_ulogic_vector(cI2cMaxBurst*8-1 downto 0);
	signal I2cTransferDone : std_ulogic;
	
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
		R, iRegDataFrequency, iStrobe, iTimeStamp, I2cDataOutVec, I2cTransferDone
	) is	
	begin
		-- defaults
		NxR <= R;
		NxR.I2cRead		<= '0';
		NxR.I2cWrite	<= '0';
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
					NxR.State <= ConfigControlReg;
				--end if;
				
			when ConfigControlReg =>
				-- write 3 to cotrol register to power up the device
				NxR.I2cAddr 		<= cI2cAddr;
				NxR.I2cRegAddr		<= cI2cRegAddrControl;
				NxR.I2cDataIn(0)	<= cI2cRegControlData;
				NxR.I2cBurstCount 	<= 1; --write 1 byte
				NxR.I2cWrite		<= '1';
				if I2cTransferDone = '1' then
					NxR.I2cWrite	<= '0';
					NxR.State		<= WaitForI2cTransfer;
				end if;
				
			-- after power up is done i2c reads are done with a specific frequency
			when WaitForI2cTransfer =>
				if R.ReadI2cData = '1' then
					NxR.State <= ReadData_CH0;
					NxR.ReadI2cData <= '0';
				end if;
				
			when ReadData_CH0 =>
				NxR.I2cAddr 		<= cI2cAddr;
				NxR.I2cRegAddr		<= cI2cRegAddrLight_Ch0_L;
				NxR.I2cBurstCount 	<= 2; -- read 2 bytes of data
				NxR.I2cRead	<= '1';
				if I2cTransferDone = '1' then
					NxR.I2cRead	<= '0';
					NxR.State		<= SaveData_CH0;
				end if;
			
			when SaveData_CH0	=>
				NxR.FifoData(tFifoRangeLight_Ch0_L)	<= I2cDataOutVec(7 downto 0);		-- first byte read
				NxR.FifoData(tFifoRangeLight_Ch0_H)	<= I2cDataOutVec(15 downto 8);		-- second
				NxR.State		<= ReadData_CH1;
				
			when ReadData_CH1 =>
				NxR.I2cAddr 		<= cI2cAddr;
				NxR.I2cRegAddr		<= cI2cRegAddrLight_Ch1_L;
				NxR.I2cBurstCount 	<= 2; -- read 2 bytes of data
				NxR.I2cRead	<= '1';
				if I2cTransferDone = '1' then
					NxR.I2cRead	<= '0';
					NxR.State		<= SaveData_CH1;
				end if;
			
			when SaveData_CH1	=>
				NxR.FifoData(tFifoRangeLight_Ch1_L)	<= I2cDataOutVec(7 downto 0);		-- first byte read
				NxR.FifoData(tFifoRangeLight_Ch1_H)	<= I2cDataOutVec(15 downto 8);		-- second
				-- save time stamp
				NxR.FifoData(tFiforangeTimeStamp)	<= iTimeStamp;
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
	
	
	I2cController: entity work.I2cController
		generic map(
			gClkFrequency       => gClkFrequency,
			gI2cFrequency       => gI2cFrequency,
			gNumOfParallelBytes => cI2cMaxBurst
		)
		port map(
			iClk           => iClk,
			inRstAsync     => inRstAsync,
			ioSCL          => ioSCL,
			ioSDA          => ioSDA,
			iI2cAddr       => R.I2cAddr,
			iI2cRegAddr    => R.I2cRegAddr,
			iI2cData       => I2cDataInVec,
			oI2cData       => I2cDataOutVec,
			iI2cBurstCount => R.I2cBurstCount,
			iI2cRead       => R.I2cRead,
			iI2cWrite      => R.I2cWrite,
			oTransferDone  => I2cTransferDone
		);
		
	-- connect data_in
	forLoop: for i in 0 to cI2cMaxBurst-1 generate 
		I2cDataInVec(7+8*i downto 0+8*i) <= R.I2cDataIn(i);
	end generate;

end architecture RTL;
