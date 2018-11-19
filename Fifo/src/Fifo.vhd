-------------------------------------------------------------------------
-- Fifo.vhd
--
-- Author: Elias Geissler
-- Project: SSL1 Master ESD at FH Hagenberg
-------------------------------------------------------------------------
-- Description: simple generic fifo

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.pkgGlobal.all;

entity Fifo is
	generic (
		gFifoWidth	: natural	:= 8;
		gFifoStages	: natural	:= 8
	);
	port(
		iClk 		: in std_ulogic;
		inRstAsync 	: in std_ulogic;
		
		iFifoData	: in  std_ulogic_vector(gFifoWidth-1 downto 0);
		oFifoData	: out std_ulogic_vector(gFifoWidth-1 downto 0);
		iFifoShift	: in  std_ulogic;
		iFifoWrite	: in  std_ulogic
	);
end entity Fifo;

architecture RTL of Fifo is
	
	type tFifo is array (0 to gFifoStages-1) of std_ulogic_vector(gFifoWidth-1 downto 0);
	signal Fifo : tFifo := (others => (others => '0'));
	
	signal Read		: natural range 0 to gFifoStages-1;
	signal Write	: natural range 0 to gFifoStages-1;
	
begin
	
	Reg: process (iClk, inRstAsync) is		
	begin
		
		if inRstAsync = cnActivated then
			Read 	<= 0;
			Write 	<= 0;
			
		elsif rising_edge(iClk) then
			
			-- read
			oFifoData <= Fifo(Read);
			
			-- write access
			if iFifoWrite = cActivated then
				-- discard new data if fifo is full
				if  (Write+1 = Read) or							-- write stand one before read
					(Write = gFifoStages-1 and Read = 0) then	-- write stand one before read but over the edge of the ringbuffer
				else
					
					Fifo(Write) <= iFifoData;
					
					-- change write address
					if Write + 1 < gFifoStages then
						Write <= Write + 1;
					else
						Write <= Write + 1 - gFifoStages;
					end if;
				end if;
			end if;
			
			if iFifoShift = cActivated then
				
				-- Read = Write means empty fifo
				if Read /= Write then
					-- change read address
					if Read + 1 < gFifoStages then
						Read <= Read + 1;
					else
						Read <= Read + 1 - gFifoStages;
					end if;
				end if;
			end if;
			
		end if;
		
	end process;

end architecture RTL;
