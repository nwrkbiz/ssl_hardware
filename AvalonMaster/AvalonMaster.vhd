library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity AvalonMaster is
	generic (
		gClkFrequency	: natural	:= 50_000_000;
		gAddrChangeFreq	: natural	:= 100;
		
		gNumOfAvalonAddresses	: natural	:= 1;
		
		gAvalonAddrWidth	: natural := 2;
		gAvalonDataWidth	: natural := 8
	);
	port(
		iClk		: in std_ulogic;
		inRstAsync	: in std_ulogic;
		
		oAvalonAddr			: out std_ulogic_vector(gAvalonAddrWidth-1 downto 0);
		oAvalonWriteData	: out std_ulogic_vector(gAvalonDataWidth-1 downto 0);
		iAvalonReadData		: in  std_ulogic_vector(gAvalonDataWidth-1 downto 0);
		oAvalonRead			: out std_ulogic;
		oAvalonWrite		: out std_ulogic
	);
end entity AvalonMaster;

architecture RTL of AvalonMaster is
	
	constant cCountMax	: natural := gClkFrequency/gAddrChangeFreq;
	
	type tState is (Idle, Read, NextAddr );
	
	type tData is record
		State			: tState;
		FreqCount		: natural range 0 to cCountMax-1;
		AvAddr			: natural range 0 to gNumOfAvalonAddresses-1;
		AvWriteData		: std_ulogic_vector(gAvalonDataWidth-1 downto 0);
		AvRead			: std_ulogic;
		AvWrite			: std_ulogic;		
	end record tData;
	
	constant cDefault	: tData := (
		State			=> Idle,
		FreqCount		=> 0,
		AvAddr			=> 0,
		AvWriteData		=> (others => '0'),
		AvRead			=> '0',
		AvWrite			=> '0'
	);
	
	signal R,NxR	: tData;
	
	
begin
	
	Reg : process(iClk, inRstAsync) is
		
		begin
			if inRstAsync = not('1') then
				R <= cDefault;
			elsif rising_edge(iClk) then
				R <= NxR;
			end if;
	end process Reg;
	
	Comb: process (
		R
	) is
	
	begin
		NxR <= R;
	
		case (R.State) is
			
			when Idle =>
				NxR.State <= Read;
				
			when Read =>
				NxR.AvRead <= '1';
				NxR.FreqCount <= cCountMax-1;
				NxR.State <= NextAddr;
				
			when NextAddr => 
				if R.FreqCount = 0 then
					NxR.AvRead <= '0';
					NxR.State <= Read;
					if R.AvAddr = gNumOfAvalonAddresses-1 then
						NxR.AvAddr <= 0;
					else
						NxR.AvAddr <= R.AvAddr+1;
					end if;
				else
					NxR.FreqCount <= R.FreqCount - 1;
				end if;
			
		end case;
		
	
	end process;
	
	-- output connect
	oAvalonAddr <= std_ulogic_vector(to_unsigned(R.AvAddr,gAvalonAddrWidth));
	oAvalonRead <= R.AvRead;
	oAvalonWriteData <= R.AvWriteData;
	oAvalonWrite <= R.AvWrite;
	
	
end architecture RTL;


























