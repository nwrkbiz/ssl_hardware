-------------------------------------------------------------------------
-- TbHDC1000.vhd
--
-- Author: Elias Geissler
-- Project: SSL1 Master ESD at FH Hagenberg
-------------------------------------------------------------------------
-- Description: testbed for HDC1000.vhd

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.pkgGlobal.all;
use work.pkgHDC1000.all;

entity TbdHDC1000 is
	generic(
		gClkFrequency 	: natural	:= 50_000_000;
		gStrobeTime 	: time		:= 1 ms;
		gI2cFrequency 	: natural	:= 200_000;
		gSyncStages 	: natural	:= 2
	);
	port(
		iClk		: in std_ulogic;
		inRstAsync	: in std_ulogic;
		
		GPIO_1		: inout std_ulogic_vector(35 downto 0);
		GPIO_0		: inout std_ulogic_vector(35 downto 0)
	);
end entity TbdHDC1000;

architecture RTL of TbdHDC1000 is
	
	signal iAvalonAddr : std_ulogic_vector(cAvalonAddrWidth-1 downto 0);
	signal iAvalonRead : std_ulogic;
	signal oAvalonReadData : std_ulogic_vector(cAvalonDataWidth-1 downto 0);
	signal iAvalonWrite : std_ulogic;
	signal iAvalonWriteData : std_ulogic_vector(cAvalonDataWidth-1 downto 0);
	signal nDataReady : std_ulogic;
	signal Strobe : std_ulogic;
	signal TimeStamp : std_ulogic_vector(cTimeStampWidth-1 downto 0);
	signal GPIO : std_ulogic_vector(5 downto 0);
	
begin
	
	HDC1000: entity work.HDC1000
		generic map(
			gClkFrequency => gClkFrequency,
			gI2cFrequency => gI2cFrequency,
			gSyncStages   => gSyncStages
		)
		port map(
			iClk             => iClk,
			inRstAsync       => inRstAsync,
			ioSCL            => GPIO_1(3),
			ioSDA            => GPIO_1(5),
			iStrobe 		 => Strobe,
			iTimeStamp 		 => TimeStamp,
			iAvalonAddr      => iAvalonAddr,
			iAvalonRead      => iAvalonRead,
			oAvalonReadData  => oAvalonReadData,
			iAvalonWrite     => iAvalonWrite,
			iAvalonWriteData => iAvalonWriteData
		);
		
			
	StrobeTimeStamp: entity work.StrobeGenAndTimeStamp
		generic map(
			gClkFreq        => gClkFrequency,
			gStrobe         => 1 ms,
			gTimeStampWidth => cTimeStampWidth
		)
		port map(
			iClk       => iClk,
			inRstAsync => inRstAsync,
			oStrobe    => Strobe,
			oTimeStamp => TimeStamp
		);
		
		
	AvalonMaster: entity work.AvalonMaster
		generic map(
			gClkFrequency         => gClkFrequency,
			gAddrChangeFreq       => 600,	-- 12*50  => 50=temp read freq; 12=avalon addresses to read
			gNumOfAvalonAddresses => cRegFileNumberOfBytes,
			gAvalonAddrWidth      => cAvalonAddrWidth,
			gAvalonDataWidth      => cAvalonDataWidth
		)
		port map(
			iClk             => iClk,
			inRstAsync       => inRstAsync,
			oAvalonAddr      => iAvalonAddr,
			oAvalonWriteData => iAvalonWriteData,
			iAvalonReadData  => oAvalonReadData,
			oAvalonRead      => iAvalonRead,
			oAvalonWrite     => iAvalonWrite
		);
		
		
	GPIO_0(4 downto 0) 	<= iAvalonAddr(4 downto 0);
	GPIO_0(5) 			<= iAvalonRead;
	GPIO_0(13 downto 6) <= oAvalonReadData;

end architecture RTL;
