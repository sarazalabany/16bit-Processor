----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    15:16:25 07/02/2017 
-- Design Name: 
-- Module Name:    Interrupt_Controller - Behavioral 
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

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity Interrupt_Controller is
    Port ( interrupts 	: in  	STD_LOGIC_VECTOR (7 downto 0);
           IE 				: in  	STD_LOGIC_VECTOR (15 downto 0);
           IFLAG 			: in  	STD_LOGIC_VECTOR (15 downto 0);
           i_available 	: out  	STD_LOGIC;
           i_addr 		: out  	STD_LOGIC_VECTOR (11 downto 0));
end Interrupt_Controller;

architecture Behavioral of Interrupt_Controller is

begin

	process (interrupts, IFLAG, IE)
	begin
		if (IE(7) = '1') then
			i_addr <=	x"000";
			if 		(IFLAG(0) = '1') 	then
				i_addr(2 downto 0) <= "001";
			elsif 	(IFLAG(1) = '1') 	then
				i_addr(2 downto 0) <= "010";
			elsif 	(IFLAG(2) = '1') 	then
				i_addr (2 downto 0)<= "011";
			elsif 	(IFLAG(3) = '1') 	then
				i_addr(2 downto 0) <= "100";
			elsif 	(IFLAG(4) = '1') 	then
				i_addr (2 downto 0)<= "101";
			elsif 	(IFLAG(5) = '1') 	then
				i_addr(2 downto 0) <= "110";
			elsif 	(IFLAG(6) = '1') 	then
				i_addr (2 downto 0)<= "111";
			end if;
			
		end if;
		if IE(7) = '1' then
			i_available <= ((IFLAG (6)and IE(6)) or (IFLAG (5)and IE(5)) or (IFLAG (4)and IE(4)) or (IFLAG (3) and IE(3))or (IFLAG (2) and IE(2)) or (IFLAG (1)and IE(1)) or (IFLAG (0)and IE(0)));
		else
			i_available	<= '0';
		end if;
	end process;
	
end Behavioral;