-------------------------------------------------------------------------
-- StrobeGenAndTimeStamp.vhd
--
-- Author: Elias Geissler
-- Project: SSL1 Master ESD at FH Hagenberg
-------------------------------------------------------------------------
-- Description: this unit provides a strobe that appears every 1ms and additionally a counter that counts the appearances of this strobe

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.pkgGlobal.all;

entity StrobeGenAndTimeStamp is
	generic(
		gClkFreq 		: natural := 50_000_000;
		
		-- divide clk with this value to create strobe
		gClkDiv			: natural := 1000;
			
		-- assuming strobe is active every 1ms, a 24-bit vector can measure about 5 hours, 32 -> ~1000years
		gTimeStampWidth : natural := 32
	);
	port(
		iClk		: in std_ulogic;
		inRstAsync	: in std_ulogic;
		
		oStrobe		: out std_ulogic;
		oTimeStamp	: out std_ulogic_vector(gTimeStampWidth-1 downto 0)		
	);
end entity;

architecture Rtl of StrobeGenAndTimeStamp is
	
	constant cStrobeCountMax 	: natural := gClkFreq/gClkDiv-1;
	constant cTimeStampMax		: unsigned(gTimeStampWidth-1 downto 0) := (others => '1');

	signal StrobeCount 	: natural range 0 to cStrobeCountMax;
	signal Strobe		: std_ulogic;
	signal TimeStamp	: unsigned(gTimeStampWidth-1 downto 0);

begin
	
	Reg: process (iClk, inRstAsync) is
	begin
		if inRstAsync = cnActivated then
			StrobeCount <= 0;
			Strobe <= '0';
			TimeStamp <= (others => '0');
		elsif rising_edge(iClk) then
			
			-- strobe gen logic
			if StrobeCount = cStrobeCountMax then
				StrobeCount <= 0;
				Strobe		<= cActivated;
			else
				StrobeCount <= StrobeCount + 1;
				Strobe 		<= cInactivated;
			end if;
			
			-- time stamp logic
			if Strobe = cActivated then
				if TimeStamp = cTimeStampMax then
					TimeStamp <= (others => '0');
				else
					TimeStamp <= TimeStamp + 1;
				end if;
			end if;
		end if;
	end process;
	
	
	-- connecting to output
	oStrobe	 	<= Strobe;
	oTimeStamp	<= std_ulogic_vector(TimeStamp);
				
end architecture;