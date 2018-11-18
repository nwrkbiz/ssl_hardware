-------------------------------------------------------------------------
-- TbFSMD.vhd
--
-- Author: Elias Geissler
-- Project: SSL1 Master ESD at FH Hagenberg
-------------------------------------------------------------------------
-- Description: testbench for FSMD
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.pkgGlobal.all; 
use work.pkgHDC1000.all;

entity TbFSMD is
end entity TbFSMD;

architecture Bhv of TbFSMD is
	
	constant cClkFrequency 	: natural	:= 50_000_000;
	constant cClkPeriod		: time		:= 1 sec/cClkFrequency;
	constant cI2cFrequency 	: natural	:= 400_000;
	constant cFifoByteWidth : natural	:= 8;
	constant cFifoWidth 	: natural	:= cFifoByteWidth*8;
	constant cFifoStages 	: natural	:= 8;
	
	signal iClk 				: std_ulogic	:= '0';
	signal inRstAsync 			: std_ulogic	:= not('1');
	signal ioSCL 				: std_logic;
	signal ioSDA 				: std_logic;
	signal oFifoWrite 			: std_ulogic;
	signal iRegDataFrequency 	: std_ulogic_vector(15 downto 0);
	signal iRegDataConfig 		: std_ulogic_vector(15 downto 0);
	signal iWriteConfigReg 		: std_ulogic;
	signal iStrobe 				: std_ulogic;
	signal iTimeStamp 			: std_ulogic_vector(cTimeStampWidth-1 downto 0);
	signal inDataReady 			: std_ulogic;
	signal oDataToFifo 			: std_ulogic_vector(cFifoByteWidth*8-1 downto 0);
	signal oDataFromFifo 		: std_ulogic_vector(cFifoByteWidth*8-1 downto 0);
	
	-- avalon
	signal iAvalonAddr 			: std_ulogic_vector(cAvalonAddrWidth-1 downto 0);
	signal iAvalonRead 			: std_ulogic;
	signal oAvalonReadData 		: std_ulogic_vector(cAvalonDataWidth-1 downto 0);
	signal iAvalonWrite 		: std_ulogic;
	signal iAvalonWriteData 	: std_ulogic_vector(cAvalonDataWidth-1 downto 0);
	
	signal oFifoShift 			: std_ulogic;
	
	
	signal iRstAsync : std_logic;
	signal SlaveReadReq : std_logic;
	signal SlaveDataValid : std_logic;
	signal SlaveDataFromMaster : std_logic_vector(7 downto 0);
	signal SlaveSCL : std_logic;
	signal SlaveSDA : std_logic;


	
begin
	
	-- clk and reset
	iClk		<= not(iClk) after cClkPeriod/2;
	inRstAsync	<= not('0') after 100 ns;
	
	-- avalon
	iAvalonAddr 	<= (others => '0');
	iAvalonRead 	<= '0';
	iAvalonWrite	<= '0';
	iAvalonWriteData <= (others => '0');
	
	-- i2c
	ioSCL <= 'H';
	ioSDA <= 'H';
	
	FSMD: entity work.FSMD
		generic map(
			gClkFrequency  => cClkFrequency,
			gI2cFrequency  => cI2cFrequency,
			gFifoByteWidth => cFifoByteWidth
		)
		port map(
			iClk              => iClk,
			inRstAsync        => inRstAsync,
			ioSCL             => ioSCL,
			ioSDA             => ioSDA,
			oFifoData         => oDataToFifo,
			oFifoWrite        => oFifoWrite,
			iRegDataFrequency => iRegDataFrequency,
			iRegDataConfig    => iRegDataConfig,
			iWriteConfigReg   => iWriteConfigReg,
			iStrobe           => iStrobe,
			iTimeStamp        => iTimeStamp,
			inDataReady       => inDataReady
		);
		
		inDataReady <= not('1');
		
	Fifo: entity work.Fifo
		generic map(
			gFifoWidth  => cFifoWidth,
			gFifoStages => cFifoStages
		)
		port map(
			iClk       => iClk,
			inRstAsync => inRstAsync,
			iFifoData  => oDataToFifo,
			oFifoData  => oDataFromFifo,
			iFifoShift => oFifoShift,
			iFifoWrite => oFifoWrite
		);
		
	RegFile: entity work.RegFile
		generic map(
			gNumOfBytes    => cRegFileNumberOfBytes,
			gFifoByteWidth => cFifoByteWidth
		)
		port map(
			iClk              => iClk,
			inRstAsync        => inRstAsync,
			iAvalonAddr       => iAvalonAddr,
			iAvalonRead       => iAvalonRead,
			oAvalonReadData   => oAvalonReadData,
			iAvalonWrite      => iAvalonWrite,
			iAvalonWriteData  => iAvalonWriteData,
			oRegDataFrequency => iRegDataFrequency,
			oRegDataConfig    => iRegDataConfig,
			oWriteConfigReg   => iWriteConfigReg,
			iFifoData         => oDataFromFifo,
			oFifoShift        => oFifoShift
		);
		
	StrobeTimeStamp: entity work.StrobeGenAndTimeStamp
		generic map(
			gClkFreq        => cClkFrequency,
			gClkDiv         => 1_000_000, -- for simulation use a 1us-strobe
			gTimeStampWidth => cTimeStampWidth
		)
		port map(
			iClk       => iClk,
			inRstAsync => inRstAsync,
			oStrobe    => iStrobe,
			oTimeStamp => iTimeStamp
		);
		
		
	-- test i2c slave
	-- slave con NOT handle 'H' so '1' is needed
	I2cSlave: entity work.I2C_slave
		generic map(
			SLAVE_ADDR => "H000000"
		)
		port map(
			scl              => ioSCL,
			sda              => ioSDA,
			clk              => iClk,
			rst              => iRstAsync,
			read_req         => SlaveReadReq,
			data_to_master   => "10101001",
			data_valid       => SlaveDataValid,
			data_from_master => SlaveDataFromMaster
		);
		
		SlaveSCL 	<= '1' when ioSCL = 'H' else ioSCL;
		SlaveSDA	<= '1' when ioSDA = 'H' else ioSDA;
		
		-- reset for slave
		iRstAsync <= not(inRstAsync);

end architecture Bhv;














