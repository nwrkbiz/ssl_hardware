-------------------------------------------------------------------------
-- RegFile.vhd
--
-- Author: Elias Geissler
-- Project: SSL1 Master ESD at FH Hagenberg
-------------------------------------------------------------------------
-- Description: this unit is a generic-sized register file

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.pkgGlobal.all;

entity RegFile is
	generic(
		-- register file can save up to gNumOfBytes * 8 bits
		gNumOfBytes			: natural	:= 16;
		
		-- width of fifo in byte
		gFifoByteWidth			: natural	:= 4;
		
	);
	port(
		iClk 		: in std_ulogic;
		inRstAsync 	: in std_ulogic;
		
		-- avalon slave interface
		-- iAvalonAddr addresses wordwise (4 bytes)
		iAvalonAddr			: in  std_ulogic_vector(cAvalonAddrWidth-1 downto 0);
		iAvalonRead			: in  std_ulogic;
		oAvalonReadData		: out std_ulogic_vector(cAvalonDataWidth-1 downto 0);
		iAvalonWrite		: in  std_ulogic;
		iAvalonWriteData	: in  std_ulogic_vector(cAvalonDataWidth-1 downto 0);
		
		-- internal interface
		-- iAddr addresses bytewise
		iAddr				: in  std_ulogic_vector(cAddrWidth-1 downto 0);
		iRead				: in  std_ulogic;
		oReadData			: out std_ulogic_vector(cDataWidth-1 downto 0);
		--oReadDataValid		: out std_ulogic;
		iWrite				: in  std_ulogic;
		iWriteData			: in  std_ulogic_vector(cDataWidth-1 downto 0);
		--oWriteDataDone		: out std_ulogic
		
		-- fifo interconection
		iFifoData			: in std_ulogic_vector(gFifoByteWidth*8-1 downto 0);
		oFifoShift			: in std_ulogic
	);
end entity RegFile;


architecture RTL of RegFile is
		
	signal RegFile : std_ulogic_vector(gNumOfBytes*8-1 downto 0);
	
begin
	
	-- infer a true dual ported ram
	
	Reg: process(iClk, inRstAsync) is
		variable Addr 	: natural;		
		variable AvalonAddr			: natural;
		
	begin
			
		if rising_edge(iClk) then
			
			-- convert addresses to natural
			AvalonAddr 	:= to_integer(unsigned(iAvalonAddr));
			Addr 		:= to_integer(unsigned(iAddr));
			
			-- avalon port
			if iAvalonRead = cActivated then
				oAvalonReadData <= RegFile(AvalonAddr+cAvalonDataWidth-1 downto AvalonAddr);
			end if;
			if iAvalonWrite = cActivated then
				RegFile(AvalonAddr+cAvalonDataWidth-1 downto AvalonAddr) <= iAvalonWriteData;
			end if;
			
			-- internal port	
			if iRead = cActivated then
				oReadData <= RegFile(Addr+cAddrWidth-1 downto Addr);
			end if;
			if iWrite = cActivated then
				RegFile(Addr+cAddrWidth-1 downto Addr) <= iWriteData;
			end if;
		end if;
	end process;
	
end architecture RTL;






