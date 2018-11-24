-------------------------------------------------------------------------
-- TbStrobeGenAndTimeStamp.vhd
--
-- Author: Elias Geissler
-- Project: SSL1 Master ESD at FH Hagenberg
-------------------------------------------------------------------------
-- Description: testbench for StrobeGenAndTimeStamp.vhd

entity TbStrobeGenAndTimeStamp is
end entity;

library ieee;
use ieee.std_logic_1164.all;
use work.pkgGlobal.all;

architecture Bhv of TbStrobeGenAndTimeStamp is
	
	constant cClkFreq 	: natural := 50_000_000;
	constant cClkDiv	: natural := 5_000_000; -- create 10us strobe
	constant cClkPeriod	: time	  := 1 sec/cClkFreq;
	
	constant cTimeStampWidth : natural := 4;
	
	signal iClk : std_ulogic 		:= cInactivated;
	signal inRstAsync : std_ulogic 	:= cnActivated;
	signal oStrobe : std_ulogic;
	signal oTimeStamp : std_ulogic_vector(cTimeStampWidth-1 downto 0);
	
begin
	
	UUT: entity work.StrobeGenAndTimeStamp
		generic map(
			gClkFreq        => cClkFreq,
			gClkDiv			=> cClkDiv,
			gTimeStampWidth => cTimeStampWidth
		)
		port map(
			iClk       => iClk,
			inRstAsync => inRstAsync,
			oStrobe    => oStrobe,
			oTimeStamp => oTimeStamp
		);
		
	iClk <= not(iClk) after cClkPeriod/2;
	inRstAsync <= cnInactivated after 50 us;
	
end architecture;