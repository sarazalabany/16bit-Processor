-----------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ALU is

port (
            A, B                : in  std_logic_vector(15 downto 0);
            C                   : out std_logic_vector(15 downto 0);
            ALUFunc             : in  std_logic_vector(3 downto 0);
            nBit, shiftRot, dir : in  std_logic := '0';
            n, z, cout, OV       : out std_logic );


end ALU;

architecture ALU_bhv of ALU is

signal c_temp: std_logic_vector (16 downto 0);
signal c_rot_temp, c_temp2: std_logic_vector (15 downto 0);

begin

process (A, B, ALUFunc)

begin
case  ALUFunc is

   when  "0000" =>
	    c_temp <= ('0' & x"0000") ;
   when  "0001" =>
	
	c_temp <= std_logic_vector(unsigned( '0' & (A)) + unsigned ( '0' & (B)));
	   --C <= std_logic_vector(unsigned(A)+ unsigned(B)); 
   when "0010" =>
	 c_temp <= std_logic_vector(unsigned('0' & (A))+ unsigned('0' & (not(B)))+ ('0' & x"0001"));
	    --C <= std_logic_vector(unsigned(A)+ unsigned(not(B))+x"0001");
   when "0011" => 
	c_temp <= std_logic_vector(unsigned('0' & (B))+ unsigned('0' &(not(A)))+ ('0' & x"0001"));

	    --C <= std_logic_vector(unsigned(B)+ unsigned(not(A))+x"0001");
 ----------------------------
  when  "0100" =>
	    c_temp <= ('0' & A );
   when  "0101" =>
	    c_temp <= ('0' & B); 
   when "0110" =>
	 c_temp <= std_logic_vector(unsigned('0' & A)+ ('0' & x"0001"));
	    --C <= std_logic_vector(unsigned(A)+x"0001");
   when "0111" => 
	    c_temp <= std_logic_vector(unsigned('0' & B)+ ('0' & x"0001"));
		 --C <= std_logic_vector(unsigned(B)+x"0001");
-------------------------------

  when  "1000" =>
	    c_temp <= '0' & (A and B) ;
   when  "1001" =>
	    c_temp <=  '0' & (A or B); 
   when "1010" =>
	    c_temp <= '0' & (A xor B);
   when "1011" => 
	    null;	 
---------------------------------
  when  "1100" =>
	    c_temp <=  ('0' & not A) ;
   when  "1101" =>
	    c_temp <= ('0' & not B); 
   when "1110" =>
	    c_temp <= std_logic_vector(unsigned('0' & not (A)) + ('0' & x"0001") );
   when "1111" => 
	    c_temp <= std_logic_vector(unsigned('0' & not (B)) + ('0' & x"0001" ));
		 when others => null;
end case;		 
 end process;
 -----------------------------------------------------------------
 ---------------------------Checking flags----------------------------------------------
 process (ALUFunc, c_temp, dir, nBit, shiftRot, A, B) 

 begin
  		cout<= '0'; OV <='0';
 C <= c_temp(15 downto 0);

case  ALUFunc is
 ----------------------------------OV Flag test of A+B---------------------------- 
    when "0001" =>
	 
 if A(15)='0' and B(15)= '0' and c_temp(15)='1' then    --2 numbers +, result 
		 OV <= '1';
	else
		 OV <= '0';
	end if; 
------------------------------Carry out check------------------------------------
	if (unsigned(c_temp(15 downto 0)) <unsigned(A)) then   --A+B  or (unsigned(c_temp(15 downto 0)) <unsigned(B))
		 cout <= '1';
	else
		 cout <= '0';
  end if;
 ---------------------------------------------------------------------------------- 
------------------------------Carry out check A+1 ------------------------------------
 when "0110" =>    -- A+1
		if(c_temp(15 downto 0) < A)then --A+1
				 cout <= '1';
			else
				 cout <= '0';
		   end if;
----------------------------------OV Flag test of A+1---------------------------- 		
		if A(15)='0' and c_temp(15)='1' then    --A is +, result -
				 OV <= '1';
			else
				 OV <= '0';
			end if; 

--------------------------------------------------------------------------------------
------------------------------Carry out check B+1 ------------------------------------
	when "0111" =>    --B+1
	  if (c_temp(15 downto 0) < B) then --B+1
			cout <= '1';
		else
			 cout <= '0';
	  end if;
----------------------------------OV Flag test of B+1---------------------------- 		  
	 if B(15)='0' and c_temp(15)='1' then    --B is +, result -
		 OV <= '1';
	  else
		 OV <= '0';
	  end if; 
--------------------------------------------------------------------------------------
------------------------------Carry out check A-B ------------------------------------  
	when  "0010" =>   --A-B
		if (A < B) then
			 cout <= '1';
		else
			 cout <= '0';
		end if; 
----------------------------------OV Flag test of A-B---------------------------- 		
		if (A /= B) then    --A-B 
			if A(15)='1' and B(15)= '1' and c_temp(15)='0' then    --2 numbers -, result +
		 OV <= '1';
		else
		 OV <= '0';
		 end if;
		 end if;
--------------------------------------------------------------------------------------
------------------------------Carry out check B-A ------------------------------------  		
	when "0011" =>   --B-A
		if (B < A) then
			 cout <= '1';
		else
			 cout <= '0';
		end if;
----------------------------------OV Flag test of B-A ---------------------------- 				
	if (A /= B) then    --B-A
		if A(15)='1' and B(15)= '1' and c_temp(15)='0' then    --2 numbers -, result +
		 OV <= '1';
		else
		 OV <= '0';		
		end if;
   end if;
--------------------------------------------------------------------------------------	
when others=>
 cout <= '0';
 OV <='0';

end case;
------------------------------ End of checking OV and carry ----------------------------------


-------------------------------End of overflow flag -----------------------
-- if c_temp(16) = '1' then
-- cout <= '1';
--end if;



------------------------------------------------------------------------
if nBit = '1' then --IF no shift/Rot is requested proceed normally
----------------------------------------------------------------

 
         if shiftrot = '1' then	--if it is 1 then it is rotate
			
				if dir = '1' then		--direction is 1 so it is rotate left
					c_temp2 <= to_stdlogicvector(to_bitvector(c_temp(15 downto 0)) rol 1); 
				else              ----rotate right
					c_temp2 <= to_stdlogicvector(to_bitvector(c_temp(15 downto 0)) ror 1);
				end if;
				
			else
				if dir = '1' then		--shift left
					c_temp2 <= to_stdlogicvector(to_bitvector(c_temp(15 downto 0)) sll 1);
				else                  --shift right
					c_temp2 <= to_stdlogicvector(to_bitvector(c_temp(15 downto 0)) srl 1);
				end if;
				
			end if;--------------------------------------------------------------
else 
c_temp2 <= c_temp(15 downto 0);			
			
--------------------------------------------------------------------- 
end if;
----------------------------------------------------------------------
end process;

Rot_shft_flags:process(c_temp2)
	begin
	
	z <= '0'; n <= '0';
		if c_temp2 = x"0000" then 
			z <= '1';
		end if;

		if c_temp2(15) = '1' then 
			n <= '1';
		end if;


end process Rot_shft_flags;

end ALU_bhv;

-----------------------------------------------------------------------