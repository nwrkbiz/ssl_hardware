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
		gFifoByteWidth		: natural	:= 8;
		
		-- default reading frequency
		gDefaultFrequency	: std_ulogic_vector(15 downto 0);
		gRegAddrFrequency	: natural
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
		
		-- output registers for internal usage
		oRegData			: out std_ulogic_vector(gNumOfBytes*8-1 downto 0);
		
		-- fifo interconection
		iFifoData			: in  std_ulogic_vector(gFifoByteWidth*8-1 downto 0);
		oFifoShift			: out std_ulogic
	);
end entity RegFile;


architecture RTL of RegFile is
	
	type tRegFile is array (0 to gNumOfBytes-1) of std_ulogic_vector(7 downto 0);
	
	-- function to init regfile
	function Init_RegFile (
    -- default reading frequency
	DefaultFrequency	: in std_ulogic_vector(15 downto 0);
	RegAddrFrequency	: in natural)
    return tRegFile is
		variable Reg : tRegFile;
  	begin
  		Reg := (others => (others => '0'));
  		Reg(RegAddrFrequency) 	:= DefaultFrequency(7  downto 0);
  		Reg(RegAddrFrequency+1) := DefaultFrequency(15 downto 8);
  		
  		return Reg;
  	end;
	
	
	signal RegFile : tRegFile := Init_RegFile(gDefaultFrequency, gRegAddrFrequency);
	
	-- tracks if every byte fo the fifo was read 
	-- if it matches (others => '1') fifo will be shifted
	signal FifoRead : std_ulogic_vector(gFifoByteWidth-1 downto 0) := (others => '0');
	signal FifoShift : std_logic;
	
begin
		
	Reg: process(iClk, inRstAsync) is	
		variable AvalonAddr		: natural;
		
	begin
		
		if inRstAsync = cnActivated then
			-- RAM must not have a reset
			FifoRead 		<= (others => '0');
			FifoShift 		<= '0';
			
			RegFile			<= Init_RegFile(gDefaultFrequency, gRegAddrFrequency);
			
		elsif rising_edge(iClk) then
			
			-- convert addresses to natural
			AvalonAddr 	:= to_integer(unsigned(iAvalonAddr));
			
			-- avalon port
			oAvalonReadData <= (others => '0');
			if iAvalonRead = cActivated then
				oAvalonReadData <= RegFile(AvalonAddr);
			end if;
			
			-- write onto the fifo registers are not possible
			if iAvalonWrite = cActivated then 
				if AvalonAddr >= gFifoByteWidth then
					RegFile(AvalonAddr) <= iAvalonWriteData;
				end if;
			end if;
			
			-- get fifo data into regfile
			for i in 0 to gFifoByteWidth-1 loop
				RegFile(i) <= iFifoData(7+8*i downto 0+8*i);
			end loop;
			
			
			-- fifo shift logic
			if AvalonAddr < gFifoByteWidth then
				if iAvalonRead = cActivated then
					FifoRead(AvalonAddr) <= '1';
				end if;
			end if;
			
			FifoShift <= '0';
			if FifoRead = (gFifoByteWidth-1 downto 0 => '1') then
				FifoShift <= '1';
				FifoRead <= (others => '0');
			end if;
			
		end if;
	end process;
	
	
	-- output connections
	oFifoShift			<= FifoShift;
	
	OutputRegData: for i in 0 to gNumOfBytes-1 generate
		oRegData(7+8*i downto 0+8*i) <= RegFile(i);
	end generate OutputRegData;
			
	
end architecture RTL;






