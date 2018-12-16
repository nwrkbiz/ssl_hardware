-------------------------------------------------------------------------
-- FSMD.vhd
--
-- Author: Elias Geissler
-- Project: SSL1 Master ESD at FH Hagenberg
-------------------------------------------------------------------------
-- Description: FSMD to read values from MPU9250 over i2c and put data into fifo

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.pkgGlobal.all;
use work.pkgMPU9250.all;

entity FsmdMPU9250 is
	generic(
		gClkFrequency	: natural	:= 50_000_000;
		gI2cFrequency	: natural	:= 400_000;
		gFifoByteWidth	: natural	:= 8
	);
	port(
		iClk 		: in std_ulogic;
		inRstAsync 	: in std_ulogic;
		
		-- i2c interface
		ioSCL		: inout	std_logic;
		ioSDA		: inout std_logic;
		
		-- fifo
		oFifoData	: out std_ulogic_vector(gFifoByteWidth*8-1 downto 0);
		oFifoWrite	: out std_ulogic;
		
		-- regfile interface
		iRegDataFrequency	: in std_ulogic_vector(15 downto 0);
		
		-- strobe and timestamp
		iStrobe		: in std_ulogic;
		iTimeStamp	: in std_ulogic_vector(cTimeStampWidth-1 downto 0)
	);
end entity FsmdMPU9250;

architecture RTL of FsmdMPU9250 is
	
	constant cI2cMaxBurst	: natural := 6;
	type tI2cData is array (0 to cI2cMaxBurst-1) of std_ulogic_vector(7 downto 0);	
		
	type tState is (Idle, WaitForI2cTransfer, Config, 
					ReadDataAcc, SaveDataAcc, ReadDataGyro, SaveDataGyro, ReadDataMagnet, SaveDataMagnet,
					WriteDataToFifo
					);
	
	type tData is record
		State 		: tState;
		FreqCount	: natural;
		ReadI2cData	: std_ulogic;
		
		I2cAddr			: std_ulogic_vector(6 downto 0);
		I2cRegAddr		: std_ulogic_vector(7 downto 0);
		I2cRead 		: std_ulogic;
		I2cWrite 		: std_ulogic;
		I2cDataIn 		: tI2cData;
		I2cBurstCount	: natural range 0 to cI2cMaxBurst;
		I2cConfigCount	: natural range 0 to cI2cRegsToConfigure-1;
		
		FifoData	: std_ulogic_vector(gFifoByteWidth*8-1 downto 0);
		FifoWrite	: std_ulogic;
	end record tData;
	
	constant cDefaultData : tData := (
		State 		=> Idle,
		FreqCount	=> 0,
		ReadI2cData	=> '0',
		
		I2cAddr			=> (others => '0'),
		I2cRegAddr		=> (others => '0'),
		I2cRead 		=> '0',
		I2cWrite 		=> '0',
		I2cDataIn 		=> (others => (others =>'0')),
		I2cBurstCount	=> 0,
		I2cConfigCount	=> 0,
		
		FifoData	=> (others => '0'),
		FifoWrite	=> '0'
	);
	
	signal R,NxR	: tData;
	
	signal I2cDataInVec, I2cDataOutVec	: std_ulogic_vector(cI2cMaxBurst*8-1 downto 0);
	signal I2cTransferDone : std_ulogic;
	
begin
	
	Reg: process (iClk, inRstAsync) is
	begin
		if inRstAsync = not('1') then
			R <= cDefaultData;
			
		elsif rising_edge(iClk) then
			R <= NxR;
		end if;
	end process;
	
	FSMD: process (
		R, iRegDataFrequency, iStrobe, iTimeStamp, I2cTransferDone, I2cDataOutVec
	) is	
	begin
		-- defaults
		NxR <= R;
		NxR.I2cRead		<= '0';
		NxR.I2cWrite	<= '0';
		NxR.FifoWrite	<= '0';
		
		
		-- freq count logic
		---------------------------------------------------------------
		if iStrobe = '1' then
			if R.FreqCount = 0 then
				-- reset count and set i2c transfer
				NxR.FreqCount <= to_integer(unsigned(iRegDataFrequency))-1;
				NxR.ReadI2cData <= '1';
			else
				NxR.FreqCount <= R.FreqCount - 1;
			end if;
		end if;
	
	
		-- FSMD start
		---------------------------------------------------------------
		case (R.State) is
			when Idle =>
				NxR.State <= Config;
				
			when Config =>
				NxR.I2cAddr 		<= cI2cConfig(R.I2cConfigCount).I2cAddr;
				NxR.I2cRegAddr		<= cI2cConfig(R.I2cConfigCount).I2cRegAddr;
				NxR.I2cDataIn(0)	<= cI2cConfig(R.I2cConfigCount).I2cRegData;
				NxR.I2cBurstCount 	<= 1; --write 1 byte
				NxR.I2cWrite		<= '1';
				if I2cTransferDone = '1' then
					NxR.I2cWrite	<= '0';
					if R.I2cConfigCount = cI2cRegsToConfigure-1 then
						NxR.State		<= WaitForI2cTransfer;
					else
						NxR.State			<= Config;
						NxR.I2cConfigCount 	<= R.I2cConfigCount+1;
					end if;
				end if;
				
			when WaitForI2cTransfer =>
				if R.ReadI2cData = '1' then
					NxR.State <= ReadDataAcc;
					NxR.ReadI2cData <= '0';
				end if;
				
			when ReadDataAcc =>
				NxR.I2cAddr 		<= cI2cAddrMPU9250;
				NxR.I2cRegAddr		<= cI2cRegAddrAccel_Xout_H;
				NxR.I2cBurstCount 	<= 6; -- read 6 bytes of data
				NxR.I2cRead	<= '1';
				if I2cTransferDone = '1' then
					NxR.I2cRead	<= '0';
					NxR.State		<= SaveDataAcc;
				end if;
				
			when SaveDataAcc =>
				NxR.FifoData(tFifoRangeAccelerometer_X_H)	<= I2cDataOutVec(7  downto 0 );		-- first   byte read
				NxR.FifoData(tFifoRangeAccelerometer_X_L)	<= I2cDataOutVec(15 downto 8 );		-- second
				NxR.FifoData(tFifoRangeAccelerometer_Y_H)	<= I2cDataOutVec(23 downto 16);		-- third
				NxR.FifoData(tFifoRangeAccelerometer_Y_L)	<= I2cDataOutVec(31 downto 24);		-- fourth
				NxR.FifoData(tFifoRangeAccelerometer_Z_H)	<= I2cDataOutVec(39 downto 32);		-- fifth
				NxR.FifoData(tFifoRangeAccelerometer_Z_L)	<= I2cDataOutVec(47 downto 40);		-- sixth
				NxR.State		<= ReadDataGyro;
				
			when ReadDataGyro =>
				NxR.I2cAddr 		<= cI2cAddrMPU9250;
				NxR.I2cRegAddr		<= cI2cRegAddrGyroscope_Xout_H;
				NxR.I2cBurstCount 	<= 6; -- read 6 bytes of data
				NxR.I2cRead	<= '1';
				if I2cTransferDone = '1' then
					NxR.I2cRead	<= '0';
					NxR.State		<= SaveDataGyro;
				end if;
				
			when SaveDataGyro =>
				NxR.FifoData(tFifoRangeGyroscope_X_H)	<= I2cDataOutVec(7  downto 0 );		-- first   byte read
				NxR.FifoData(tFifoRangeGyroscope_X_L)	<= I2cDataOutVec(15 downto 8 );		-- second
				NxR.FifoData(tFifoRangeGyroscope_Y_H)	<= I2cDataOutVec(23 downto 16);		-- third
				NxR.FifoData(tFifoRangeGyroscope_Y_L)	<= I2cDataOutVec(31 downto 24);		-- fourth
				NxR.FifoData(tFifoRangeGyroscope_Z_H)	<= I2cDataOutVec(39 downto 32);		-- fifth
				NxR.FifoData(tFifoRangeGyroscope_Z_L)	<= I2cDataOutVec(47 downto 40);		-- sixth
				NxR.State		<= ReadDataMagnet;
				
			when ReadDataMagnet =>
				NxR.I2cAddr 		<= cI2cAddrAK8963;
				NxR.I2cRegAddr		<= cI2cRegAddrMagnetometer_Xout_L;
				NxR.I2cBurstCount 	<= 6; -- read 6 bytes of data
				NxR.I2cRead	<= '1';
				if I2cTransferDone = '1' then
					NxR.I2cRead	<= '0';
					NxR.State		<= SaveDataMagnet;
				end if;
				
			when SaveDataMagnet =>
				NxR.FifoData(tFifoRangeMagnetometer_X_L)	<= I2cDataOutVec(7  downto 0 );		-- first   byte read
				NxR.FifoData(tFifoRangeMagnetometer_X_H)	<= I2cDataOutVec(15 downto 8 );		-- second
				NxR.FifoData(tFifoRangeMagnetometer_Y_L)	<= I2cDataOutVec(23 downto 16);		-- third
				NxR.FifoData(tFifoRangeMagnetometer_Y_H)	<= I2cDataOutVec(31 downto 24);		-- fourth
				NxR.FifoData(tFifoRangeMagnetometer_z_L)	<= I2cDataOutVec(39 downto 32);		-- fifth
				NxR.FifoData(tFifoRangeMagnetometer_Z_H)	<= I2cDataOutVec(47 downto 40);		-- sixth
				-- save time stamp
				NxR.FifoData(tFifoRangeTimeStamp)	<= iTimeStamp;
				
				if I2cDataOutVec = (I2cDataOutVec'range => '0') then
					NxR.State <= Config;
				else
					NxR.State		<= WriteDataToFifo;	
				end if;
				
			when WriteDataToFifo =>
				NxR.FifoWrite 	<= '1';
				NxR.State		<= WaitForI2cTransfer;
			
		end case;
		
	
	end process;

	-- outputs
	oFifoData 	<= R.FifoData;
	oFifoWrite	<= R.FifoWrite;
	
	
	I2cController: entity work.I2cController
		generic map(
			gClkFrequency       => gClkFrequency,
			gI2cFrequency       => gI2cFrequency,
			gNumOfParallelBytes => cI2cMaxBurst
		)
		port map(
			iClk           => iClk,
			inRstAsync     => inRstAsync,
			ioSCL          => ioSCL,
			ioSDA          => ioSDA,
			iI2cAddr       => R.I2cAddr,
			iI2cRegAddr    => R.I2cRegAddr,
			iI2cData       => I2cDataInVec,
			oI2cData       => I2cDataOutVec,
			iI2cBurstCount => R.I2cBurstCount,
			iI2cRead       => R.I2cRead,
			iI2cWrite      => R.I2cWrite,
			oTransferDone  => I2cTransferDone
		);
		
	-- connect data_in
	forLoop: for i in 0 to cI2cMaxBurst-1 generate 
		I2cDataInVec(7+8*i downto 0+8*i) <= R.I2cDataIn(i);
	end generate;

end architecture RTL;
