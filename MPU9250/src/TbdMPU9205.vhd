-------------------------------------------------------------------------
-- TbdMPU9250.vhd
--
-- Author: Elias Geissler
-- Project: SSL1 Master ESD at FH Hagenberg
-------------------------------------------------------------------------
-- Description: testbed for MPU9250.vhd

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.pkgGlobal.all;

entity TbdMPU9250 is
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
		
		-- gpio_1 connects fpga and rfs card
		GPIO_1		: inout std_ulogic_vector(35 downto 0);
		
		LEDR		: out	std_ulogic_vector(9 downto 0);
		SW			: in	std_ulogic_vector(9 downto 0)
	);
end entity TbdMPU9250;

architecture RTL of TbdMPU9250 is
	
	signal iAvalonAddr : std_ulogic_vector(cAvalonAddrWidth-1 downto 0);
	signal iAvalonRead : std_ulogic;
	signal oAvalonReadData : std_ulogic_vector(cAvalonDataWidth-1 downto 0);
	signal iAvalonWrite : std_ulogic;
	signal iAvalonWriteData : std_ulogic_vector(cAvalonDataWidth-1 downto 0);
	signal Strobe : std_ulogic;
	signal TimeStamp : std_ulogic_vector(cTimeStampWidth-1 downto 0);
	signal LEDs : std_ulogic_vector(9 downto 0);
	signal StreamingModeEn : std_ulogic;
	
begin
		
	-- avalon inactive
	iAvalonAddr 	 <= (others => '0');
	iAvalonRead 	 <= '0';
	iAvalonWrite 	 <= '0';
	iAvalonWriteData <= (others => '0');
	
	-- set MPU_AD0_SD0
	GPIO_1(27) <= '0';
	
	MPU9250: entity work.MPU9250
		generic map(
			gClkFrequency => gClkFrequency,
			gI2cFrequency => gI2cFrequency,
			gSyncStages   => gSyncStages,
			gResetIsLowActive => 1
		)
		port map(
			iClk             => iClk,
			inRstAsync       => inRstAsync,
			ioSCL            => GPIO_1(11),
			ioSDA            => GPIO_1(13),
			iStrobe 		 => Strobe,
			iTimeStamp 		 => TimeStamp,
			iAvalonAddr      => iAvalonAddr,
			iAvalonRead      => iAvalonRead,
			oAvalonReadData  => oAvalonReadData,
			iAvalonWrite     => iAvalonWrite,
			iAvalonWriteData => iAvalonWriteData,
			
			iStreamingModeEn => StreamingModeEn,
			
			oLEDs			 => LEDs
		);
		
		
	LEDR <= LEDs;
		
			
	StrobeTimeStamp: entity work.StrobeGenAndTimeStamp
		generic map(
			gClkFreq        => gClkFrequency,
			gStrobe         => gStrobeTime,
			gTimeStampWidth => cTimeStampWidth,
			gResetIsLowActive => 1
		)
		port map(
			iClk       => iClk,
			inRstAsync => inRstAsync,
			oStrobe    => Strobe,
			oTimeStamp => TimeStamp
		);
		
		
	Sync: entity work.Sync
		generic map(
			gSyncStages => 2,
			gDataWidth  => 1
		)
		port map(
			iClk       => iClk,
			inRstAsync => inRstAsync,
			iData(0)   => SW(0),
			oData(0)   => StreamingModeEn
		);

end architecture RTL;
