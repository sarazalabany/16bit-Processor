----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    14:15:18 07/19/2017 
-- Design Name: 
-- Module Name:    MUX1 - Behavioral 
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

entity MUX1 is
   PORT ( input1_mux  				: in  std_logic_vector(15 downto 0);
			 input2_mux				   : in  STD_LOGIC_VECTOR(15 downto 0);
			 sel                    : in 	STD_LOGIC;
			 sel_int						: in  STD_LOGIC;
			 output_mux             : out STD_LOGIC_VECTOR(15 downto 0));

end MUX1;

architecture Behavioral of MUX1 is

begin

output_mux  <= input1_mux when (sel = '0' and sel_int ='1')
			     else input2_mux when (sel = '1')
			     else x"0000"; 
end Behavioral;

