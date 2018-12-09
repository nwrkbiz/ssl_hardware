-------------------------------------------------------------------------
-- HDC1000.vhd
--
-- Author: Elias Geissler
-- Project: SSL1 Master ESD at FH Hagenberg
-------------------------------------------------------------------------
-- Description: this unit reads data over i2c from HDC1000 and provides them over avalonMM
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.pkgGlobal.all; 
use work.pkgHDC1000.all;

entity HDC1000 is
	generic (
		gClkFrequency	: natural	:= 50_000_000;
		gI2cFrequency	: natural	:= 400_000;
		
		-- sync inDataRdy (min. 2)
		gSyncStages		: natural	:= 2;
		
		-- set reset configuration - default: low active
		gResetIsLowActive	: natural range 0 to 1	:= 1
	);
	port(
		iClk		: in  std_ulogic;
		inRstAsync	: in  std_ulogic;
		
		-- i2c interface
		ioSCL		: inout	std_logic;
		ioSDA		: inout std_logic;
		-- Data ready from HDC1000
		inDataReady	: in std_ulogic;
		
		-- strobe and timestamp
		iStrobe		: in std_ulogic;
		iTimeStamp	: in std_ulogic_vector(cTimeStampWidth-1 downto 0);
		
		-- avalon MM interface
		iAvalonAddr 		: in  std_ulogic_vector(cAvalonAddrWidth-1 downto 0);
		iAvalonRead 		: in  std_ulogic;
		oAvalonReadData 	: out std_ulogic_vector(cAvalonDataWidth-1 downto 0);
		iAvalonWrite 		: in  std_ulogic;
		iAvalonWriteData 	: in  std_ulogic_vector(cAvalonDataWidth-1 downto 0);
		
		-- interrupt to show software that fifo is not empty
		oDataAvailable		: out std_ulogic
	);
end entity HDC1000;

architecture Rtl of HDC1000 is

	signal FifoWrite 			: std_ulogic;
	signal RegDataFrequency 	: std_ulogic_vector(15 downto 0);
	signal RegDataConfig 		: std_ulogic_vector(15 downto 0);
	signal WriteConfigReg 		: std_ulogic;
	signal DataToFifo 			: std_ulogic_vector(cFifoByteWidth*8-1 downto 0);
	signal DataFromFifo 		: std_ulogic_vector(cFifoByteWidth*8-1 downto 0);
	signal FifoShift 			: std_ulogic;
	signal nDataReadySync		: std_ulogic;
	
	constant cSyncDataWidth		: natural := 1;
	signal iDataAsync 	: std_ulogic_vector(cSyncDataWidth-1 downto 0);
	signal oDataSync 		: std_ulogic_vector(cSyncDataWidth-1 downto 0);
	
	signal Reset		: std_ulogic;
	signal RegData : std_ulogic_vector(cRegFileNumberOfBytes*8-1 downto 0);
		
begin
	
	-- convert reset if necessary
	nRst: if gResetIsLowActive = 1 generate		-- low active
			Reset <= inRstAsync;
		end generate;
		
	Rst: if gResetIsLowActive = 0 generate		-- high active
			Reset <= not(inRstAsync);
		end generate;
	
	iDataAsync(0) 	<= inDataReady;
	nDataReadySync	<= oDataSync(0);
	
	Sync: entity work.Sync
		generic map(
			gSyncStages => gSyncStages,
			gDataWidth  => cSyncDataWidth
		)
		port map(
			iClk       => iClk,
			inRstAsync => Reset,
			iData      => iDataAsync,
			oData      => oDataSync
		);
	
	FSMD: entity work.FSMD
		generic map(
			gClkFrequency  => gClkFrequency,
			gI2cFrequency  => gI2cFrequency,
			gFifoByteWidth => cFifoByteWidth
		)
		port map(
			iClk              => iClk,
			inRstAsync        => Reset,
			ioSCL             => ioSCL,
			ioSDA             => ioSDA,
			oFifoData         => DataToFifo,
			oFifoWrite        => FifoWrite,
			iRegDataFrequency => RegDataFrequency,
			iRegDataConfig    => RegDataConfig,
			iWriteConfigReg   => WriteConfigReg,
			iStrobe           => iStrobe,
			iTimeStamp        => iTimeStamp,
			inDataReady       => nDataReadySync
		);
		
	Fifo: entity work.Fifo
		generic map(
			gFifoWidth  => cFifoByteWidth*8,
			gFifoStages => cFifoStages
		)
		port map(
			iClk       		=> iClk,
			inRstAsync 		=> Reset,
			iFifoData  		=> DataToFifo,
			oFifoData  		=> DataFromFifo,
			iFifoShift 		=> FifoShift,
			iFifoWrite 		=> FifoWrite,
			oFifoNotEmpty	=> oDataAvailable
		);
		
	RegFile: entity work.RegFile
		generic map(
			gNumOfBytes    => cRegFileNumberOfBytes,
			gFifoByteWidth => cFifoByteWidth,
			
			-- input default frequency over generic to keep RegFile independent
			gDefaultFrequency => cDefaultI2cReadFreq,
			gRegAddrFrequency => cRegAddrFrequenzy_L
		)
		port map(
			iClk              => iClk,
			inRstAsync        => Reset,
			iAvalonAddr       => iAvalonAddr,
			iAvalonRead       => iAvalonRead,
			oAvalonReadData   => oAvalonReadData,
			iAvalonWrite      => iAvalonWrite,
			iAvalonWriteData  => iAvalonWriteData,
			iFifoData         => DataFromFifo,
			oFifoShift        => FifoShift,
			oRegData		  => RegData
		);
		
		-- detect write into config reg
		WriteConfigReg 	<= iAvalonWrite when iAvalonAddr = std_ulogic_vector(to_unsigned(cRegAddrConfig_H, cAvalonAddrWidth)) else '0';
		RegDataConfig(15 downto 8)	<= RegData(cRegAddrConfig_H*8+7 downto cRegAddrConfig_H*8);
		RegDataConfig(7  downto 0)	<= RegData(cRegAddrConfig_L*8+7 downto cRegAddrConfig_L*8);
	
		RegDataFrequency(15 downto 8)	<= RegData(cRegAddrFrequenzy_H*8+7 downto cRegAddrFrequenzy_H*8);
		RegDataFrequency(7  downto 0)	<= RegData(cRegAddrFrequenzy_L*8+7 downto cRegAddrFrequenzy_L*8);
		

end architecture Rtl;














