-------------------------------------------------------------------------
-- TbdAPDS9301.vhd
--
-- Author: Elias Geissler
-- Project: SSL1 Master ESD at FH Hagenberg
-------------------------------------------------------------------------
-- Description: testbed for APDS9301.vhd

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.pkgGlobal.all;

entity TbdAPDS9301 is
	generic(
		gClkFrequency 	: natural	:= 50_000_000;
		gStrobeTime 	: time		:= 1 ms;
		gI2cFrequency 	: natural	:= 400_000;
		gSyncStages 	: natural	:= 2
	);
	port(
		iClk		: in std_ulogic;
		inRstAsync	: in std_ulogic;
		
		-- gpio_1 connects fpga and rfs card
		GPIO_1		: inout std_ulogic_vector(35 downto 0);
		
		--debug
		HEX0		: out std_ulogic_vector(6 downto 0);
		HEX1		: out std_ulogic_vector(6 downto 0);
		HEX2		: out std_ulogic_vector(6 downto 0);
		HEX3		: out std_ulogic_vector(6 downto 0);
		HEX4		: out std_ulogic_vector(6 downto 0);
		HEX5		: out std_ulogic_vector(6 downto 0)
	);
end entity TbdAPDS9301;

architecture RTL of TbdAPDS9301 is
	
	signal iAvalonAddr : std_ulogic_vector(cAvalonAddrWidth-1 downto 0);
	signal iAvalonRead : std_ulogic;
	signal oAvalonReadData : std_ulogic_vector(cAvalonDataWidth-1 downto 0);
	signal iAvalonWrite : std_ulogic;
	signal iAvalonWriteData : std_ulogic_vector(cAvalonDataWidth-1 downto 0);
	signal Strobe : std_ulogic;
	signal TimeStamp : std_ulogic_vector(cTimeStampWidth-1 downto 0);
	
begin
		
	-- avalon inactive
	iAvalonAddr 	 <= (others => '0');
	iAvalonRead 	 <= '0';
	iAvalonWrite 	 <= '0';
	iAvalonWriteData <= (others => '0');
	
	APDS9301: entity work.APDS9301
		generic map(
			gClkFrequency => gClkFrequency,
			gI2cFrequency => gI2cFrequency,
			gSyncStages   => gSyncStages
		)
		port map(
			iClk             => iClk,
			inRstAsync       => inRstAsync,
			ioSCL            => GPIO_1(7),
			ioSDA            => GPIO_1(9),
			iStrobe 		 => Strobe,
			iTimeStamp 		 => TimeStamp,
			iAvalonAddr      => iAvalonAddr,
			iAvalonRead      => iAvalonRead,
			oAvalonReadData  => oAvalonReadData,
			iAvalonWrite     => iAvalonWrite,
			iAvalonWriteData => iAvalonWriteData
		);
		
		HEX4 <= (others => '1');
		HEX5 <= (others => '1');
		
			
	StrobeTimeStamp: entity work.StrobeGenAndTimeStamp
		generic map(
			gClkFreq        => gClkFrequency,
			gStrobe         => gStrobeTime,
			gTimeStampWidth => cTimeStampWidth
		)
		port map(
			iClk       => iClk,
			inRstAsync => inRstAsync,
			oStrobe    => Strobe,
			oTimeStamp => TimeStamp
		);

end architecture RTL;
