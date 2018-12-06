-------------------------------------------------------------------------
-- MPU9250.vhd
--
-- Author: Elias Geissler
-- Project: SSL1 Master ESD at FH Hagenberg
-------------------------------------------------------------------------
-- Description: this unit reads data over i2c from APDS9301 and provides them over avalonMM
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.pkgGlobal.all; 
use work.pkgAPDS9301.all;

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
		
		-- strobe and timestamp
		iStrobe		: in std_ulogic;
		iTimeStamp	: in std_ulogic_vector(cTimeStampWidth-1 downto 0);
		
		-- avalon MM interface
		iAvalonAddr 		: in  std_ulogic_vector(cAvalonAddrWidth-1 downto 0);
		iAvalonRead 		: in  std_ulogic;
		oAvalonReadData 	: out std_ulogic_vector(cAvalonDataWidth-1 downto 0);
		iAvalonWrite 		: in  std_ulogic;
		iAvalonWriteData 	: in  std_ulogic_vector(cAvalonDataWidth-1 downto 0);
		
		-- debug
		HEX0		: out std_ulogic_vector(6 downto 0);
		HEX1		: out std_ulogic_vector(6 downto 0);
		HEX2		: out std_ulogic_vector(6 downto 0);
		HEX3		: out std_ulogic_vector(6 downto 0)
	);
end entity MPU9250;

architecture Rtl of MPU9250 is

	signal FifoWrite 			: std_ulogic;
	signal RegDataFrequency 	: std_ulogic_vector(15 downto 0);
	signal RegDataConfig 		: std_ulogic_vector(7 downto 0);
	signal WriteConfigReg 		: std_ulogic;
	signal DataToFifo 			: std_ulogic_vector(cFifoByteWidth*8-1 downto 0) := (others => '1');
	signal DataFromFifo 		: std_ulogic_vector(cFifoByteWidth*8-1 downto 0);
	signal FifoShift 			: std_ulogic;
	
	signal Reset		: std_ulogic;
	
	function ToSevSeg(cValue : std_ulogic_vector(3 downto 0))
      return std_ulogic_vector is
    begin
      
      case cValue(3 downto 0) is
        when "0000" => return "0111111";
        when "0001" => return "0000110";
        when "0010" => return "1011011";
        when "0011" => return "1001111";
        when "0100" => return "1100110";
        when "0101" => return "1101101";
        when "0110" => return "1111101";
        when "0111" => return "0000111";
        when "1000" => return "1111111";
        when "1001" => return "1101111";
        when "1010" => return "1110111";
        when "1011" => return "1111100";
        when "1100" => return "0111001";
        when "1101" => return "1011110";
        when "1110" => return "1111001";
        when "1111" => return "1110001";
        when others => return "XXXXXXX";
      end case;
    end ToSevSeg;
		
begin
	
	-- convert reset if necessary
	nRst: if gResetIsLowActive = 1 generate		-- low active
			Reset <= inRstAsync;
		end generate;
		
	Rst: if gResetIsLowActive = 0 generate		-- high active
			Reset <= not(inRstAsync);
		end generate;
	
	FSMD: entity work.FsmdAPDS9301(Rtl)
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
			iTimeStamp        => iTimeStamp
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
		
	RegFile: entity work.RegFileAPDS9301
		generic map(
			gNumOfBytes    => cRegFileNumberOfBytes,
			gFifoByteWidth => cFifoByteWidth
		)
		port map(
			iClk              => iClk,
			inRstAsync        => Reset,
			iAvalonAddr       => iAvalonAddr,
			iAvalonRead       => iAvalonRead,
			oAvalonReadData   => oAvalonReadData,
			iAvalonWrite      => iAvalonWrite,
			iAvalonWriteData  => iAvalonWriteData,
			oRegDataFrequency => RegDataFrequency,
			oRegDataConfig    => RegDataConfig,
			oWriteConfigReg   => WriteConfigReg,
			iFifoData         => DataFromFifo,
			oFifoShift        => FifoShift
		);
		
		
		
	-- debug
	HEX0 <= not(ToSevSeg(DataToFifo(3 downto 0)));
	HEX1 <= not(ToSevSeg(DataToFifo(7 downto 4)));
	HEX2 <= not(ToSevSeg(DataToFifo(11 downto 8)));
	HEX3 <= not(ToSevSeg(DataToFifo(15 downto 12)));

end architecture Rtl;














