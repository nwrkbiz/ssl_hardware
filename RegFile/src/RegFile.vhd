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
use work.pkgHDC1000.all;

entity RegFile is
	generic(
		-- register file can save up to gNumOfBytes * 8 bits
		gNumOfBytes			: natural	:= 16;
		
		-- width of fifo in byte
		gFifoByteWidth			: natural	:= 8
		
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
		
		-- data to FSM
		oRegDataFrequency	: out std_ulogic_vector(15 downto 0);
		oRegDataConfig		: out std_ulogic_vector(15 downto 0);
		-- this signal start a i2c write to config register of the HDC1000
		oWriteConfigReg		: out std_ulogic;
		
		-- fifo interconection
		iFifoData			: in  std_ulogic_vector(gFifoByteWidth*8-1 downto 0);
		oFifoShift			: out std_ulogic
	);
end entity RegFile;


architecture RTL of RegFile is
	
	type tRegFile is array (0 to gNumOfBytes-1) of std_ulogic_vector(cAvalonDataWidth-1 downto 0);
	signal RegFile : tRegFile;
	
	-- tracks if every byte fo the fifo was read 
	-- if it matches (others => '1') fifo will be shifted
	signal FifoRead : std_ulogic_vector(gFifoByteWidth-1 downto 0) := (others => '0');
	signal FifoShift : std_logic;
	signal WriteConfigReg : std_ulogic;
	
begin
	
	-- infer a true dual ported ram
	
	Reg: process(iClk, inRstAsync) is
		variable Addr 			: natural;		
		variable AvalonAddr		: natural;
		
	begin
		
		if inRstAsync = cnActivated then
			-- RAM must not have a reset
			FifoRead 		<= (others => '0');
			FifoShift 		<= '0';
			WriteConfigReg 	<= '0';
			
		elsif rising_edge(iClk) then
			
			-- convert addresses to natural
			AvalonAddr 	:= to_integer(unsigned(iAvalonAddr));
			
			-- avalon port
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
			RegFile(cRegAddrTemp_L) 		<= iFifoData(tFifoRangeTemp_L);
			RegFile(cRegAddrTemp_H) 		<= iFifoData(tFifoRangeTemp_H);
			RegFile(cRegAddrHumidity_L) 	<= iFifoData(tFifoRangeHumidity_L);
			RegFile(cRegAddrHumidity_H) 	<= iFifoData(tFifoRangeHumidity_H);
			RegFile(cRegAddrTimeStamp_0) 	<= iFifoData(tFifoRangeTimeStamp_0);
			RegFile(cRegAddrTimeStamp_1) 	<= iFifoData(tFifoRangeTimeStamp_1);
			RegFile(cRegAddrTimeStamp_2) 	<= iFifoData(tFifoRangeTimeStamp_2);
			RegFile(cRegAddrTimeStamp_3) 	<= iFifoData(tFifoRangeTimeStamp_3);
			
			
			-- fifo shift logic
			if Addr < gFifoByteWidth then
				if iAvalonRead = cActivated then
					FifoRead(Addr) <= '1';
				end if;
			end if;
			
			FifoShift <= '0';
			if FifoRead(gFifoByteWidth-1 downto 0) = (others => '1') then
				FifoShift <= '1';
				FifoRead <= (others => '0');
			end if;
			
			-- detect a write into the config register
			WriteConfigReg <= '0';
			if AvalonAddr = cRegAddrConfig_H then
				WriteConfigReg <= iAvalonWrite;
			end if;
			
		end if;
	end process;
	
	
	-- output connections
	oRegDataFrequency 	<= RegFile(cRegAddrFrequenzy_H) & RegFile(cRegAddrFrequenzy_L);
	oRegDataConfig		<= RegFile(cRegAddrConfig_H) & RegFile(cRegAddrConfig_L);
	oFifoShift			<= FifoShift;
	oWriteConfigReg		<= WriteConfigReg;
	
end architecture RTL;






