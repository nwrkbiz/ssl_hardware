-------------------------------------------------------------------------
-- Sync.vhd
--
-- Author: Elias Geissler
-- Project: SSL1 Master ESD at FH Hagenberg
-------------------------------------------------------------------------
-- Description: simple generic sync unit 

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Sync is
	generic(
		-- minimum is 2
		gSyncStages	: natural  	:= 2;
		gDataWidth	: natural	:= 1	
	);
	port(
		iClk 		: in std_ulogic;
		inRstAsync 	: in std_ulogic;
		
		iData		: in  std_ulogic_vector(gDataWidth-1 downto 0);
		oData		: out std_ulogic_vector(gDataWidth-1 downto 0);
		onData		: out std_ulogic_vector(gDataWidth-1 downto 0)
	);
end entity Sync;

architecture RTL of Sync is
	
	type tSyncPipe is array (0 to gSyncStages-1) of std_ulogic_vector(gDataWidth-1 downto 0);
	signal SyncPipe	: tSyncPipe;
	
begin
	
	Sync: process (iClk, inRstAsync) is
	begin
		if inRstAsync = not('1') then
			SyncPipe <= (others => (others => '0'));
			
		elsif rising_edge(iClk) then
			SyncPipe(0) <= iData;
			SyncPipe(1 to gSyncStages-1) <= SyncPipe(0 to gSyncStages-1-1);
		end if;
	end process;
	
	oData  <= SyncPipe(gSyncStages-1);
	onData <= not(SyncPipe(gSyncStages-1));

end architecture RTL;
