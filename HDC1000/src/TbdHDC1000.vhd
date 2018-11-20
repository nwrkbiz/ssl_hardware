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
	generic(
		gClkFrequency 	: natural	:= 50_000_000;
		gStrobeTime 	: time		:= 1 ms;
		gI2cFrequency 	: natural	:= 400_000;
		gSyncStages 	: natural	:= 2
	);
	port(
		iClk		: in std_ulogic;
		inRstAsync	: in std_ulogic;
		
		-- i2c interface
		--ioSDA		: inout std_ulogic;
		--ioSCL		: inout std_ulogic;
		
		-- nDataRdy
		--inDataReady	: in std_ulogic;
		
		-- debug LEDs
		LEDR		: out std_ulogic_vector(9 downto 0);
		GPIO_0		: inout std_ulogic_vector(35 downto 0);
		GPIO_1		: inout std_ulogic_vector(35 downto 0)
	);
end entity TbdHDC1000;

architecture RTL of TbdHDC1000 is
	
	constant cClkPeriod 	: time	  	:= 1 sec/gClkFrequency;
	constant cClkDiv		: natural	:= gStrobeTime/cClkPeriod;
	
	signal iAvalonAddr : std_ulogic_vector(cAvalonAddrWidth-1 downto 0);
	signal iAvalonRead : std_ulogic;
	signal oAvalonReadData : std_ulogic_vector(cAvalonDataWidth-1 downto 0);
	signal iAvalonWrite : std_ulogic;
	signal iAvalonWriteData : std_ulogic_vector(cAvalonDataWidth-1 downto 0);
	signal nDataReady : std_ulogic;
	signal SCL : std_logic;
	signal SDA : std_logic;
	signal Strobe : std_ulogic;
	signal TimeStamp : std_ulogic_vector(cTimeStampWidth-1 downto 0);
	
begin
	

	-- oszi
	GPIO_0(0) <= GPIO_1(3);
	GPIO_0(1) <= GPIO_1(4);
	
	-- gpio interconnect
	GPIO_1(3) <= SCL;
	GPIO_1(5) <= SDA;
	nDataReady <= GPIO_1(4);
	
	-- avalon inactive
	iAvalonAddr 	 <= (others => '0');
	iAvalonRead 	 <= '0';
	iAvalonWrite 	 <= '0';
	iAvalonWriteData <= (others => '0');
	
	HDC1000: entity work.HDC1000
		generic map(
			gClkFrequency => gClkFrequency,
			gI2cFrequency => gI2cFrequency,
			gSyncStages   => gSyncStages
		)
		port map(
			iClk             => iClk,
			inRstAsync       => inRstAsync,
			ioSCL            => SCL,
			ioSDA            => SDA,
			inDataReady      => nDataReady,
			iStrobe 		 => Strobe,
			iTimeStamp 		 => TimeStamp,
			iAvalonAddr      => iAvalonAddr,
			iAvalonRead      => iAvalonRead,
			oAvalonReadData  => oAvalonReadData,
			iAvalonWrite     => iAvalonWrite,
			iAvalonWriteData => iAvalonWriteData,
			oLEDs            => LEDR
		);
		
			
	StrobeTimeStamp: entity work.StrobeGenAndTimeStamp
		generic map(
			gClkFreq        => gClkFrequency,
			gClkDiv         => cClkDiv,
			gTimeStampWidth => cTimeStampWidth
		)
		port map(
			iClk       => iClk,
			inRstAsync => inRstAsync,
			oStrobe    => Strobe,
			oTimeStamp => TimeStamp
		);

end architecture RTL;
