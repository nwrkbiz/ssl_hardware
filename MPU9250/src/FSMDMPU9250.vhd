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
		
		-- streaming fifo
		oFifoData	: out std_ulogic_vector(gFifoByteWidth*8-1 downto 0);
		oFifoWrite	: out std_ulogic;
		
		-- event fifos
		-- 256
		oFifoData256	: out std_ulogic_vector(cEventModeFifoBytes*8-1 downto 0);
		oFifoWrite256	: out std_ulogic;
		iFifoFull256	: in  std_ulogic;
		iFifoEmpty256	: in  std_ulogic;
		-- 768
		oFifoData768	: out std_ulogic_vector(cEventModeFifoBytes*8-1 downto 0);
		oFifoWrite768	: out std_ulogic;
		iFifoFull768	: in  std_ulogic;
		iFifoEmpty768	: in  std_ulogic;
		
		-- event mode interrrupt
		oEventOccured	: out std_ulogic;
		
		-- regfile interface
		iRegFileData		: in std_ulogic_vector(cRegFileNumberOfBytes*8-1 downto 0);
		
		-- mode selection
		iStreamingModeActive	: in std_ulogic;
		
		-- strobe and timestamp
		iStrobe		: in std_ulogic;
		iTimeStamp	: in std_ulogic_vector(cTimeStampWidth-1 downto 0);
		
		oLEDs		: out std_ulogic_vector(9 downto 0)
	);
end entity FsmdMPU9250;

architecture RTL of FsmdMPU9250 is
	
	constant cI2cMaxBurst	: natural := 6;
	type tI2cData is array (0 to cI2cMaxBurst-1) of std_ulogic_vector(7 downto 0);	
		
	type tState is (Idle, WaitForI2cTransfer, Config, 
					ReadDataAcc, SaveDataAcc, ReadDataGyro, SaveDataGyro, ReadDataMagnet, SaveDataMagnet,
					ReadAK8963StatusReg2, ModeSelection, StoreDataInFifo, EventMode
					);
					
	
	type tEventModeState is (Idle, FillFifo256, CompareValues, HitDetected, Fifo768Full, WaitUntilDataIsRead);
	
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
		
		FifoData256		: std_ulogic_vector(cEventModeFifoBytes*8-1 downto 0);
		FifoWrite256	: std_ulogic;
		
		FifoData768		: std_ulogic_vector(cEventModeFifoBytes*8-1 downto 0);
		FifoWrite768	: std_ulogic;
		
		EventModeState	: tEventModeState;
		EventModeCount	: natural range 0 to cEventModeFreq-1;
		EventInterrupt	: std_ulogic;
		IrqCount		: natural range 0 to 9;
		
		LEDs			: std_ulogic_vector(9 downto 0);
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
		FifoWrite	=> '0',
		
		FifoData256		=> (others => '0'),
		FifoWrite256	=> '0',
		
		FifoData768		=> (others => '0'),
		FifoWrite768	=> '0',
		
		EventModeState  => Idle,
		EventModeCount	=> 0,
		EventInterrupt	=> '0',
		IrqCount		=> 0,
		
		LEDs			=> (others => '0')
	);
	
	signal R,NxR	: tData;
	
	signal I2cDataInVec, I2cDataOutVec	: std_ulogic_vector(cI2cMaxBurst*8-1 downto 0);
	signal I2cTransferDone : std_ulogic;
	
	signal RegDataFrequency : std_ulogic_vector(15 downto 0);
	signal XToleranceTop	: signed(15 downto 0);
	signal XToleranceBottom	: signed(15 downto 0);
	signal YToleranceTop	: signed(15 downto 0);
	signal YToleranceBottom	: signed(15 downto 0);
	signal ZToleranceTop	: signed(15 downto 0);
	signal ZToleranceBottom	: signed(15 downto 0);
	
begin
	
	-- reg file connections
	RegDataFrequency(15 downto 8)	<= iRegFileData(cRegAddrFrequenzy_H*8+7 downto cRegAddrFrequenzy_H*8);
	RegDataFrequency(7  downto 0)	<= iRegFileData(cRegAddrFrequenzy_L*8+7 downto cRegAddrFrequenzy_L*8);
	
	-- x
	XToleranceTop(15 downto 8)		<= signed(iRegFileData(cRegAddrTolerance_X_Top_H*8+7 downto cRegAddrTolerance_X_Top_H*8));
	XToleranceTop(7  downto 0)		<= signed(iRegFileData(cRegAddrTolerance_X_Top_L*8+7 downto cRegAddrTolerance_X_Top_L*8));
	XToleranceBottom(15 downto 8)	<= signed(iRegFileData(cRegAddrTolerance_X_Bot_H*8+7 downto cRegAddrTolerance_X_Bot_H*8));
	XToleranceBottom(7  downto 0)	<= signed(iRegFileData(cRegAddrTolerance_X_Bot_L*8+7 downto cRegAddrTolerance_X_Bot_L*8));
	--y
	YToleranceTop(15 downto 8)		<= signed(iRegFileData(cRegAddrTolerance_Y_Top_H*8+7 downto cRegAddrTolerance_Y_Top_H*8));
	YToleranceTop(7  downto 0)		<= signed(iRegFileData(cRegAddrTolerance_Y_Top_L*8+7 downto cRegAddrTolerance_Y_Top_L*8));
	YToleranceBottom(15 downto 8)	<= signed(iRegFileData(cRegAddrTolerance_Y_Bot_H*8+7 downto cRegAddrTolerance_Y_Bot_H*8));
	YToleranceBottom(7  downto 0)	<= signed(iRegFileData(cRegAddrTolerance_Y_Bot_L*8+7 downto cRegAddrTolerance_Y_Bot_L*8));
	-- z
	ZToleranceTop(15 downto 8)		<= signed(iRegFileData(cRegAddrTolerance_Z_Top_H*8+7 downto cRegAddrTolerance_Z_Top_H*8));
	ZToleranceTop(7  downto 0)		<= signed(iRegFileData(cRegAddrTolerance_Z_Top_L*8+7 downto cRegAddrTolerance_Z_Top_L*8));
	ZToleranceBottom(15 downto 8)	<= signed(iRegFileData(cRegAddrTolerance_Z_Bot_H*8+7 downto cRegAddrTolerance_Z_Bot_H*8));
	ZToleranceBottom(7  downto 0)	<= signed(iRegFileData(cRegAddrTolerance_Z_Bot_L*8+7 downto cRegAddrTolerance_Z_Bot_L*8));
	
	Reg: process (iClk, inRstAsync) is
	begin
		if inRstAsync = not('1') then
			R <= cDefaultData;
			
		elsif rising_edge(iClk) then
			R <= NxR;
		end if;
	end process;
	
	FSMD: process (
		R, RegDataFrequency, iStrobe, iTimeStamp, I2cTransferDone, I2cDataOutVec, 
		iFifoFull256, iFifoEmpty256, iFifoEmpty768, iFifoFull768, iStreamingModeActive, 
		XToleranceBottom, XToleranceTop, YToleranceBottom, YToleranceTop, ZToleranceBottom, ZToleranceTop
	) is	
		variable AccX, AccY, AccZ : signed(15 downto 0);
	begin
		-- defaults
		NxR <= R;
		NxR.I2cRead		<= '0';
		NxR.I2cWrite	<= '0';
		NxR.FifoWrite	<= '0';
		NxR.FifoWrite256 <= '0';
		NxR.FifoWrite768 <= '0';
		NxR.EventInterrupt <= '0';
		NxR.LEDs(7) <= '0';
		NxR.LEDs(8) <= '0';
		
		
		-- freq count logic
		---------------------------------------------------------------
		if iStrobe = '1' then
			if R.FreqCount = 0 then
				-- reset count and set i2c transfer
				NxR.FreqCount <= to_integer(unsigned(RegDataFrequency))-1;
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
				
				-- if magneotmeter sends always zeros -> reset the whole fsm to do config again
				if I2cDataOutVec = (I2cDataOutVec'range => '0') then
					NxR.State <= Config;
				else
					NxR.State		<= ReadAK8963StatusReg2;	
				end if;
				
			when ReadAK8963StatusReg2 =>
				-- status reg 2 needs to be read to enable a new data conversion
				-- data will not be used
				NxR.I2cAddr 		<= cI2cAddrAK8963;
				NxR.I2cRegAddr		<= cI2cRegAddrMagnetometer_St2;
				NxR.I2cBurstCount 	<= 1;
				NxR.I2cRead	<= '1';
				if I2cTransferDone = '1' then
					NxR.I2cRead	<= '0';
					NxR.State		<= ModeSelection;
				end if;
				
			when ModeSelection =>
				-- decide if streaming mode or event mode is active
				if iStreamingModeActive = '1' then
					NxR.LEDs(0)		<= '1';
					NxR.State		<= StoreDataInFifo;
				else
					NxR.LEDs(0)		<= '0';
					NxR.State		<= EventMode;
				end if;
				
			when StoreDataInFifo =>
				-- write data to fifo and go back to reading state
				NxR.FifoWrite 	<= '1';
				NxR.State		<= WaitForI2cTransfer;
				
			when EventMode =>
				
				-- data should be always provided with 2Hz (to the streaming fifo)
				NxR.LEDs(1) <= '0';
				if R.EventModeCount = cEventModeFreq-1 then
					NxR.FifoWrite 	<= '1';
					NxR.EventModeCount <= 0;
					NxR.LEDs(1) <= '1';
					NxR.LEDs(2) <= '1';
				else
					NxR.EventModeCount <= R.EventModeCount+1;
				end if;
				
				-- after event mode was handled -> wait for next data 
				NxR.State <= WaitForI2cTransfer;
				
				-- get accelerometer x,y,z values into variables
				AccX := signed(R.FifoData(tFifoRangeAccelerometer_X_H'high downto tFifoRangeAccelerometer_X_L'low));
				AccY := signed(R.FifoData(tFifoRangeAccelerometer_Y_H'high downto tFifoRangeAccelerometer_Y_L'low));
				AccZ := signed(R.FifoData(tFifoRangeAccelerometer_Z_H'high downto tFifoRangeAccelerometer_Z_L'low));
							
				-- event mode
				case (R.EventModeState) is
					
					when Idle =>
						NxR.EventModeState <= FillFifo256;
						
					-- if fifo256 is empty -> wait until its full
					when FillFifo256 =>
						NxR.FifoData256 	<= std_ulogic_vector(signed(R.FifoData(tFifoRangeTimeStamp)) & AccZ & AccY & AccX); -- take data to event fifo 256
						NxR.FifoWrite256	<= '1';
						
						if iFifoFull256 = '1' then
							NxR.LEDs(3) <= '1';
							NxR.EventModeState <= CompareValues;
						end if;
					
					-- now values can be compared with tolearances - new data will still be written to fifo 256
					when CompareValues =>
						NxR.FifoData256 	<= std_ulogic_vector(signed(R.FifoData(tFifoRangeTimeStamp)) & AccZ & AccY & AccX); -- take data to event fifo 256
						NxR.FifoWrite256	<= '1';
						
						if (AccX > XToleranceTop or AccX < XToleranceBottom or
							AccY > YToleranceTop or AccY < YToleranceBottom or
							AccZ > ZToleranceTop or AccZ < ZToleranceBottom ) then
							NxR.LEDs(4) <= '1';
							NxR.EventModeState <= HitDetected;
						end if;
						
					-- now fill fifo 768 
					when HitDetected =>
						NxR.FifoData768 	<= std_ulogic_vector(signed(R.FifoData(tFifoRangeTimeStamp)) & AccZ & AccY & AccX); -- take data to event fifo 768
						NxR.FifoWrite768	<= '1';
						
						if iFifoFull768 = '1' then
							NxR.LEDs(5) <= '1';
							NxR.EventModeState <= Fifo768Full;
						end if;
						
					-- 1024 values are there to read -> assert interrupt
				when Fifo768Full =>
						NxR.LEDs(8) <= '1';
						NxR.EventInterrupt <= '1';
						if R.IrqCount = 9 then
							NxR.EventModeState <= WaitUntilDataIsRead;
							NxR.IrqCount <= 0;
						else
							NxR.IrqCount <= R.IrqCount+1;
						end if;
						
					when WaitUntilDataIsRead =>
						if iFifoEmpty256 = '1' and iFifoEmpty768 = '1' then
							NxR.LEDs(6) <= '1';
							NxR.LEDs(7) <= '1';
							NxR.EventModeState <= Idle;
						end if;					
						
				end case;			
		end case;
		
	
	end process;

	-- outputs
	oFifoData 	<= R.FifoData;
	oFifoWrite	<= R.FifoWrite;
	
	oFifoData256 	<= R.FifoData256;
	oFifoWrite256 	<= R.FifoWrite256;
	oFifoData768 	<= R.FifoData768;
	oFifoWrite768 	<= R.FifoWrite768;
	
	oEventOccured	<= R.EventInterrupt;
	
	oLEDs			<= R.LEDs;
	
	
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
