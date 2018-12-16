-------------------------------------------------------------------------
-- TbI2cController.vhd
--
-- Author: Elias Geissler
-- Project: SSL1 Master ESD at FH Hagenberg
-------------------------------------------------------------------------
-- Description: testbench for i2c controller

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity TbI2cController is
end entity TbI2cController;

architecture RTL of TbI2cController is
	constant gClkFrequency 	: natural	:= 50_000_000;
	constant cClkPeriod		: time		:= 1 sec/gClkFrequency;
	constant gI2cFrequency 	: natural	:= 400_000;

	
	signal iClk : std_ulogic	:= '0';
	signal inRstAsync : std_ulogic := not('1');
	signal ioSCL : std_logic	:= 'H';
	signal ioSDA : std_logic	:= 'H';
	signal iI2cAddr : std_ulogic_vector(6 downto 0);
	signal iI2cRegAddr : std_ulogic_vector(7 downto 0);
	signal iI2cData : std_ulogic_vector(4*8-1 downto 0);
	signal oI2cData : std_ulogic_vector(4*8-1 downto 0);
	signal iI2cBurstCount : natural range 0 to 4-1;
	signal iI2cRead : std_ulogic;
	signal iI2cWrite : std_ulogic;
	signal oTransferDone : std_ulogic;
	signal iRstAsync : std_logic;
begin
	
	iClk 		<= not(iClk) after cClkPeriod/2;
	inRstAsync 	<= not('0') after 100 ns;
	
	UUT: entity work.I2cController
		generic map(
			gClkFrequency       => gClkFrequency,
			gI2cFrequency       => gI2cFrequency,
			gNumOfParallelBytes => 4
		)
		port map(
			iClk           => iClk,
			inRstAsync     => inRstAsync,
			ioSCL          => ioSCL,
			ioSDA          => ioSDA,
			iI2cAddr       => iI2cAddr,
			iI2cRegAddr    => iI2cRegAddr,
			iI2cData       => iI2cData,
			oI2cData       => oI2cData,
			iI2cBurstCount => iI2cBurstCount,
			iI2cRead       => iI2cRead,
			iI2cWrite      => iI2cWrite,
			oTransferDone  => oTransferDone
		);
		
	ioSCL <= 'H';
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
		
		
	Stimul: process is
	begin
		-- reset
		iI2cAddr <= (others => '0');
		iI2cRegAddr <= (others => '0');
		iI2cData <= (others => '0');
		iI2cBurstCount <= 0;
		iI2cRead	<= '0';
		iI2cWrite	<= '0';
		
		wait for 500*cClkPeriod;
		
		iI2cAddr <= "H000000";
		iI2cData <= x"12345678";
		iI2cBurstCount <= 3;
		iI2cWrite <= '1';
		
		wait until oTransferDone = '1';
		wait until rising_edge(iClk);
		iI2cWrite <= '0';
		
		wait for 10000*cClkPeriod;
		
		iI2cAddr <= "H000000";
		iI2cBurstCount <= 2;
		iI2cRead <= '1';
		
		wait for cClkPeriod;
		iI2cRead <= '0';
		
		
		wait;
	end process;

end architecture RTL;
