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

entity TbdHDC1000 is
	port(
		iClk		: in std_ulogic;
		inRstAsync	: in std_ulogic;
		
		-- i2c interface
		ioSDA		: inout std_ulogic;
		ioSCL		: inout std_ulogic;
		
		-- nDataRdy
		inDataReady	: in std_ulogic;
		
		-- debug LEDs
		LEDR		: out std_ulogic_vector(9 downto 0)
	);
end entity TbdHDC1000;

architecture RTL of TbdHDC1000 is
	
	constant cClkFrequency 	: natural	:= 50_000_000;
	constant cStrobeTime 	: time		:= 1 ms;
	constant cI2cFrequency 	: natural	:= 400_000;
	constant cSyncStages 	: natural	:= 2;
	
	signal iAvalonAddr : std_ulogic_vector(cAvalonAddrWidth-1 downto 0);
	signal iAvalonRead : std_ulogic;
	signal oAvalonReadData : std_ulogic_vector(cAvalonDataWidth-1 downto 0);
	signal iAvalonWrite : std_ulogic;
	signal iAvalonWriteData : std_ulogic_vector(cAvalonDataWidth-1 downto 0);
	
begin
	
	-- avalon inactive
	iAvalonAddr 	 <= (others => '0');
	iAvalonRead 	 <= '0';
	iAvalonWrite 	 <= '0';
	iAvalonWriteData <= (others => '0');
	
	HDC1000: entity work.HDC1000
		generic map(
			gClkFrequency => cClkFrequency,
			gStrobeTime   => cStrobeTime,
			gI2cFrequency => cI2cFrequency,
			gSyncStages   => cSyncStages
		)
		port map(
			iClk             => iClk,
			inRstAsync       => inRstAsync,
			ioSCL            => ioSCL,
			ioSDA            => ioSDA,
			inDataReady      => inDataReady,
			iAvalonAddr      => iAvalonAddr,
			iAvalonRead      => iAvalonRead,
			oAvalonReadData  => oAvalonReadData,
			iAvalonWrite     => iAvalonWrite,
			iAvalonWriteData => iAvalonWriteData,
			oLEDs            => LEDR
		);

end architecture RTL;
