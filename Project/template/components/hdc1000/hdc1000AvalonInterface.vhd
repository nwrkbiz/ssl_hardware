-- altera vhdl_input_version vhdl_2008
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity hdc1000AvalonInterface is
	port (
		avs_s0_address     			: in  std_logic_vector(7 downto 0)  := (others => '0');
		avs_s0_read        			: in  std_logic                     := '0';
		avs_s0_readdata    			: out std_logic_vector(31 downto 0);
		avs_s0_write       			: in  std_logic                     := '0';
		avs_s0_writedata   			: in  std_logic_vector(31 downto 0) := (others => '0');
		avs_s0_waitrequest 			: out std_logic;
		clk                			: in  std_logic                     := '0';
		reset              			: in  std_logic                     := '0'
	);
end entity hdc1000AvalonInterface;

architecture rtl of hdc1000AvalonInterface is

  signal temp 			: std_logic_vector(15 downto 0);
  signal humidity       : std_logic_vector(15 downto 0);
  signal timestamp      : std_logic_vector(31 downto 0);
  signal frequency      : std_logic_vector(15 downto 0);
  signal config         : std_logic_vector(15 downto 0);

begin
	process(clk, reset, avs_s0_address, avs_s0_writedata, avs_s0_write)
	begin
		if reset = '1' then
        temp 					 <= (others=>'0');
        humidity       <= (others=>'0');
        timestamp      <= (others=>'0');
        frequency      <= (others=>'0');
        config         <= (others=>'0');
        
        temp(7 downto 0)<= "10101010";
        humidity(7 downto 0)<= "01010101";
        timestamp(7 downto 0)<= "11001100";
        
		elsif rising_edge(clk) then
      
			-- Change the dummy values so that the driver can read different stuff
			timestamp <= std_logic_vector(unsigned(timestamp) + 1);
			humidity(3 downto 0) <= timestamp(3 downto 0);
			temp(4 downto 0) <= timestamp(5 downto 1);
	  
				case avs_s0_address(3 downto 0) is

					when X"0" =>
						if avs_s0_read = '1' then
							avs_s0_readdata( 15 downto  0) <= temp;
							avs_s0_readdata( 31 downto  16) <= humidity;                  
						elsif avs_s0_write = '1' then
							--temp <= avs_s0_writedata( 15 downto  0);
							--humidity <= avs_s0_writedata( 31 downto  16);
						end if;
              
					when X"1" =>
						if avs_s0_read = '1' then
							avs_s0_readdata<= timestamp;
						elsif avs_s0_write = '1' then
							--timestamp<= avs_s0_writedata;
						end if;
              
					when X"2" =>
						if avs_s0_write = '1' then
							frequency <= avs_s0_writedata( 15 downto  0);
							config <= avs_s0_writedata( 31 downto  16);
						elsif avs_s0_read = '1' then
							avs_s0_readdata( 15 downto  0) <= frequency;
							avs_s0_readdata( 31 downto  16)<= config;                  
						end if;

					when others =>
							if avs_s0_read = '1' then
								avs_s0_readdata<= X"DEADDA7A"; -- SW accessing dead data
							end if;
				end case;


		end if;

	end process;

	avs_s0_waitrequest <= '0';
end architecture rtl;
