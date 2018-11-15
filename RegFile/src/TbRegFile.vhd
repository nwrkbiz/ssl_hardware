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

entity TbRegFile is
end entity TbRegFile;

architecture Bhv of TbRegFile is
	
	constant cRegFileWidth 		: natural := 32;
	constant cRegFileHeight 	: natural := 10;
	constant cAvalonDataWidth 	: natural := 32;
	constant cAvalonAddrWidth 	: natural := 4;
	constant cAddrWidth 		: natural := 6;
	constant cDataWidth 		: natural := 8;
	
	signal iClk 			: std_ulogic := '0';
	signal inRstAsync 		: std_ulogic := not('1');
	signal iAvalonAddr 		: std_ulogic_vector(cAvalonAddrWidth-1 downto 0);
	signal iAvalonRead 		: std_ulogic;
	signal oAvalonReadData 	: std_ulogic_vector(cAvalonDataWidth-1 downto 0);
	signal iAvalonWrite 	: std_ulogic;
	signal iAvalonWriteData : std_ulogic_vector(cAvalonDataWidth-1 downto 0);
	signal iAddr 			: std_ulogic_vector(cAddrWidth-1 downto 0);
	signal iRead 			: std_ulogic;
	signal oReadData 		: std_ulogic_vector(cDataWidth-1 downto 0);
	signal iWrite 			: std_ulogic;
	signal iWriteData 		: std_ulogic_vector(cDataWidth-1 downto 0);
	
begin
	
	UUT: entity work.RegFile
		generic map(
			gRegFileWidth    => cRegFileWidth,
			gRegFileHeight   => cRegFileHeight,
			gAvalonDataWidth => cAvalonDataWidth,
			gAvalonAddrWidth => cAvalonAddrWidth,
			gAddrWidth       => cAddrWidth,
			gDataWidth       => cDataWidth
		)
		port map(
			iClk             => iClk,
			inRstAsync       => inRstAsync,
			iAvalonAddr      => iAvalonAddr,
			iAvalonRead      => iAvalonRead,
			oAvalonReadData  => oAvalonReadData,
			iAvalonWrite     => iAvalonWrite,
			iAvalonWriteData => iAvalonWriteData,
			iAddr            => iAddr,
			iRead            => iRead,
			oReadData        => oReadData,
			iWrite           => iWrite,
			iWriteData       => iWriteData
		);
		
		
	iClk <= not(iClk) after 5 ns; -- 100MHz
	inRstAsync <= not('0') after 20 ns;
	
	Stimul: process is
		
	begin
		iAvalonAddr <= x"1";
		iAvalonWrite <= '1';
		iAvalonWriteData <= x"ABCD_EFEF";
		
		iAddr <= b"00_0000";
		iWrite <= '1';
		iWriteData <= x"55";
		
		wait for 20 ns;
		
		iAvalonWrite <= '0';
		
		
	wait;
	end process;

end architecture Bhv;
