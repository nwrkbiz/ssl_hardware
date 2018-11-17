-------------------------------------------------------------------------
-- TbFifo.vhd
--
-- Author: Elias Geissler
-- Project: SSL1 Master ESD at FH Hagenberg
-------------------------------------------------------------------------
-- Description: testbench for fifo

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.pkgGlobal.all;

entity TbFifo is
end entity TbFifo;

architecture RTL of TbFifo is
	constant gFifoWidth	 : natural	:= 4;
	constant gFifoStages : natural 	:= 4;
	
	signal iClk 		: std_ulogic	:= '0';
	signal inRstAsync 	: std_ulogic	:= not('1');
	signal iFifoData 	: std_ulogic_vector(gFifoWidth-1 downto 0);
	signal oFifoData 	: std_ulogic_vector(gFifoWidth-1 downto 0);
	signal iFifoShift 	: std_ulogic;
	signal iFifoWrite 	: std_ulogic;
	
	constant cClkFreq	: natural 	:= 50_000_000;
	constant cClkPeriod	: time		:= 1 sec/cClkFreq; 
	
begin
	
	UUT: entity work.Fifo
		generic map(
			gFifoWidth  => gFifoWidth,
			gFifoStages => gFifoStages
		)
		port map(
			iClk       => iClk,
			inRstAsync => inRstAsync,
			iFifoData  => iFifoData,
			oFifoData  => oFifoData,
			iFifoShift => iFifoShift,
			iFifoWrite => iFifoWrite
		);
		
	iClk <= not(iClk) after cClkPeriod/2; -- 100MHz
	inRstAsync <= not('0') after 20 ns;
	
	Stimul: process is
	begin
		
		wait until inRstAsync = not('0');
		
		-- provide some data 
		iFifoData <= x"F";
		iFifoWrite <= cActivated;
		wait for 2*cClkPeriod;
		
		-- first shift
		iFifoWrite <= cInactivated;
		iFifoShift <= cActivated;
		wait for cClkPeriod;
		iFifoShift <= cInactivated;
		
		-- fill fifo
		iFifoData <= x"0";
		iFifoWrite <= cActivated;
		wait for cClkPeriod;
		iFifoData <= x"1";
		iFifoWrite <= cActivated;
		wait for cClkPeriod;
		iFifoData <= x"2";
		iFifoWrite <= cActivated;
		wait for cClkPeriod;
		iFifoData <= x"3";
		iFifoWrite <= cActivated;
		wait for cClkPeriod;
		iFifoData <= x"4"; -- this data should be discarded
		iFifoWrite <= cActivated;
		wait for cClkPeriod;
		iFifoWrite <= cInactivated;
		
		-- read out whole fifo
		iFifoShift <= cActivated;
		
		
		wait;
	end process;

end architecture RTL;
