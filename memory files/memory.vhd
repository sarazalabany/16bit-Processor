----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    19:05:30 01/08/2008 
-- Design Name: 
-- Module Name:    memory - Behavioral 
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

---- Uncomment the following library declaration if instantiating
---- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity memory is
    Port ( clk : in  STD_LOGIC;
           addr : in  STD_LOGIC_VECTOR (10 downto 0);
           dataIO : inout  STD_LOGIC_VECTOR (15 downto 0);
           wren : in  STD_LOGIC;
           oe : in  STD_LOGIC);
end memory;

architecture Behavioral of memory is

	component memory_int is
		port ( clk  : in  STD_LOGIC;
             addr : in  STD_LOGIC_VECTOR (10 downto 0);
             inp  : in  STD_LOGIC_VECTOR (15 downto 0);
             outp : out  STD_LOGIC_VECTOR (15 downto 0);
             wren : in  STD_LOGIC);
	end component memory_int;
	
	signal outp_int 	: std_logic_vector(15 downto 0);
	signal oe_int 		: std_logic;

begin

	mem : memory_int 
    port map ( clk  => clk,
               addr => addr,
               inp  => dataIO,
               outp => outp_int,
               wren => wren );
					
	oe_reg: process(clk)
	begin
		if rising_edge(clk) then
			oe_int <= oe;
		end if;
	end process oe_reg;

	outp_ctrl: process(oe_int, outp_int)
	begin
	--if rising_edge(clk) then
	
		if oe_int = '1' then
			dataIO <= outp_int;
--			oe_int		<=	'0';
		else
			dataIO <= (others => 'Z');
--		end if;
	end if;
	end process outp_ctrl;

end Behavioral;

