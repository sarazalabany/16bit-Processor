----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    18:20:57 06/06/2017 
-- Design Name: 
-- Module Name:    PathControlMultiplexer - Behavioral 
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

entity PathControlMultiplexer is
	port	(
		---Mux selection ports - these out control mux inside processor
		Sel_ALU_out	:	out	std_logic_vector (1 downto 0);			--connect ALU DATA out to PC, ACC, SP (3 bit PC, ACC, SP)
		Sel_Addr		:	out	std_logic_vector (1 downto 0);			--select address source PC for fetch or DataBus for LOAD
		Sel_B_src	:	out	std_logic_vector (1 downto 0);			--whether to feed data from memory or PC(for increment in address) to ALU B input
		Sel_DB		:	out	std_logic;										--select whether databus receives from ACC or ZZZZZZZZ...
		ALUFunc		:	out	std_logic_vector	(3 downto 0);
		oe				:	out	std_logic;
		wren			:	out	std_logic;
		shiftr		:	out	std_logic_vector	(2 downto 0);
		Sel_reg		:	out	std_logic_vector (2 downto 0);										--select active CPU register
		Sel_reg_src	:	out	std_logic_vector	(1 downto 0);			--select whether to write flags or ALUout to register
--		interrupts	:	in		std_logic_vector 	(07 downto 0);
		enIFLAG, enGIE, enALU	:out 	std_logic;
		IE_Control  :  out 	std_logic;
		temp1			:	out 		std_logic_vector (15 downto 0);
		--MUX Inputs
		OPCODE		:	in		std_logic_vector	(3 downto 0);
		Addr			:	in		std_logic_vector	(11 downto 0);
		PSW			:	in		std_logic_vector	(15 downto 0);
		clk			:	in 	std_logic;
		res			:	in 	std_logic;
		i_addr		: in		std_logic_vector (11 downto 0);
		i_available : in		std_logic;
		en_i_addr	:out		std_logic
	
	);
end PathControlMultiplexer;

architecture Behavioral of PathControlMultiplexer is


	type State is (FETCH1, FETCH2, STORE, PROC, INIT,						--basic functions, init is reset
						LOAD1, LOAD2,													--Load data MEM=>Acc
						ADD1, ADD2,	SUB1, SUB2,									--Artihmatic functions
						AND1, AND12, NOT1, COMP1,								--Logical Operations
						BN, BZ, NOP, JUMP, ROT1,ROT2, SHF1, SHF2,			--Branching and otehr operations
						LOADI1, LOADI2, STOREI,									--Indirect LOAD/STORE
						LOADR, STORER,
						LOADinc1, LOADinc2, LOADinc3,                   --Indirect LOAD/STORE with increment
						LOADdec1, LOADdec2, LOADdec3,LOADdec4,							--and decrement
						STOREinc1,STOREinc2,
						STOREdec1,STOREdec2, STOREdec3,STOREdec4,
						RET1, RET2, RET3, CALL1, CALL2, CALL3, CALL4,
						INT1, RETI, CALL1i,CALL2i, CALL3i, CALL4i
						);
	
	signal p_state					:	state;													--STATE Machine for processor.
	
	--|--------------------------------------------------------------------------------------------------------|--
	--|-------------------------SEPARATE STATE CHANGE PROCESS FROM STATE WRITE PROCESS-..done------------------|--
	--|----------------------------CREATE A PROCESS SENSITIVE TO THE STATE VARIABLE----..done------------------|--
	--|--------------------------------MAKE THIS PROCESS INSENSITIVE TO P_STATE--------..done------------------|--
	--|--------------------------------------------------------------------------------------------------------|--
begin
--READ OR WRITE TO DATABUS
	states: process (clk, res)
	begin
		if res = '1' then
			p_state	<=	INIT;														--Initialize/Reset
		elsif rising_edge(clk) then
			case p_state is														--Reset state of processor
				when INIT 	=>
					p_state 		<= FETCH1;										--Gets the next Instruction from program memory.
				when FETCH1 	=>
					if i_available ='1' then
						p_state  <= INT1;
					else
						p_state		<= FETCH2;
					end if;
						
				when FETCH2 	=>
					p_state		<= PROC;
				when PROC 	=>														--PROCess the Program line that was read.
					case OPCODE is
						when "0000"	=>
							p_state	<=	NOP;
						when "0001"	=>
							p_state	<=	ADD1;
						when "0010"	=>
							p_state	<=	SUB1;
						when "0011" =>
							p_state	<=	AND1;
						when "0100" =>
							p_state	<=	NOT1;
						when "0101"	=>
							p_state	<=	COMP1;
						when "0110"	=>
							p_state	<=	ROT1;
						when "0111"=>
							p_state	<=	SHF1;
						when "1000"	=>
							p_state	<=	LOAD1;
						when "1001"	=>
							p_state	<=	STORE;
						when "1010"	=>					--check 2/4 more bits to select correct function(see proj description)
							case addr(5 downto 4) is
								when "00"	=>    --#sara:LOADR or RET or RETI share tha same 4,5 bits
									case addr(9 downto 8) is
										when "00"	=>
											p_state	<=	LOADR;
										when "01"	=>
											p_state	<=	RET1;
										when "10"	=>
											p_state	<=	RETI;
										when others	=>
											null;
									end case;	
								when "01"	=>
									p_state	<=	LOADI1;
								when "10"	=>
									p_state	<=	LOADinc1;
								when "11"	=>
									p_state	<=	LOADdec1;
								when others	=>
									null;
							end case;
						when "1011"	=>					--check last 2 more bits to select correct function(see proj description)
							case addr(5 downto 4) is
								when "00"	=>
									p_state	<=	STORER;	
								when "01"	=>
									p_state	<=	STOREI;
								when "10"	=>
									p_state	<=	STOREinc1;
								when "11"	=>
									p_state	<=	STOREdec1;
								when others	=>
									null;
							end case;
						when "1100" =>
							p_state	<=	JUMP;
						when "1101" =>
							p_state	<=	BZ;
						when "1110" =>
							p_state	<=	BN;
						when "1111"	=>
							p_state	<=	CALL1;								
						when others	=>
							p_state	<=	LOAD1;
							null;
					end case;
					
					--Operational states selected based on OPCODE
					------GET DATA TO ACC
				when LOAD1	=>
					p_state		<= LOAD2;
				when LOAD2 	=>
					p_state		<= FETCH1;
					------STORE	from ACC to MEMORY					
				when STORE =>
					p_state		<= FETCH1;
					
					
---------------------------------------------------------------
-----------------------ALU Functions---------------------------
				when ADD1	=>
					p_state		<= ADD2;
				when ADD2	=>
					p_state		<=	FETCH1;
				when SUB1	=>
					p_state		<= SUB2;
				when SUB2	=>
					p_state		<=	FETCH1;
				when AND1	=>
					p_state		<= AND12;
				when AND12	=>
					p_state		<=	FETCH1;
				when NOT1	=>
					p_state		<=	FETCH1;
				when COMP1	=>
					p_state		<=	FETCH1;
				when	ROT1 =>
					p_state		<=	FETCH1;
				when	SHF1 =>
					p_state		<=	FETCH1;
---------------------------------------------------------------
-----------------------CPU Functions --------------------------
				when	BN		=>								--Branch on negative
					p_state	<=	FETCH1;
				when BZ		=>								--Branch on zero
					p_state	<=	FETCH1;
				when JUMP	=>								--Jump
					p_state	<=	FETCH1;
				when NOP		=>								--No operation
					p_state	<=	FETCH1;
				when LOADI1		=>							--LOADI
					p_state	<=	LOADI2;
				when LOADI2		=>								
					p_state	<=	FETCH1;
	
      --------------------#Sara: LOADinc, LOADdec,----------------
		-------------------- STOREinc, STOREdec--------------------		
				when LOADinc1  =>
					p_state	<=	LOADinc2;
				when LOADinc2  =>
					p_state	<=	LOADinc3;
				when LOADinc3  =>
					p_state	<=	FETCH1;	
					
				when LOADdec1  =>
					p_state	<=	LOADdec2; 	
				when LOADdec2  =>
					p_state	<=	LOADdec3; 
				when LOADdec3  =>
					p_state	<=	LOADdec4; 
				when LOADdec4  =>
					p_state	<=	FETCH1; 
					
				when STOREinc1  =>
					p_state	<=	STOREinc2;
				when STOREinc2  =>
					p_state	<=	FETCH1;	
					
				when STOREdec1  =>
					p_state	<=	STOREdec2; 	
				when STOREdec2  =>
					p_state	<=	STOREdec3; 
				when STOREdec3  =>
					p_state	<=	STOREdec4;
				when STOREdec4  =>
					p_state	<=	FETCH1;

				when CALL1  =>
					p_state	<=	CALL2; 	
				when CALL2  =>
					p_state	<=	CALL3; 
				when CALL3  =>
					p_state	<=	CALL4;
				when CALL4  =>
					p_state	<=	JUMP; 	
					
				when RET1  =>
					p_state	<=	RET2; 	
				when RET2  =>
					p_state	<=	RET3; 
				when RET3  =>
					p_state	<=	FETCH1; 						
		-------------------------------------------------			
				when STOREI	=>								--LOADI
					p_state	<=	FETCH1;
				when STORER	=>
					p_state	<=	FETCH1;
				when LOADR	=>
					p_state	<=	FETCH1;
		-------------------------------------------			
				when INT1 =>
					p_state <= CALL1i;
				when CALL1i =>
					p_state <= CALL2i;
				when CALL2i =>
					p_state <= CALL3i;
				when CALL3i =>
					p_state <= CALL4i;
				when CALL4i =>
					p_state <= JUMP;	
				when RETI =>
					p_state <= RET1;
		---------------------------------------------			
				when others =>								--for the sake of completion
					p_state		<=	FETCH1;
					
					
			end case;
		end if;
	end process states;
	
	---------------------------------------------------------------------------------------------------------
	---------------------------------------------------------------------------------------------------------
	--THIS PROCESS DEFINES WHAT HAPPENS IN EACH OF THE STATES. BUT IT DOES NOT CHANGE THE STATES ITSELF. ----
	----------------------------NO STATE CHANGES ANYWHERE IN THIS PROCESS------------------------------------
	--------------------------------------------------------------------------------------------------------
	
	Work: process (p_state, i_addr, PSW, addr)
	begin
			--Defaults. will be applied in each state where no value is assigned
--			enALU 	<=	'0';
--			enGIE		<=	'0';
--			IE_Control<= '0';
			
			case p_state is							--UPDATE COMMENTS
				when INIT 	=>							--TO REFLECT ACTUAL
					oe 			<= '0';				--FUNCTION. AT THE
					wren			<= '0';				--MOMENT, THEY ARE
					ALUFunc		<=	"0000";			--COPIED PASTED MOSTLY
					Sel_Addr		<=	"00";
					Sel_B_src	<=	"--";
					Sel_DB		<= '0';
					Sel_Alu_out	<=	"00";
					ALUFunc		<=	"0000";
					Shiftr		<= "000";
					Sel_reg_src <= "00";
					Sel_reg		<=	"---";
					enIFLAG		<=	'0';
					enGIE			<=	'0';
					enALU			<=	'0';
					IE_control	<=	'0';
					temp1			<= x"FFFF";
					en_i_addr	<=	'0';
					
				when FETCH1 	=>
					oe 			<= '1';
					wren 			<= '0';
					Sel_addr		<=	"00";				--Address from PC
					Sel_DB		<=	'0';				--DB to high ZZZ
					Sel_B_src	<=	"--";				--No B source yet
					Sel_ALU_out	<=	"00";				--ALUOut disconnected
					ALUFunc		<=	"----";			--ALU Doesn't care
					shiftr		<=	"000";			--no shifting/rotation
					Sel_reg_src <= "00";				--do not write to 910 registers
					Sel_reg		<=	"---";
					enIFLAG		<=	'0';
					enGIE			<=	'0';
					enALU			<=	'0';
					IE_control	<=	'0';
					en_i_addr	<=	'0';
					
				when FETCH2 	=>
					oe 			<= '0';				--reading nothing
					wren 			<= '0';				--writing nothing
					Sel_addr		<=	"--";				--no address needed
					Sel_DB		<=	'0';				--DATAbus to High impedance
					Sel_B_src	<=	"01";				--Databus to B in of ALU
					Sel_ALU_out	<=	"11";				--ALU out to OPCODE+Addr
					ALUFunc		<=	"0101";			--ALU outputs B
					shiftr		<=	"000";			--no shift/rot
					Sel_reg_src <= "00";				--do not write to reg
					Sel_reg		<=	"---";
					enIFLAG		<=	'0';
					enGIE			<=	'0';
					enALU			<=	'0';
					IE_control	<=	'0';
					en_i_addr	<=	'0';
					
				when PROC	=>
					oe 			<= '0';				--reading nothing
					wren 			<= '0';				--writing nothing
					Sel_addr		<=	"--";				--no address needed
					Sel_DB		<=	'0';				--DATAbus to High impedance
					Sel_B_src	<=	"00";				--PC to B in of ALU
					Sel_ALU_out	<=	"01";				--ALU out to PC
					ALUFunc		<=	"0111";			--C=B+1 (PC=PC+1)
					shiftr		<=	"000";
					Sel_reg_src <= "00";
					Sel_reg		<=	"---";
					enIFLAG		<=	'0';
					enGIE			<=	'0';
					enALU			<=	'0';
					IE_control	<=	'0';
					en_i_addr	<=	'0';
					
				when LOAD1 	=>
					oe 			<= '1';				--read mem
					wren 			<= '0';				--
					Sel_addr		<=	"01";				--address from addr
					Sel_DB		<=	'0';				--databus High ZZ
					Sel_B_src	<=	"--";				--no B yet
					Sel_ALU_out	<=	"00";				--ALUOut disconnected
					ALUFunc		<=	"----";			--ALU doesn't care
					shiftr		<=	"000";			--no shifting/rotation
					Sel_reg_src <= "00";
					Sel_reg		<=	"---";
					enIFLAG		<=	'0';
					enGIE			<=	'0';
					enALU			<=	'0';
					IE_control	<=	'0';
					en_i_addr	<=	'0';
					
				when LOAD2 	=>
					oe 			<= '0';				--reading nothing
					wren 			<= '0';				--writing nothing
					Sel_addr		<=	"--";				--no address needed
					Sel_DB		<=	'0';				--DATAbus to High impedance
					Sel_B_src	<=	"01";				--Databus to B in of ALU
					Sel_ALU_out	<=	"10";				--ALU out to ACC
					ALUFunc		<=	"0101";			--Outs B
					shiftr		<=	"000";
					Sel_reg_src <= "11";
					Sel_reg		<=	"---";
					enALU 		<= '1';
					enIFLAG		<=	'0';
					enGIE			<=	'0';
					enALU			<=	'0';
					IE_control	<=	'0';
					en_i_addr	<=	'0';

				when ADD1 	=>
					oe 			<= '1';				--read mem
					wren 			<= '0';				--
					Sel_addr		<=	"01";				--address from addr
					Sel_DB		<=	'0';				--databus High ZZ
					Sel_B_src	<=	"--";				--no B yet
					Sel_ALU_out	<=	"00";				--ALUOut disconnected
					ALUFunc		<=	"----";			--ALU doesn't care
					shiftr		<=	"000";			--no shifting/rotation
					Sel_reg_src <= "00";				--no writing to regs
					Sel_reg		<=	"---";
					enIFLAG		<=	'0';
					enGIE			<=	'0';
					enALU			<=	'0';
					IE_control	<=	'0';
					en_i_addr	<=	'0';
					
				when ADD2 	=>
					oe 			<= '0';				--reading nothing
					wren 			<= '0';				--writing nothing
					Sel_addr		<=	"--";				--no address needed
					Sel_DB		<=	'0';				--DATAbus to High impedance
					Sel_B_src	<=	"01";				--Databus to B_in of ALU
					Sel_ALU_out	<=	"10";				--ALU out to ACC
					ALUFunc		<=	"0001";			--C = A + B
					shiftr		<=	"000";			--no shf/rot
					Sel_reg_src <= "11";				--write all 4 FLAGS to PSW
					Sel_reg		<=	"---";
					enALU 		<= '1';
					enIFLAG		<=	'0';
					enGIE			<=	'0';
					IE_control	<=	'0';
					en_i_addr	<=	'0';
					
				when SUB1 	=>
					oe 			<= '1';				--read mem
					wren 			<= '0';				--
					Sel_addr		<=	"01";				--address from addr
					Sel_DB		<=	'0';				--databus High ZZ
					Sel_B_src	<=	"--";				--no B yet
					Sel_ALU_out	<=	"00";				--ALUOut disconnected
					ALUFunc		<=	"----";			--ALU doesn't care
					shiftr		<=	"000";			--no shifting/rotation
					Sel_reg_src <= "00";				--do not write to regs
					Sel_reg		<=	"---";
					enIFLAG		<=	'0';
					enGIE			<=	'0';
					enALU			<=	'0';
					IE_control	<=	'0';
					en_i_addr	<=	'0';
					
				when SUB2 	=>
					oe 			<= '0';				--reading nothing
					wren 			<= '0';				--writing nothing
					Sel_addr		<=	"--";				--no address needed
					Sel_DB		<=	'0';				--DATAbus to High impedance
					Sel_B_src	<=	"01";				--Databus to B_in of ALU
					Sel_ALU_out	<=	"10";				--ALU out to ACC
					ALUFunc		<=	"0010";			--C = A - B
					shiftr		<=	"000";
					Sel_reg_src <= "11";				--Write all FLAGS to PSW
					Sel_reg		<=	"---";
					enALU 		<= '1';
					enIFLAG		<=	'0';
					enGIE			<=	'0';
					IE_control	<=	'0';
					en_i_addr	<=	'0';
					
				when AND1 	=>
					oe 			<= '1';				--read mem
					wren 			<= '0';				--mem write fn disabled
					Sel_addr		<=	"01";				--address from addr
					Sel_DB		<=	'0';				--databus High ZZ
					Sel_B_src	<=	"--";				--no B yet
					Sel_ALU_out	<=	"00";				--ALUOut disconnected
					ALUFunc		<=	"----";			--ALU doesn't care
					shiftr		<=	"000";			--no shifting/rotation
					Sel_reg_src <= "00";				--Do not write to regs
					Sel_reg		<=	"---";
					enIFLAG		<=	'0';
					enGIE			<=	'0';
					enALU			<=	'0';
					IE_control	<=	'0';
					en_i_addr	<=	'0';
					
				when AND12 	=>
					oe 			<= '0';				--reading nothing
					wren 			<= '0';				--
					Sel_addr		<=	"--";				--no address needed
					Sel_DB		<=	'0';				--DATAbus to High impedance
					Sel_B_src	<=	"01";				--Databus to B in of ALU
					Sel_ALU_out	<=	"10";				--ALU out to ACC + (read from mem, WHAT??)
					ALUFunc		<=	"1000";			-- C = A and B 
					shiftr		<=	"000";			--
					Sel_reg_src <= "11";				--Write basic flags
					Sel_reg		<=	"---";
					enALU 		<= '1';
					enIFLAG		<=	'0';
					enGIE			<=	'0';
					IE_control	<=	'0';
					en_i_addr	<=	'0';
					
				when NOT1	=>
					oe 			<= '0';				--reading nothing
					wren 			<= '0';				--writing nothing
					Sel_addr		<=	"--";				--no address needed
					Sel_DB		<=	'0';				--DATAbus to High impedance
					Sel_B_src	<=	"--";				--No B_in needed
					Sel_ALU_out	<=	"10";				--ALU out to ACC
					ALUFunc		<=	"1100";			-- C = not(A)
					shiftr		<=	"000";
					Sel_reg_src <= "11";				--Write basic flags
					Sel_reg		<=	"---";
					enALU 		<= '1';
					enIFLAG		<=	'0';
					enGIE			<=	'0';
					IE_control	<=	'0';
					en_i_addr	<=	'0';
					
				when COMP1	=>
					oe 			<= '0';				--reading nothing
					wren 			<= '0';				--writing nothing
					Sel_addr		<=	"--";				--no address needed
					Sel_DB		<=	'0';				--DATAbus to High impedance
					Sel_B_src	<=	"--";				--no B_in needed
					Sel_ALU_out	<=	"10";				--ALU out to ACC
					ALUFunc		<=	"1110";			-- C = not(A) + 1
					shiftr		<=	"000";
					Sel_reg_src <= "11";				--write all flags
					Sel_reg		<=	"---";
					enALU 		<= '1';
					enIFLAG		<=	'0';
					enGIE			<=	'0';
					IE_control	<=	'0';
					en_i_addr	<=	'0';
					
				when ROT1	=>
					oe 			<= '0';				--reading nothing
					wren 			<= '0';				--writing nothing
					Sel_addr		<=	"--";				--no address needed
					Sel_DB		<=	'0';				--DATAbus to High impedance
					Sel_B_src	<=	"--";				--No B_in needed
					Sel_ALU_out	<=	"10";				--ALU out to ACC
					ALUFunc		<=	"0100";			--ALUout = A
					shiftr		<=	"011";			--Rotate by 1 bit
					Sel_reg_src <= "11";				--write basic flags
					Sel_reg		<=	"---";
					enALU 		<= '1';
					enIFLAG		<=	'0';
					enGIE			<=	'0';
					IE_control	<=	'0';
					en_i_addr	<=	'0';
					
				when SHF1	=>
					oe 			<= '0';				--reading nothing
					wren 			<= '0';				--writing nothing
					Sel_addr		<=	"--";				--no address needed
					Sel_DB		<=	'0';				--DATAbus to High impedance
					Sel_B_src	<=	"--";				--No B_in needed
					Sel_ALU_out	<=	"10";				--ALU out to ACC
					ALUFunc		<=	"0100";			-- C = A
					shiftr		<=	"001";			-- Shift by 1 bit
					Sel_reg_src <= "11";				--write basic flags
					Sel_reg		<=	"---";
					enALU 		<= '1';
					enIFLAG		<=	'0';
					enGIE			<=	'0';
					IE_control	<=	'0';
					en_i_addr	<=	'0';
					
				when STORE	=>
					oe 			<= '0';				--
					wren 			<= '1';				--write enabled
					Sel_addr		<=	"01";				--address from addr
					Sel_DB		<=	'1';				--databus connected to ALUout
					Sel_B_src	<=	"--";				--no B needed.
					Sel_ALU_out	<=	"00";				--ALUOut disconnected from all reg
					ALUFunc		<=	"0100";			--ALU outputs Acc (A input)
					shiftr		<=	"000";			--
					Sel_reg_src <= "00";				--
					Sel_reg		<=	"---";
					enIFLAG		<=	'0';
					enGIE			<=	'0';
					enALU			<=	'0';
					IE_control	<=	'0';
					en_i_addr	<=	'0';

				when JUMP	=>							--PATH: addr>ALU_B>ALUOUT>PC
					oe 			<= '0';				--
					wren 			<= '0';				--
					Sel_addr		<=	"--";				--no address needed
					Sel_DB		<=	'0';				--DATAbus HIGH ZZZ
					Sel_B_src	<=	"10";				-- B from addr.
					Sel_ALU_out	<=	"01";				--ALUOut connected to PC
					ALUFunc		<=	"0101";			--ALU outputs B
					shiftr		<=	"000";
					Sel_reg_src <= "00";
					Sel_reg		<=	"---";
					en_i_addr 	<= '0';				--these bits might cause problems
					enIFLAG		<=	'0';
					enGIE			<=	'0';
					enALU			<=	'0';
					IE_control	<=	'0';
					
				when BZ		=>							--PSW directly accessible in Control MUX.
					oe 			<= '0';				--
					wren 			<= '0';				--
					Sel_addr		<=	"--";				--no address needed
					Sel_DB		<=	'0';				--DATAbus HIGH ZZZ
					Sel_reg		<=	"---";
					
					if PSW (1)	= '1' then			--if zero flag is high
						Sel_ALU_out	<=	"01";				--ALUOut connected to PC
						Sel_B_src	<=	"10";				--B from addr
						ALUFunc		<=	"0101";			--ALU outputs B
					else									--flag not satisfied, do nothing
						Sel_ALU_out	<=	"00";				--do not write ALUout
						Sel_B_src	<=	"--";				--no B
						ALUFunc		<=	"----";			--ALU doesn't care
					end if;
					shiftr		<=	"000";
					Sel_reg_src <= "00";				--do not write to Register memory
					enIFLAG		<=	'0';
					enGIE			<=	'0';
					enALU			<=	'0';
					IE_control	<=	'0';
					en_i_addr	<=	'0';
				when BN		=>
					oe 			<= '0';				--
					wren 			<= '0';				--
					Sel_addr		<=	"--";				--no address needed
					Sel_DB		<=	'0';				--DATAbus HIGH ZZZ
					
					if PSW (0)	= '1' then			--negative flag is high
						Sel_ALU_out	<=	"01";				--ALUOut connected to PC
						Sel_B_src	<=	"10";				-- B from addr.
						ALUFunc		<=	"0101";			--ALU outputs B
					else									--not satisfied? do nothing
						Sel_ALU_out	<=	"00";				--do not write ALUout
						Sel_B_src	<=	"--";				-- B from addr
						ALUFunc		<=	"----";			--ALU doesn't care
					end if;
					shiftr		<=	"000";
					Sel_reg_src <= "00";				--do not write to Register memory
					enIFLAG		<=	'0';
					enGIE			<=	'0';
					enALU			<=	'0';
					IE_control	<=	'0';
					en_i_addr	<=	'0';
					
				when LOADI1 	=>
					oe 			<= '1';				--read mem
					wren 			<= '0';				--
					Sel_addr		<=	"10";				--address from RM_Bus
					Sel_DB		<=	'0';				--databus High ZZ
					Sel_B_src	<=	"--";				--no B yet
					Sel_ALU_out	<=	"00";				--ALUOut disconnected
					ALUFunc		<=	"----";			--ALU doesn't care
					shiftr		<=	"000";			--no shifting/rotation
					Sel_reg_src <= "00";
					Sel_reg		<=	addr( 2 downto 0);
					enALU 		<= '1';
					enIFLAG		<=	'0';
					enGIE			<=	'0';
					IE_control	<=	'0';
					en_i_addr	<=	'0';
					
				when LOADI2 	=>
					oe 			<= '0';				--reading nothing
					wren 			<= '0';				--writing nothing
					Sel_addr		<=	"--";				--no address needed
					Sel_DB		<=	'0';				--DATAbus to High impedance
					Sel_B_src	<=	"01";				--Databus to B in of ALU
					Sel_ALU_out	<=	"10";				--ALU out to ACC
					ALUFunc		<=	"0101";			-- C = B
					shiftr		<=	"000";
					Sel_reg_src <= "11";				--write basic flags
					Sel_reg		<=	"---";
					enALU 		<= '1';
					enIFLAG		<=	'0';
					enGIE			<=	'0';
					IE_control	<=	'0';
					en_i_addr	<=	'0';

				when LOADR 	=>
					oe 			<= '0';				--not reading mem
					wren 			<= '0';				--
					Sel_addr		<=	"--";				--no address
					Sel_DB		<=	'0';				--databus High ZZ
					Sel_B_src	<=	"11";				--B from RM_Bus
					Sel_ALU_out	<=	"10";				--ALU to ACC
					ALUFunc		<=	"0101";			--ALUout = B
					shiftr		<=	"000";			--no shifting/rotation
					Sel_reg_src <= "00";				--not writing to the register
					Sel_reg		<=	addr( 2 downto 0);
					enIFLAG		<=	'0';
					enGIE			<=	'0';
					enALU			<=	'0';
					IE_control	<=	'0';
					en_i_addr	<=	'0';
					
				when STOREI	=>
					oe 			<= '0';				--
					wren 			<= '1';				--write
					Sel_addr		<=	"10";				--address from RM_Bus
					Sel_DB		<=	'1';				--databus connected to ALU
					Sel_B_src	<=	"--";				--no B needed.
					Sel_ALU_out	<=	"00";				--ALUOut disconnected from all reg
					ALUFunc		<=	"0100";			--C = A (Acc)
					shiftr		<=	"000";
					Sel_reg_src <= "00";			 	--nothing 
					Sel_reg		<=	addr(2 downto 0);
					enIFLAG		<=	'0';
					enGIE			<=	'0';
					enALU			<=	'0';
					IE_control	<=	'0';
					en_i_addr	<=	'0';
					
				when STORER	=>							-- get value from ACC and save it to register
					oe 			<= '0';				--
					wren 			<= '0';				--write enabled not needed
					Sel_addr		<=	"--";				--address not needed
					Sel_DB		<=	'0';				--databus disconnected
					Sel_B_src	<=	"--";				--no B needed.
					Sel_ALU_out	<=	"00";				--ALUOut disconnected from all basic reg
					ALUFunc		<=	"0100";			--ALU outputs Acc (A input)
					shiftr		<=	"000";			--
					Sel_reg_src <= "01";				--
					Sel_reg		<=	addr(2 downto 0);
					enALU 		<= '1';
					enIFLAG		<=	'0';
					enGIE			<=	'0';
					IE_control	<=	'0';
					en_i_addr	<=	'0';
					
				when NOP		=>
					oe 			<= '0';				
					wren			<= '0';				
					ALUFunc		<=	"0000";			
					Sel_Addr		<=	"00";
					Sel_B_src	<=	"--";
					Sel_DB		<= '0';
					Sel_Alu_out	<=	"00";
					ALUFunc		<=	"0000";
					Shiftr		<= "000";
					Sel_reg_src <= "00";
					Sel_reg		<=	"---";
					enIFLAG		<=	'0';
					enGIE			<=	'0';
					enALU			<=	'0';
					IE_control	<=	'0';
					en_i_addr	<=	'0';
------------------------------------- LOADinc, LOADdec ---------------------------					
				when LOADinc1=>
					oe 			<= '1';				--read mem
					wren 			<= '0';				--
					Sel_addr		<=	"10";				--address from RM_Bus
					Sel_DB		<=	'0';				--databus High ZZ
					Sel_B_src	<=	"--";				--no B yet
					Sel_ALU_out	<=	"00";				--ALUOut disconnected
					ALUFunc		<=	"----";			--ALU doesn't care
					shiftr		<=	"000";			--no shifting/rotation
					Sel_reg_src <= "00";
					Sel_reg		<=	addr(2 downto 0);
					enIFLAG		<=	'0';
					enGIE			<=	'0';
					enALU			<=	'0';
					IE_control	<=	'0';
					en_i_addr	<=	'0';
					
				when LOADinc2 	=>
					oe 			<= '0';				--reading nothing
					wren 			<= '0';				--writing nothing
					Sel_addr		<=	"--";				--no address needed
					Sel_DB		<=	'0';				--DATAbus to High impedance
					Sel_B_src	<=	"01";				--Databus to B in of ALU
					Sel_ALU_out	<=	"10";				--ALU out to ACC
					ALUFunc		<=	"0101";			-- C = B
					shiftr		<=	"000";
					Sel_reg_src <= "11";				--write basic flags
					Sel_reg		<=	"---";	
					enALU 		<= '1';					
					enIFLAG		<=	'0';
					enGIE			<=	'0';
					IE_control	<=	'0';
					en_i_addr	<=	'0';
					
				when LOADinc3 	=>                --#sara:here we add one to the address and save it 
					oe 			<= '0';				--reading nothing
					wren 			<= '0';				--writing nothing
					Sel_addr		<=	"--";				--
					Sel_DB		<=	'0';				--DATAbus to High impedance
					Sel_B_src	<=	"11";				--#sara:address from RM_Bus 
					Sel_ALU_out	<=	"--";				--ALU out to ACC
					ALUFunc		<=	"0111";			--C = B+1
					shiftr		<=	"000";
					Sel_reg_src <= "01";				--#sara:write ALUOUT to 910 specific registers	
					Sel_reg		<=	addr(2 downto 0);
					enALU 		<= '1';
					enIFLAG		<=	'0';
					enGIE			<=	'0';
					IE_control	<=	'0';
					en_i_addr	<=	'0';
	
				when LOADdec1=>                  --#sara: Here we just add 1 to ACC
					oe 			<= '0';				--read mem
					wren 			<= '0';				--
					Sel_addr		<=	"--";				--#sara: No address yet
					Sel_DB		<=	'0';				--databus High ZZ
					Sel_B_src	<=	"--";				--#sara: this will put 0 on B probably??
					Sel_ALU_out	<=	"10";				--#sara: ALUOut connected to ACC
					ALUFunc		<=	"0111";			--#sara: B+1===> will pass 1 to ACC
					shiftr		<=	"000";			--no shifting/rotation
					Sel_reg_src <= "00";
					Sel_reg		<=	"---";	
					enIFLAG		<=	'0';
					enGIE			<=	'0';
					enALU			<=	'0';
					IE_control	<=	'0';
					en_i_addr	<=	'0';
					
				when LOADdec2 	=>                --#sara:here we sub one from the address and save it in reg 
					oe 			<= '0';				--#sara:Read mem
					wren 			<= '0';				--writing nothing
					Sel_addr		<=	"--";				--
					Sel_DB		<=	'0';				--DATAbus to High impedance
					Sel_B_src	<=	"11";				--#sara:address from RM_Bus 
					Sel_ALU_out	<=	"--";				--ALU out to ACC
					ALUFunc		<=	"0011";			--C = B-A
					shiftr		<=	"000";
					Sel_reg_src <= "01";				--#sara:write ALUOUT to 910 specific registers
					Sel_reg		<=	addr(2 downto 0);
					enALU 		<= '1';
					enIFLAG		<=	'0';
					enGIE			<=	'0';
					IE_control	<=	'0';
					en_i_addr	<=	'0';
					
				when LOADdec3 	=>						--#sara:here we pass the new address to address bus
					oe 			<= '1';				--#sara: Set memory
					wren 			<= '0';				--writing nothing
					Sel_addr		<=	"10";				--#sara: Address from reg
					Sel_DB		<=	'0';				--DATAbus to High impedance
					Sel_B_src	<=	"--";				--Databus to B in of ALU
					Sel_ALU_out	<=	"--";				--ALU out to ACC
					ALUFunc		<=	"----";			--C = B
					shiftr		<=	"000";
					Sel_reg_src <= "00";				--write basic flags	
					Sel_reg		<=	addr(2 downto 0);
					enIFLAG		<=	'0';
					enGIE			<=	'0';
					enALU			<=	'0';
					IE_control	<=	'0';
					en_i_addr	<=	'0';
					
				when LOADdec4 	=>
					oe 			<= '0';				--reading nothing
					wren 			<= '0';				--writing nothing
					Sel_addr		<=	"--";				--no address needed
					Sel_DB		<=	'0';				--DATAbus to High impedance
					Sel_B_src	<=	"01";				--Databus to B in of ALU
					Sel_ALU_out	<=	"10";				--ALU out to ACC
					ALUFunc		<=	"0101";			-- C = B
					shiftr		<=	"000";
					Sel_reg_src <= "11";				--write basic flags
					Sel_reg		<=	"---";	
					enALU 		<= '1';
					enIFLAG		<=	'0';
					enGIE			<=	'0';
					IE_control	<=	'0';
					en_i_addr	<=	'0';
					
---------------------------------STOREinc, STOREdec---------------------------------------------------
				when STOREinc1=>
					oe 			<= '0';				--
					wren 			<= '1';				--write
					Sel_addr		<=	"10";				--address from RM_Bus
					Sel_DB		<=	'1';				--databus connected to ALU
					Sel_B_src	<=	"--";				--no B needed.
					Sel_ALU_out	<=	"00";				--ALUOut disconnected from all reg
					ALUFunc		<=	"0100";			--C = A (Acc)
					shiftr		<=	"000";
					Sel_reg_src <= "00";
					Sel_reg		<=	addr(2 downto 0);
					enIFLAG		<=	'0';
					enGIE			<=	'0';
					enALU			<=	'0';
					IE_control	<=	'0';
					en_i_addr	<=	'0';
					
				when STOREinc2 	=>             	--#sara: increment the address and save in reg
					oe 			<= '0';					--reading nothing
					wren 			<= '0';					--writing nothing
					Sel_addr		<=	"10";					--no address needed
					Sel_DB		<=	'0';					--DATAbus to High impedance
					Sel_B_src	<=	"11";					--Databus to B in of ALU
					Sel_ALU_out	<=	"00";					--ALU out to ACC
					ALUFunc		<=	"0111";				--C = B+1
					shiftr		<=	"000";
					Sel_reg_src <= "01";					--#sara:save to reg	
					Sel_reg		<=	addr(2 downto 0); --To decide which reg to write to
					enALU 		<= '1';
					enIFLAG		<=	'0';
					enGIE			<=	'0';
					IE_control	<=	'0';
					en_i_addr	<=	'0';
				  
				when STOREdec1=>                 --#sara: Here we just convert the address to negative
					oe 			<= '0';				--nothing
					wren 			<= '0';				--
					Sel_addr		<=	"--";				--#sara:address has not been added yet
					Sel_DB		<=	'0';				--databus High ZZ
					Sel_B_src	<=	"11";				--#sara:pass the reg address to ALU
					Sel_ALU_out	<=	"00";				--ALUOut disconnected
					ALUFunc		<=	"1111";			--#sara:(NOT B)+1 to get the negative of address
					shiftr		<=	"000";			--no shifting/rotation
					Sel_reg_src <= "01";				--#sara:sava the negative value of reg into the reg
					Sel_reg		<=	addr(2 downto 0);
					enALU 		<= '1';
					enIFLAG		<=	'0';
					enGIE			<=	'0';
					IE_control	<=	'0';
					en_i_addr	<=	'0';
					
				when STOREdec2 	=>             --#sara:here we add one to negative value 
					oe 			<= '0';				--nothing
					wren 			<= '0';				--
					Sel_addr		<=	"--";				--#sara:address has not been added yet
					Sel_DB		<=	'0';				--databus High ZZ
					Sel_B_src	<=	"11";				--#sara:pass the reg address to ALU
					Sel_ALU_out	<=	"00";				--ALUOut disconnected
					ALUFunc		<=	"0111";			--#sara:B+1 to reduce one from the negative address
					shiftr		<=	"000";			--no shifting/rotation
					Sel_reg_src <= "01";				--#sara:sava the negative value of reg into the reg
					Sel_reg		<=	addr(2 downto 0);
					enALU 		<= '1';
					enIFLAG		<=	'0';
					enGIE			<=	'0';
					IE_control	<=	'0';
					en_i_addr	<=	'0';
					
				when STOREdec3 	=>					--#sara:here we get the final address		
					oe 			<= '0';				--nothing
					wren 			<= '0';				--
					Sel_addr		<=	"--";				--#sara:address has not been added yet
					Sel_DB		<=	'0';				--databus High ZZ
					Sel_B_src	<=	"11";				--#sara:pass the reg address to ALU
					Sel_ALU_out	<=	"00";				--ALUOut disconnected
					ALUFunc		<=	"1111";			--#sara:(NOT B)+1 to get the positive of address
					shiftr		<=	"000";			--no shifting/rotation
					Sel_reg_src <= "01";				--#sara:sava the negative value of reg into the reg
					Sel_reg		<=	addr(2 downto 0);
					enALU 		<= '1';
					enIFLAG		<=	'0';
					enGIE			<=	'0';
					IE_control	<=	'0';
					en_i_addr	<=	'0';
									
				when STOREdec4 	=>					--#sara:pass the address and store		
					oe 			<= '0';				--nothing
					wren 			<= '1';				--
					Sel_addr		<=	"10";				--#sara:address from reg
					Sel_DB		<=	'1';				--databus to ALU
					Sel_B_src	<=	"--";				--nothing
					Sel_ALU_out	<=	"00";				--ALUOut disconnected
					ALUFunc		<=	"0100";			--pass ACC
					shiftr		<=	"000";			--no shifting/rotation
					Sel_reg_src <= "--";				--
					Sel_reg		<=	addr(2 downto 0);
					enIFLAG		<=	'0';
					enGIE			<=	'0';
					IE_control	<=	'0';
					en_i_addr	<=	'0';
					enALU 		<= '0';
				
--------------------------------------------CALL & RET ----------------------------------------------					
				when CALL1 =>                  	--#sara: Here we just convert the address to negative
					oe 			<= '0';				--nothing
					wren 			<= '0';				--
					Sel_addr		<=	"--";				--#sara:address has not been added yet
					Sel_DB		<=	'0';				--databus High ZZ
					Sel_B_src	<=	"11";				--#sara:pass the SP address to ALU
					Sel_ALU_out	<=	"00";				--ALUOut disconnected
					ALUFunc		<=	"1111";			--#sara:(NOT B)+1 to get the negative of address
					shiftr		<=	"000";			--no shifting/rotation
					Sel_reg_src <= "01";				--#sara:save the negative value of reg into the reg
					Sel_reg		<=	"000";			--To set it to SP
					enALU 		<= '1';
					enIFLAG		<= '0';
					enGIE 		<= '0';
					en_i_addr	<=	'0';
					IE_control	<=	'0';
						when CALL2 	=>             		--#sara:here we add one to negative value 
					oe 			<= '0';				--nothing
					wren 			<= '0';				--
					Sel_addr		<=	"--";				--#sara:address has not been added yet
					Sel_DB		<=	'0';				--databus High ZZ
					Sel_B_src	<=	"11";				--#sara:pass the SP address to ALU
					Sel_ALU_out	<=	"00";				--ALUOut disconnected
					ALUFunc		<=	"0111";			--#sara:B+1 to subtract one from the negative address
					shiftr		<=	"000";			--no shifting/rotation
					Sel_reg_src <= "01";				--#sara:save the negative value +1 into the reg
					Sel_reg		<=	"000";			--To set it to SP
					enALU 		<= '1';
					enIFLAG		<=	'0';
					en_i_addr	<=	'0';
					enGIE 		<= '0';
					IE_control	<=	'0';
					
				when CALL3 	=>							--#sara:the final address of SP	= SP-1
					oe 			<= '0';				--nothing
					wren 			<= '0';				--
					Sel_addr		<=	"--";				--#sara:address has not been added yet
					Sel_DB		<=	'0';				--databus High ZZ
					Sel_B_src	<=	"11";				--#sara:pass the reg address to ALU
					Sel_ALU_out	<=	"00";				--ALUOut disconnected
					ALUFunc		<=	"1111";			--#sara:(NOT B)+1 to get the positive of SP
					shiftr		<=	"000";			--no shifting/rotation
					Sel_reg_src <= "01";				--#sara:sava the positive value of reg into the reg
					Sel_reg		<=	"000";			--to set it to SP
					enALU 		<= '1';
					en_i_addr	<=	'0';
					enIFLAG		<=	'0';
					enGIE 		<= '0';
					IE_control	<=	'0';

				when CALL4  =>							--#sara:store the PC in SP
					oe 			<= '0';				--nothing
					wren 			<= '1';				--
					Sel_addr		<=	"10";				--#sara:address from SP
					Sel_DB		<=	'1';				--databus to ALUout= PC
					Sel_B_src	<=	"00";				--#sara:pass the PC to ALU bus
					Sel_ALU_out	<=	"--";				--ALUOut to nothing
					ALUFunc		<=	"0101";			--B=PC
					shiftr		<=	"000";			--no shifting/rotation
					Sel_reg_src <= "00";				--#sara:nothing needed here
					Sel_reg		<=	"000";
					en_i_addr	<=	'0';
					enIFLAG		<=	'0';
					enALU 		<= '1';
					enGIE 		<= '0';
					IE_control	<=	'0';

					
					when CALL1i =>                  	--#sara: Here we just convert the address to negative
					oe 			<= '0';				--nothing
					wren 			<= '0';				--
					Sel_addr		<=	"--";				--#sara:address has not been added yet
					Sel_DB		<=	'0';				--databus High ZZ
					Sel_B_src	<=	"11";				--#sara:pass the SP address to ALU
					Sel_ALU_out	<=	"00";				--ALUOut disconnected
					ALUFunc		<=	"1111";			--#sara:(NOT B)+1 to get the negative of address
					shiftr		<=	"000";			--no shifting/rotation
					Sel_reg_src <= "01";				--#sara:save the negative value of reg into the reg
					Sel_reg		<=	"000";			--To set it to SP
					enALU 		<= '1';
					enIFLAG		<= '1';
					enGIE 		<= '0';
					en_i_addr	<=	'1';
					IE_control	<=	'0';
				
				when CALL2i 	=>             		--#sara:here we add one to negative value 
					oe 			<= '0';				--nothing
					wren 			<= '0';				--
					Sel_addr		<=	"--";				--#sara:address has not been added yet
					Sel_DB		<=	'0';				--databus High ZZ
					Sel_B_src	<=	"11";				--#sara:pass the SP address to ALU
					Sel_ALU_out	<=	"00";				--ALUOut disconnected
					ALUFunc		<=	"0111";			--#sara:B+1 to subtract one from the negative address
					shiftr		<=	"000";			--no shifting/rotation
					Sel_reg_src <= "01";				--#sara:save the negative value +1 into the reg
					Sel_reg		<=	"000";			--To set it to SP
					enALU 		<= '1';
					enIFLAG		<=	'0';
					en_i_addr	<=	'1';
					enGIE 		<= '0';
					IE_control	<=	'0';
					
				when CALL3i 	=>							--#sara:the final address of SP	= SP-1
					oe 			<= '0';				--nothing
					wren 			<= '0';				--
					Sel_addr		<=	"--";				--#sara:address has not been added yet
					Sel_DB		<=	'0';				--databus High ZZ
					Sel_B_src	<=	"11";				--#sara:pass the reg address to ALU
					Sel_ALU_out	<=	"00";				--ALUOut disconnected
					ALUFunc		<=	"1111";			--#sara:(NOT B)+1 to get the positive of SP
					shiftr		<=	"000";			--no shifting/rotation
					Sel_reg_src <= "01";				--#sara:sava the positive value of reg into the reg
					Sel_reg		<=	"000";			--to set it to SP
					enALU 		<= '1';
					en_i_addr	<=	'1';
					enIFLAG		<=	'0';
					enGIE 		<= '0';
					IE_control	<=	'0';

				when CALL4i  =>							--#sara:store the PC in SP
					oe 			<= '0';				--nothing
					wren 			<= '1';				--
					Sel_addr		<=	"10";				--#sara:address from SP
					Sel_DB		<=	'1';				--databus to ALUout= PC
					Sel_B_src	<=	"00";				--#sara:pass the PC to ALU bus
					Sel_ALU_out	<=	"--";				--ALUOut to nothing
					ALUFunc		<=	"0101";			--B=PC
					shiftr		<=	"000";			--no shifting/rotation
					Sel_reg_src <= "00";				--#sara:nothing needed here
					Sel_reg		<=	"000";
					en_i_addr	<=	'1';
					enIFLAG		<=	'0';
					enALU 		<= '1';
					enGIE 		<= '0';
					IE_control	<=	'0';

				----CALL5 is a normal JUMP!	
				
				when RET1 =>
					oe 			<= '1';				--reading PC from memory
					wren 			<= '0';				--writing nothing
					Sel_addr		<=	"10";				--connect to SP
					Sel_DB		<=	'0';				--DATAbus to High impedance
					Sel_B_src	<=	"--";				--nothing
					Sel_ALU_out	<=	"--";				--nothing
					ALUFunc		<=	"----";			--nothing
					shiftr		<=	"000";
					Sel_reg_src <= "--";				--nothing
					Sel_reg		<=	"000";			--choose SP
					en_i_addr	<=	'0';
					enIFLAG		<=	'0';
					enALU 		<= '0';
					enGIE 		<= '0';
					IE_control	<=	'0';
				
				when RET2 =>							--Getting old PC value and saving it to PC		
					oe 			<= '0';				--reading nothing
					wren 			<= '0';				--writing nothing
					Sel_addr		<=	"--";				--nothing
					Sel_DB		<=	'0';				--DATAbus to High impedance
					Sel_B_src	<=	"01";				--Databus to B in of ALU to get PC
					Sel_ALU_out	<=	"01";				--ALU out to PC
					ALUFunc		<=	"0101";			--C = B = PC
					shiftr		<=	"000";
					Sel_reg_src <= "--";				--nothing
					Sel_reg		<=	"---";
					en_i_addr	<=	'0';
					enIFLAG		<=	'0';
					enALU 		<= '0';
					enGIE 		<= '0';
					IE_control	<=	'0';
					
				when RET3 =>
					oe 			<= '0';				--reading nothing
					wren 			<= '0';				--writing nothing
					Sel_addr		<=	"--";				--do not care
					Sel_DB		<=	'0';				--DATAbus to High impedance
					Sel_B_src	<=	"11";				--SP to ALU 
					Sel_ALU_out	<=	"--";				--
					ALUFunc		<=	"0111";			--C = B+1 = SP+1
					shiftr		<=	"000";
					Sel_reg_src <= "01";				--#sara:save to reg	
					Sel_reg		<=	"000";	
					enALU 		<= '1';	
					en_i_addr	<=	'0';
					enIFLAG		<=	'0';
					enALU 		<= '1';
					enGIE 		<= '0';
					IE_control	<=	'0';
					
---------------------------------------------------------------------------------------------	
			when INT1 =>
					IE_Control 	<= '0';				--
	
					oe 			<= '0';				--reading nothing
					wren 			<= '0';				--writing nothing
					Sel_addr		<=	"--";				--do not care
					Sel_DB		<=	'0';				--DATAbus to High impedance
					Sel_B_src	<=	"--";				--SP to ALU 
					Sel_ALU_out	<=	"--";				--
					ALUFunc		<=	"----";			--C = B+1 = SP+1
					shiftr		<=	"---";
					Sel_reg_src <= "--";				--#sara:save to reg	
					Sel_reg		<=	"---";	
					enALU 		<= '0';		
					enGIE			<=	'1';
					enIFLAG		<=	'0';
					en_i_addr	<=	'1';
					
			case i_addr(2 downto 0) is
					when "001" =>
					temp1 <= x"FFFE";
					when "010" =>
					temp1 <= x"FFFD";
					when "011" =>
					temp1 <= x"FFFB";
					when "100" =>
					temp1 <= x"FFF7";
					when "101" =>
					temp1 <= x"FFEF";
					when "110" =>
					temp1 <= x"FFDF";
					when "111" =>
					temp1 <= x"FFBF";
				when others =>
						temp1 <= x"0000";
					end case;
when RETI	=>
			
				oe 			<= '0';				--reading nothing
				wren 			<= '0';				--writing nothing
				Sel_addr		<=	"--";				--do not care
				Sel_DB		<=	'0';				--DATAbus to High impedance
				Sel_B_src	<=	"--";				--SP to ALU 
				Sel_ALU_out	<=	"--";				--
				ALUFunc		<=	"----";			--C = B+1 = SP+1
				shiftr		<=	"---";
				Sel_reg_src <= "--";				--#sara:save to reg	
				Sel_reg		<=	"---";	
				enALU 		<= '0';		
				enGIE			<=	'1';
				enIFLAG		<=	'0';
				en_i_addr	<=	'0';
				IE_Control 	<= '1';
	----------------------------------------------------------------------------------------------				
				    
				when others	=>
					null;
					oe 			<= '0';				--FUNCTION. AT THE
					wren			<= '0';				--MOMENT, THEY ARE
					ALUFunc		<=	"0000";			--COPIED PASTED MOSTLY
					Sel_Addr		<=	"00";
					Sel_B_src	<=	"--";
					Sel_DB		<= '0';
					Sel_Alu_out	<=	"00";
					ALUFunc		<=	"0000";
					Shiftr		<= "000";
					Sel_reg_src <= "00";
					Sel_reg		<=	"---";
					enIFLAG		<=	'0';
					enGIE			<=	'0';
					enALU			<=	'0';
					IE_control	<=	'0';
					temp1			<= x"FFFF";
					en_i_addr	<=	'0';
			end case;
	end process Work;
end Behavioral;

