-------------------------------------------------------------------------
-- TbHDC1000.vhd
--
-- Author: Elias Geissler
-- Project: SSL1 Master ESD at FH Hagenberg
-------------------------------------------------------------------------
-- Description: testbench for HDC1000.vhd
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.pkgGlobal.all;

entity TbHDC1000 is
end entity TbHDC1000;

architecture Bhv of TbHDC1000 is
	constant gClkFrequency 	: natural	:= 50_000_000;
	constant cClkPeriod		: time		:= 1 sec/gClkFrequency;
	constant gStrobeTime 	: time		:= 1 us;
	constant gI2cFrequency 	: natural	:= 400_000;
	constant gSyncStages 	: natural	:= 2;
	
	signal iClk 			: std_ulogic	:= '0';
	signal inRstAsync 		: std_ulogic	:= not('1');
	signal iRstAsync 		: std_ulogic;
	signal ioSCL 			: std_logic;
	signal ioSDA 			: std_logic;
	signal inDataReady 		: std_ulogic;
	signal iAvalonAddr 		: std_ulogic_vector(cAvalonAddrWidth-1 downto 0);
	signal iAvalonRead 		: std_ulogic;
	signal oAvalonReadData 	: std_ulogic_vector(cAvalonDataWidth-1 downto 0);
	signal iAvalonWrite 	: std_ulogic;
	signal iAvalonWriteData : std_ulogic_vector(cAvalonDataWidth-1 downto 0);
	signal oLEDs 			: std_ulogic_vector(8 downto 0);
	
	
begin
	
	iClk <= not(iClk) after cClkPeriod/2;
	inRstAsync <= not('0') after 100 ns;
	
	-- avalon inactive
	iAvalonAddr 	 <= (others => '0');
	iAvalonRead 	 <= '0';
	iAvalonWrite 	 <= '0';
	iAvalonWriteData <= (others => '0');

	UUT: entity work.HDC1000
		generic map(
			gClkFrequency => gClkFrequency,
			gStrobeTime   => gStrobeTime,
			gI2cFrequency => gI2cFrequency,
			gSyncStages   => gSyncStages
		)
		port map(
			iClk             => iClk,
			inRstAsync       => inRstAsync,
			ioSCL            => ioSCL,
			ioSDA            => ioSDA,
			inDataReady      => inDataReady,
			iAvalonAddr      => iAvalonAddr,
			iAvalonRead      => iAvalonRead,
			oAvalonReadData  => oAvalonReadData,
			iAvalonWrite     => iAvalonWrite,
			iAvalonWriteData => iAvalonWriteData,
			oLEDs            => oLEDs
		);
		
	inDataReady <= not('1');
		
	ioSCl <= 'H';
	ioSDA <= 'H';
		
	iRstAsync <= not(inRstAsync);
		
	Slave: entity work.I2C_slave
		generic map(
			SLAVE_ADDR => "H000000"
		)
		port map(
			scl              => ioSCL,
			sda              => ioSDA,
			clk              => iClk,
			rst              => iRstAsync,
			data_to_master   => "H0H0H00H"
		);
end architecture Bhv;
