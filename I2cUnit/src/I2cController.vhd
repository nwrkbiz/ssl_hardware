-------------------------------------------------------------------------
-- I2cController.vhd
--
-- Author: Elias Geissler
-- Project: SSL1 Master ESD at FH Hagenberg
-------------------------------------------------------------------------
-- Description: simple interface to control i2c

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.pkgGlobal.all;

entity I2cController is
	generic(
		gClkFrequency	: natural := 50_000_000;
		gI2cFrequency	: natural := 400_000;
		
		-- determines the size of vector iI2cData
		gNumOfParallelBytes		: natural := 1
	);
	port(
		iClk 		: in std_ulogic;
		inRstAsync 	: in std_ulogic;
		
		-- i2c 
		ioSCL		: inout std_logic;
		ioSDA		: inout std_logic;
		
		-- i2c address already with R/W bit
		iI2cAddr		: in std_ulogic_vector(6 downto 0);
		iI2cRegAddr		: in std_ulogic_vector(7 downto 0);
		iI2cData		: in std_ulogic_vector(gNumOfParallelBytes*8-1 downto 0);
		oI2cData		: out std_ulogic_vector(gNumOfParallelBytes*8-1 downto 0);
		
		-- determines the burst size of the current transfer
		iI2cBurstCount	: in natural range 0 to gNumOfParallelBytes;	
		
		-- one of these must be be asserted for only one cycle to start a transfer
		iI2cRead			: in  std_ulogic;
		iI2cWrite			: in  std_ulogic;
		
		-- signals the end of one transfer
		oTransferDone	: out std_ulogic
		
		
	);
end entity I2cController;

architecture RTL of I2cController is
	
	-- i2c tristate
	signal sda_tri_i, sda_tri_o, sda_tri_t, sda_async, sda_sync	: std_ulogic;
	signal scl_tri_i, scl_tri_o, scl_tri_t, scl_async, scl_sync	: std_ulogic;
	signal scl_sync_dlyd : std_ulogic;
	
	type tI2cData	is array (0 to gNumOfParallelBytes-1) of std_ulogic_vector(7 downto 0);
	
	type tState is (	Idle, WaitOnTransfer, RegisterData, TransferDone, 
						RW_I2cAddress, RW_WaitOnAck0, RW_I2cRegAddress, RW_WaitOnAck1,
						W_WriteData, W_NextData,
						R_I2cAddress, R_WaitOnAck2, R_ReadData, R_NextData
					);
	
	type tI2c is record
		State			: tState;
	
		I2cAddr			: std_ulogic_vector(6 downto 0);
		I2cRegAddr  	: std_ulogic_vector(7 downto 0);
		I2cDataIn		: tI2cData;
		I2cDataOut		: tI2cData;
		I2cBurstCount	: natural range 0 to gNumOfParallelBytes;
		I2cDone			: std_ulogic;
		I2cRead			: std_ulogic;
		I2cWrite		: std_ulogic;
		I2cBurstIndex	: natural;
		
		-- i2c signals for i2c core
		Enable 	: std_ulogic;
		Start 	: std_ulogic;
		Stop 	: std_ulogic;
		Read 	: std_ulogic;
		Write 	: std_ulogic;
		AckIn 	: std_ulogic;
		DataIn 	: std_ulogic_vector(7 downto 0);
	end record tI2c;
	
	constant cDefault	: tI2c := (
		State 			=> Idle,
		
		I2cAddr			=> (others => '0'),
		I2cRegAddr  	=> (others => '0'),
		I2cDataIn		=> (others => (others => '0')),
		I2cDataOut		=> (others => (others => '0')),
		I2cBurstCount	=> 0,
		I2cDone			=> '0',
		I2cRead			=> '0',
		I2cWrite		=> '0',
		I2cBurstIndex	=> 0,
		
		Enable 	=> '0',
		Start 	=> '0',
		Stop 	=> '0',
		Read 	=> '0',
		Write 	=> '0',
		AckIn 	=> '0',
		DataIn 	=> (others => '0')
	);
	
	signal R,NxR	: tI2c;
	
	-- i2c core signals
	signal CmdAck : std_ulogic;
	signal DataOut : std_logic_vector(7 downto 0);

	
	
begin
	
	-- split i2c into the three tristate signale to sync sda
	scl_async 	<= ioSCL;
	ioSCL 		<= scl_tri_o when scl_tri_t = '0' else 'Z';
	scl_tri_i	<= scl_sync;
	
	sda_async 	<= ioSDA;
	ioSDA 		<= sda_tri_o when sda_tri_t = '0' else 'Z';
	sda_tri_i	<= sda_sync;
	
	-- sync sda (scl will not be read in this design)
	Sync: entity work.Sync
		generic map(
			gSyncStages => 2,
			gDataWidth  => 3
		)
		port map(
			iClk       => iClk,
			inRstAsync => not('0'),	-- no reset 
			iData(0)      => sda_async,
			iData(1)      => scl_async,
			iData(2)      => scl_sync,
			oData(0)      => sda_sync,
			oData(1)      => scl_sync,
			oData(2)      => scl_sync_dlyd
		);
		
				
		
	Regs: process (iClk, inRstAsync) is
	begin
		if inRstAsync = not('1') then
			R <= cDefault;
			
		elsif rising_edge(iClk) then
			R <= NxR;
		end if;
	end process;
	
	Comb: process (
		iI2cAddr, iI2cRegAddr, iI2cBurstCount, iI2cData, iI2cRead, iI2cWrite, 
		CmdAck, DataOut, 
		R, scl_sync, scl_sync_dlyd, sda_sync
	)	is
	
	begin
	
		-- default
		NxR <= R;
		NxR.Enable 	<= '1';		-- always enable i2c core
		NxR.Start 	<= '0';
		NxR.Stop 	<= '0';
		NxR.Read 	<= '0';
		NxR.Write 	<= '0';
		NxR.AckIn 	<= '1';		-- disable ackin
		NxR.I2cDone <= '0';
		
		case R.State is
			
			when Idle =>
				NxR.State <= WaitOnTransfer;
				
			when WaitOnTransfer =>
				if (iI2cRead or iI2cWrite) = '1' then
					NxR.State <= RegisterData;
					-- they can be asserted only one cycle
					NxR.I2cRead <= iI2cRead;
					NxR.I2cWrite <= iI2cWrite;
				end if;
				
			when RegisterData =>
				NxR.I2cBurstIndex	<= 0;	-- reset index
				NxR.I2cAddr 		<= iI2cAddr;
				NxR.I2cRegAddr 		<= iI2cRegAddr;
				for i in 0 to gNumOfParallelBytes-1 loop
					NxR.I2cDataIn(i)	<= iI2cData(7+8*i downto 0+8*i); 
				end loop;
				NxR.I2cBurstCount	<= iI2cBurstCount;
				NxR.State			<= RW_I2cAddress;
				
			-- now do the actual i2c transfer
			-- RW_ : appears in read and write transfer
			-- R_ : appears in read transfer
			-- W_ : appears in write transfer
			when RW_I2cAddress =>
				NxR.Start  	<= '1';
				NxR.Write  	<= '1';
				NxR.DataIn	<= R.I2cAddr & cI2cWrite;
				if CmdAck = '1' then
					NxR.Start  	<= '0';
					NxR.Write  	<= '0';
					NxR.State 			<= RW_WaitOnAck0;
				end if;
				
			when RW_WaitOnAck0	=>
				-- check sda on rising edge of scl
				if scl_sync_dlyd = '0' and (scl_sync = '1' or scl_sync = 'H') then -- rising_edge(scl)
					if sda_sync = '0' then
						NxR.State <= RW_I2cRegAddress;
					else
						NxR.State <= RW_I2cAddress;
					end if;
				end if;
				
			when RW_I2cRegAddress =>
				NxR.Write	<= '1';
				NxR.DataIn	<= R.I2cRegAddr;
				if CmdAck = '1' then
					NxR.Write  	<= '0';
					NxR.State 			<= RW_WaitOnAck1;
				end if; 
				
			when RW_WaitOnAck1	=> 
				-- check sda on rising edge of scl
				if scl_sync_dlyd = '0' and (scl_sync = '1' or scl_sync = 'H') then -- rising_edge(scl)
					if sda_sync = '0' then
						-- the next state is read/write dependent
						if R.I2cRead = '1' then
							NxR.State <= R_I2cAddress;
						elsif R.I2cWrite = '1' then
							NxR.State <= W_WriteData;
						end if;
					else
						NxR.State <= RW_I2cAddress;
					end if;
				end if;
				
				
			-------------------------------------------------------------------
			-- write burst
			-------------------------------------------------------------------
			when W_WriteData =>
				if 	R.I2cBurstCount = 0 then
					NxR.State <= TransferDone;
				else
					if R.I2cBurstCount = 1 then
						NxR.Stop 	<= '1';
					end if;
					NxR.Write 	<= '1';
					NxR.DataIn	<= R.I2cDataIn(R.I2cBurstIndex);
					if CmdAck = '1' then
						NxR.Write  	<= '0';
						NxR.State <= W_NextData;
					end if;
				end if;
								
			when W_NextData =>
				NxR.I2cBurstIndex	<= R.I2cBurstIndex+1;
				NxR.I2cBurstCount 	<= R.I2cBurstCount-1;
				NxR.State 			<= W_WriteData;
							
			-------------------------------------------------------------------
			-- read burst
			-------------------------------------------------------------------
			when R_I2cAddress => 
				NxR.Start  	<= '1';
				NxR.Write  	<= '1';
				NxR.DataIn	<= R.I2cAddr & cI2cRead;
				if CmdAck = '1' then
					NxR.Start  			<= '0';
					NxR.Write  			<= '0';
					NxR.State 			<= R_WaitOnAck2;
				end if;
				
			when R_WaitOnAck2	=>
				-- check sda on rising edge of scl
				if scl_sync_dlyd = '0' and (scl_sync = '1' or scl_sync = 'H') then -- rising_edge(scl)
					if sda_sync = '0' then
						NxR.State <= R_ReadData;
					else
						NxR.State <= R_I2cAddress;
					end if;
				end if;
				
			when R_ReadData =>
				if 	R.I2cBurstCount = 0 then
					NxR.State <= TransferDone;
				else
					NxR.AckIn	<= '0'; -- send ACK
					NxR.Read 	<= '1';
					-- if its the last byte read: send stop and no ACK
					if R.I2cBurstCount = 1 then
						NxR.Stop 	<= '1';
						NxR.AckIn	<= '1';
					end if;
					if CmdAck = '1' then
						NxR.Read 	<= '0';
						NxR.State <= R_NextData;
					end if;
				end if;
						
						
			when R_NextData =>
				NxR.I2cBurstCount 	<= R.I2cBurstCount-1;
				NxR.State 			<= R_ReadData;
				NxR.I2cDataOut(R.I2cBurstIndex)	<= std_ulogic_vector(DataOut);
				NxR.I2cBurstIndex	<= R.I2cBurstIndex+1;
				
			when TransferDone => 
				NxR.I2cDone <= '1';
				NxR.State 	<= Idle; 
			
		end case;
	end process;
	
	
	oTransferDone 	<= R.I2cDone;

	ForGen: for i in 0 to gNumOfParallelBytes-1 generate
				oI2cData(7+8*i downto 0+8*i)	<= R.I2cDataOut(i);
			end generate;
	
	i2c_core: entity work.simple_i2c
		port map(
			clk     => iClk,
			ena     => R.Enable,
			nReset  => inRstAsync,
			clk_cnt => to_unsigned(gClkFrequency/gI2cFrequency/5 -1,8), -- creates a 400kHz clk
			start   => R.Start,
			stop    => R.Stop,
			read    => R.Read,
			write   => R.Write,
			ack_in  => R.AckIn,
			Din     => std_logic_vector(R.DataIn),
			cmd_ack => CmdAck,
			Dout    => DataOut,
		
			-- i2c tristated
			scl_tri_i	=> scl_tri_i,
			scl_tri_o	=> scl_tri_o,
			scl_tri_t	=> scl_tri_t,
			
			sda_tri_i	=> sda_tri_i,
			sda_tri_o	=> sda_tri_o,
			sda_tri_t	=> sda_tri_t
		);
	
	
	
	
end architecture RTL;




















