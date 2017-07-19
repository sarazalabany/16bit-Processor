----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    17:42:44 01/08/2008 
-- Design Name: 
-- Module Name:    memory_int - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use ieee.std_logic_textio.all;
use std.textio.all;

---- Uncomment the following library declaration if instantiating
---- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity memory_int is
    Port ( clk 	: in  STD_LOGIC;
           addr 	: in  STD_LOGIC_VECTOR (10 downto 0);
           inp 	: in  STD_LOGIC_VECTOR (15 downto 0);
           outp 	: out  STD_LOGIC_VECTOR (15 downto 0);
           wren 	: in  STD_LOGIC);
end memory_int;

architecture Behavioral of memory_int is
	type saveArray is array (0 to (2**addr'length-1)) of std_logic_vector(15 downto 0);
	--signal data : saveArray := (others => "0000000000000000");
	
	signal data : saveArray := ( X"c008",
  X"c016",
  X"c01a",
  X"c01e",
  X"c022",
  X"c023",
  X"c024",
  X"c025",
  X"8032",
  X"b000",
  X"8033",
  X"b005",
  X"8027",
  X"102a",
  X"f013",
  X"1028",
  X"0000",
  X"0000",
  X"c010",
  X"802f",
  X"2028",
  X"a100",
  X"802e",
  X"9031",
  X"9fff",
  X"a200",
  X"802f",
  X"9031",
  X"9fff",
  X"a200",
  X"8030",
  X"9031",
  X"9fff",
  X"a200",
  X"0000",
  X"0000",
  X"0000",
  X"0000",
  X"0000",
  X"0001",
  X"0002",
  X"0003",
  X"0004",
  X"0005",
  X"0006",
  X"0006",
  X"000a",
  X"0014",
  X"001e",
  X"0000",
  X"07ff",
  X"0082",
  X"0002",
  others => X"0000" );
	
begin


mem_ctrl: process(clk)
--		variable init : integer := 0;
--		file inputfile : text open read_mode is "memory.txt";
--		variable inputline : line;
--		variable inputval  : std_logic_vector(15 downto 0);
--		variable address   : integer := 0;
--		
	begin
--	   if init = 0 then                                  --reading from text file is not needed here
--			while not endfile(inputfile) loop
--				readline(inputfile, inputline);
--				hread(inputline, inputval);
--				data(address) <= inputval;
--				address := address+1;
--			end loop;
--			init := 1;

		if rising_edge(clk) then
			if wren = '1' then
				data(conv_integer(unsigned(addr))) <= inp;
				outp <= inp;
			else
				outp <= data(conv_integer(unsigned(addr)));
			end if;
		end if;
	end process mem_ctrl;
end Behavioral;







