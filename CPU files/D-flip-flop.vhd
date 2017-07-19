----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    13:45:36 07/19/2017 
-- Design Name: 
-- Module Name:    D-flip - Behavioral 
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

entity D_flip is

	PORT ( 		inp        		:IN STD_LOGIC_VECTOR (15 downto 0);
		         outp 				:OUT STD_LOGIC_VECTOR(15 downto 0);
					clk_int        :IN STD_LOGIC ;
					clr          	:IN STD_LOGIC 
					   ) ;
end D_flip;

architecture Behavioral of D_flip is

begin

	process(clk_int,clr)
		begin
		if clr ='1' then   --when enIFLAG=1 then we set IFLAG to 0
			outp<= x"0000";
		elsif rising_edge(clk_int) then --otherwise we have an interrupt 
			outp <= inp;
		end if;
	end process ;
	
end Behavioral;


