-------------------------------------------------------------------------
-- MPU9250.vhd
--
-- Author: Elias Geissler
-- Project: SSL1 Master ESD at FH Hagenberg
-------------------------------------------------------------------------
-- Description: this unit reads data over i2c from MPU9250 and provides them over avalonMM
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.pkgGlobal.all; 
use work.pkgMPU9250.all;

entity MPU9250 is
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
		-- this bit controls the LSB of the I2c address of MPU9250
		AD0_SD0		: out	std_ulogic;
		
		-- strobe and timestamp
		iStrobe		: in std_ulogic;
		iTimeStamp	: in std_ulogic_vector(cTimeStampWidth-1 downto 0);
		
		-- input is a switch on the dev board
		iStreamingModeEn	: in std_ulogic;
				
		-- avalon MM interface
		iAvalonAddr 		: in  std_ulogic_vector(cAvalonAddrWidth-1 downto 0);
		iAvalonRead 		: in  std_ulogic;
		oAvalonReadData 	: out std_ulogic_vector(cAvalonDataWidth-1 downto 0);
		iAvalonWrite 		: in  std_ulogic;
		iAvalonWriteData 	: in  std_ulogic_vector(cAvalonDataWidth-1 downto 0)
	);
end entity MPU9250;

architecture Rtl of MPU9250 is

	signal FifoWrite 			: std_ulogic;
	signal DataToFifo 			: std_ulogic_vector(cFifoByteWidth*8-1 downto 0) := (others => '1');
	signal DataFromFifo 		: std_ulogic_vector(cFifoByteWidth*8-1 downto 0);
	signal FifoShift 			: std_ulogic;
	
	signal Reset		: std_ulogic;
	signal RegData : std_ulogic_vector(cRegFileNumberOfBytes*8-1 downto 0);
	
	-- signals for fifos for event mode
	signal DataToFifo256 : std_ulogic_vector(cFifoByteWidth*8-1 downto 0);
	signal DataFromFifo256 : std_ulogic_vector(cFifoByteWidth*8-1 downto 0);
	signal FifoShift256 : std_ulogic;
	signal FifoWrite256 : std_ulogic;
	signal FifoEmpty256 : std_ulogic;
	signal FifoFull256 : std_ulogic;
	
	signal DataToFifo768 : std_ulogic_vector(cFifoByteWidth*8-1 downto 0);
	signal DataFromFifo768 : std_ulogic_vector(cFifoByteWidth*8-1 downto 0);
	signal FifoShift768 : std_ulogic;
	signal FifoWrite768 : std_ulogic;
	signal FifoEmpty768 : std_ulogic;
	signal FifoFull768 : std_ulogic;
	
	constant cSyncWidth	: natural := 1;
	signal iAsync : std_ulogic_vector(cSyncWidth-1 downto 0);
	signal oSync : std_ulogic_vector(cSyncWidth-1 downto 0);
		
begin
	
	AD0_SD0 <= '0';
	
	-- convert reset if necessary
	nRst: if gResetIsLowActive = 1 generate		-- low active
			Reset <= inRstAsync;
		end generate;
		
	Rst: if gResetIsLowActive = 0 generate		-- high active
			Reset <= not(inRstAsync);
		end generate;
		
	Sync: entity work.Sync
		generic map(
			gSyncStages => gSyncStages,
			gDataWidth  => cSyncWidth
		)
		port map(
			iClk       => iClk,
			inRstAsync => inRstAsync,
			iData      => iAsync,
			oData      => oSync
		);
		
	iAsync(0) <= iStreamingModeEn;
	
	FSMD: entity work.FsmdMPU9250(Rtl)
		generic map(
			gClkFrequency  => gClkFrequency,
			gI2cFrequency  => gI2cFrequency,
			gFifoByteWidth => cFifoByteWidth
		)
		port map(
  			iClk                 => iClk,
			inRstAsync           => Reset,
			ioSCL                => ioSCL,
			ioSDA                => ioSDA,
			oFifoData            => DataToFifo,
			oFifoWrite           => FifoWrite,
			iRegFileData		 => RegData,
			iStrobe              => iStrobe,
			iTimeStamp           => iTimeStamp,
			iFifoFull256 	     => FifoFull256,
			iFifoEmpty256 	     => FifoEmpty256,
			iFifoFull768 	     => FifoFull768,
			iFifoEmpty768 	     => FifoEmpty768,
			iStreamingModeActive => oSync(0)
		);
		
	Fifo: entity work.Fifo
		generic map(
			gFifoWidth  => cFifoByteWidth*8,
			gFifoStages => cFifoStages
		)
		port map(
			iClk       => iClk,
			inRstAsync => Reset,
			iFifoData  => DataToFifo,
			oFifoData  => DataFromFifo,
			iFifoShift => FifoShift,
			iFifoWrite => FifoWrite
		);
		
	RegFile: entity work.RegFileMPU
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
			oRegData		  => RegData,
			iFifoData256 	  => DataFromFifo256,
			iFifoEmpty256 	  => FifoEmpty256,
			oFifoShift256	  => FifoShift256,
			iFifoData768 	  => DataFromFifo768,
			iFifoEmpty768 	  => FifoEmpty768,
			oFifoShift768	  => FifoShift768
		);

		
	------------------------------------------------------------------------------------------------------------------------------------------
	-- event mode
	------------------------------------------------------------------------------------------------------------------------------------------
	Fifo256: entity work.Fifo
		generic map(
			gFifoWidth  => cEventModeFifoBytes*8,
			gFifoStages => 256
		)
		port map(
			iClk       => iClk,
			inRstAsync => Reset,
			iFifoData  => DataToFifo256,
			oFifoData  => DataFromFifo256,
			iFifoShift => FifoShift256,
			iFifoWrite => FifoWrite256,
			oFifoEmpty => FifoEmpty256,
			oFifoFull  => FifoFull256
		);
		
	Fifo768: entity work.Fifo
		generic map(
			gFifoWidth  => cEventModeFifoBytes*8,
			gFifoStages => 768
		)
		port map(
			iClk       => iClk,
			inRstAsync => Reset,
			iFifoData  => DataToFifo768,
			oFifoData  => DataFromFifo768,
			iFifoShift => FifoShift768,
			iFifoWrite => FifoWrite768,
			oFifoEmpty => FifoEmpty768,
			oFifoFull  => FifoFull768
		);

end architecture Rtl;














