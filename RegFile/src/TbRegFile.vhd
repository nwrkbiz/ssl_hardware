-------------------------------------------------------------------------
-- TbRegFile.vhd
--
-- Author: Elias Geissler
-- Project: SSL1 Master ESD at FH Hagenberg
-------------------------------------------------------------------------
-- Description: testbench for Regfile.vhd

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.pkgGlobal.all;

entity TbRegFile is
end entity TbRegFile;

architecture Bhv of TbRegFile is
	
	constant gNumOfBytes 	: natural := 12;
	constant gFifoByteWidth : natural := 8;
	
	signal iClk 			: std_ulogic := '0';
	signal inRstAsync 		: std_ulogic := not('1');
	signal AvalonAddr		: natural;
	signal iAvalonAddr 		: std_ulogic_vector(cAvalonAddrWidth-1 downto 0);
	signal iAvalonRead 		: std_ulogic;
	signal oAvalonReadData 	: std_ulogic_vector(cAvalonDataWidth-1 downto 0);
	signal iAvalonWrite 	: std_ulogic;
	signal iAvalonWriteData : std_ulogic_vector(cAvalonDataWidth-1 downto 0);
	signal iFifoData 		: std_ulogic_vector(gFifoByteWidth*8-1 downto 0);
	signal oFifoShift 		: std_ulogic;
	
	constant cClkFreq	: natural 	:= 50_000_000;
	constant cClkPeriod	: time		:= 1 sec/cClkFreq; 
	signal RegData : std_ulogic_vector(gNumOfBytes*8-1 downto 0);

	
begin
	
		
	UUT: entity work.RegFile
		generic map(
			gNumOfBytes    => gNumOfBytes,
			gFifoByteWidth => gFifoByteWidth,
			
			-- input default frequency over generic to keep RegFile independent
			gDefaultFrequency => std_ulogic_vector(to_unsigned(400,16)),
			gRegAddrFrequency => 2
		)
		port map(
			iClk              => iClk,
			inRstAsync        => inRstAsync,
			iAvalonAddr       => iAvalonAddr,
			iAvalonRead       => iAvalonRead,
			oAvalonReadData   => oAvalonReadData,
			iAvalonWrite      => iAvalonWrite,
			iAvalonWriteData  => iAvalonWriteData,
			iFifoData         => iFifoData,
			oFifoShift        => oFifoShift,
			oRegData		  => RegData
		);
		
		
	iClk <= not(iClk) after cClkPeriod/2; -- 100MHz
	inRstAsync <= not('0') after 20 ns;
	
	iAvalonAddr <= std_ulogic_vector(to_unsigned(AvalonAddr,cAvalonAddrWidth));
	
	Stimul: process is
		
	begin
		
		-- provide some data over the fifo interface
		iFifoData <= x"0123_4567_89AB_CDEF";
		
		wait for 2* cClkPeriod;
		
		-- read some fifo values
		iAvalonRead <= '1';
		AvalonAddr <= 0;
		wait for 5*cClkPeriod;
		AvalonAddr <= 1;
		wait for 5*cClkPeriod;
		AvalonAddr <= 2;
		wait for 5*cClkPeriod;
		AvalonAddr <= 3;
		wait for 5*cClkPeriod;
		
		-- try to write to fifo region the whole time
		AvalonAddr <= 3;
		iAvalonWrite <= '1';
		iAvalonWriteData <= x"CC";
		wait for 5*cClkPeriod;
		
		-- read all fifo values now
		AvalonAddr <= 0;
		wait for 5*cClkPeriod;
		AvalonAddr <= 1;
		wait for 5*cClkPeriod;
		AvalonAddr <= 2;
		wait for 5*cClkPeriod;
		AvalonAddr <= 3;
		wait for 5*cClkPeriod;
		AvalonAddr <= 4;
		wait for 5*cClkPeriod;
		AvalonAddr <= 5;
		wait for 5*cClkPeriod;
		AvalonAddr <= 6;
		wait for 5*cClkPeriod;
		AvalonAddr <= 7;
		wait for 5*cClkPeriod;
		iAvalonRead <= '0';
		
		-- write to the config register
		AvalonAddr <= 11;
		wait for 5*cClkPeriod;
		
		-- write and read from freq reg
		iAvalonRead <= '0';
		iAvalonWrite <= '1';
		AvalonAddr <= 8;
		iAvalonWriteData <= x"AA";
		wait for 5*cClkPeriod;
		AvalonAddr <= 9;
		iAvalonWriteData <= x"BB";
		wait for 5*cClkPeriod;
		iAvalonWrite <= '0';
		iAvalonRead <= '1';
		AvalonAddr <= 8;
		wait for 2*cClkPeriod;
		AvalonAddr <= 9;
		
		
		
	wait;
	end process;

end architecture Bhv;
