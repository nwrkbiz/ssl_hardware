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
		iTimeStamp	: in std_ulogic_vector(cTimeStampWidth-1 downto 0)
	);
end entity FSMD;

architecture RTL of FSMD is
	
	constant cI2cMaxBurst	: natural := 4;
	type tI2cData is array (0 to cI2cMaxBurst-1) of std_ulogic_vector(7 downto 0);	
		
	type tState is (Idle, WaitForI2cTransfer, TriggerMeasurement, SaveData, WriteDataToFifo);
	
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
		R, iRegDataFrequency, iStrobe, iTimeStamp, I2cDataOutVec, I2cTransferDone) is	
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
				NxR.State <= WaitForI2cTransfer;
				
			when WaitForI2cTransfer =>
				if R.ReadI2cData = '1' then
					NxR.State <= TriggerMeasurement;
					NxR.ReadI2cData <= '0';
				end if;
				
			-- to trigger a temp+ humidity measurement, regaddr 0x00 has to be written to the chip
			-- then i2c will be written until the chip acknoledges it - then data is ready to be written
			when TriggerMeasurement =>
				-- set start condition and i2c addr
				NxR.I2cAddr 		<= cI2cAddr;
				NxR.I2cRegAddr		<= cI2cRegAddrTemp;
				NxR.I2cBurstCount 	<= 4; -- read 4 bytes of data
				NxR.I2cRead	<= '1';
				if I2cTransferDone = '1' then
					NxR.I2cRead	<= '0';
					NxR.State		<= SaveData;
				end if;
				
			when SaveData	=>
				NxR.FifoData(tFifoRangeTemp_H)		<= I2cDataOutVec(7 downto 0);		-- first byte read
				NxR.FifoData(tFifoRangeTemp_L)		<= I2cDataOutVec(15 downto 8);		-- second
				NxR.FifoData(tFifoRangeHumidity_H)	<= I2cDataOutVec(23 downto 16);		-- third
				NxR.FifoData(tFifoRangeHumidity_L)	<= I2cDataOutVec(31 downto 24);		-- fourth
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
