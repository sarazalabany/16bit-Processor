----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    15:42:41 05/28/2017 
-- Design Name: 
-- Module Name:    UKM910 - Behavioral 
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

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
LIBRARY UNISIM;
USE UNISIM.Vcomponents.ALL;
entity UKM901 is

			 port (oe				:	OUT	STD_LOGIC; 
					 wren				:	OUT	STD_LOGIc; 
					 res				:	IN		STD_LOGIC; 
					 clk				:	IN		STD_LOGIC;
					 interrupts		:	IN 	STD_LOGIC_VECTOR (7 downto 0);
					 addressbus		:	OUT	STD_LOGIC_VECTOR (11 DOWNTO 0); 
					 databus			:	INOUT	STD_LOGIC_VECTOR (15 DOWNTO 0));

end UKM901;
architecture UKM901_behav of UKM901 is

	
	-- * Registers should be defined in Processor itself.
	-- * ALU should house only ALU related functions. No memory!
	-- * Path MUX will generate all signals that control the path of Buses and
	--	  memory control signals. It will also define the states of procesor.
	-- * Processor it self will control the paths based on signals from Path MUX. Connecting
	--   register and buses to other buses.
	
	--CPU Registers	
	signal acc							:	std_logic_vector	(15 downto 0);			--Accumulator register.
	signal pc		 					:	std_logic_vector	(11 downto 0);			--Program memory address to be accessed.
	signal addr	 						:	std_logic_vector	(11 downto 0);			--Memory address to be accessed.
	signal OPCODE						:	std_logic_vector	(03 downto 0);			--opcode; Initial is 0000.
	signal SP, R0, R1, R2, RS		:	std_logic_vector	(15 downto 0);			--_|  Registers for memory in processor - RS is special register. Extra!
	signal IE, IFLAG, PSW			:	std_logic_vector	(15 downto 0);			-- |  PSW:Flags, IE: interrupt enable, IFLAG: intrpt flags
	--CPU Buses
	signal ALUFunc						:	std_logic_vector	(03 downto 0);			--ALU Function
	signal BUS2,ALUout, RM_Bus		:	std_logic_vector	(15 downto 0);			--
	signal Sel_reg						:	std_logic_vector	(2 downto 0);			--select active CPU register to write to/ Reg MEM to RM_BUS
	signal shiftr						:	std_logic_vector	(2  downto 0);			--rotation shifting enable and flag storage bus.
	signal flags						:	std_logic_vector	(3  downto 0);			--rotation shifting enable and flag storage bus.
	--MUX Selection pins
	signal Sel_Alu_out				:	std_logic_vector	(1 downto 0);			--Not a MUX, Individual enable bits, can select multiple
	signal Sel_addr, Sel_B_src		:	std_logic_vector	(1 downto 0);			--select ALU_B and addressbus source
	signal Sel_DB						:	std_logic;
	signal Sel_reg_src				:	std_logic_vector	(1 downto 0);			--select whether to write flags or ALUout to register
	signal enIFLAG, enGIE, enALU	:	std_logic;
	
	
	signal i_addr						:std_logic_vector 	(11 downto 0);
	signal en_i_addr 					:std_logic;
	signal i_available, IE_Control						:std_logic;
	signal temp1			:	std_logic_vector	(15 downto 0);	
	signal int_high	:	std_logic_vector (15 downto 0) := x"0002";   --IFLAG value
	signal toMux1, toMux2, input1_mux, input2_mux, output_mux : std_logic_vector (15 downto 0);
	signal X_signal			:std_logic := '0';  --select signal for MUX
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------		
--ALU component declaration
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
		
	component MUX1 
		PORT ( input1_mux  				: in  std_logic_vector(15 downto 0);
				 input2_mux				   : in  STD_LOGIC_VECTOR(15 downto 0);
				 sel                    : in 	STD_LOGIC;
				 sel_int                : in 	STD_LOGIC;
				 output_mux             : out STD_LOGIC_VECTOR(15 downto 0));

	end component MUX1;
  ----------------------------------------------------------------	
	component D_flip 
		
	PORT ( 		inp        		:IN STD_LOGIC_VECTOR (15 downto 0);
		         outp 				:OUT STD_LOGIC_VECTOR(15 downto 0);
					clk_int        :IN STD_LOGIC ;
					clr          	:IN STD_LOGIC 
					   ) ;
						
   end component D_flip;
 -------------------------------------------------------------------	
	component ALU
		port (
			A, B                	: in  std_logic_vector(15 downto 0);
			C                   	: out std_logic_vector(15 downto 0);
			ALUFunc             	: in  std_logic_vector(3  downto 0);
			nBit, shiftrot, dir 	: in  std_logic;
			n, z, cout, OV      	: out std_logic);
	end component;
--PathControl Component declaration
	component PathControlMultiplexer
		port	(
			---Mux selection ports
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
		en_i_addr	:out		std_logic);

	end component;
	
	component Interrupt_Controller is
    Port ( interrupts 	: in  	STD_LOGIC_VECTOR (7 downto 0);
           IE 				: in  	STD_LOGIC_VECTOR (15 downto 0);
           IFLAG 			: in  	STD_LOGIC_VECTOR (15 downto 0);
           i_available 	: out  	STD_LOGIC;
           i_addr 		: out  	STD_LOGIC_VECTOR (11 downto 0));
	end component Interrupt_Controller;
	
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--Architecture begining
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
begin
--instantiation of ALU
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	DF_int : D_flip port map(         --interrupt flip flop
				inp	  =>  int_high,
				outp    =>  toMux1,
				clk_int =>	interrupts(0),
				clr	  =>  enIFLAG
				);
				
	DF_ALU : D_flip port map(         --one flip flop connected to ALUout and resets by res signal
				inp	  =>  ALUout,
				outp    =>  toMux2,
				clk_int =>	clk,
				clr	  =>  res
				);	
				
	M1 	 : MUX1 port map(         --to choose which component writes to IFLAG
				input1_mux  =>  toMux1,
				input2_mux  =>  toMux2,
				sel => X_signal , 
				sel_int => IE(7),
				output_mux	  =>  IFLAG
				);
				
	IC1: Interrupt_Controller Port map ( 
			  interrupts 	=> interrupts,
           IE 				=> IE,
           IFLAG 			=>IFLAG,
           i_available 	=>i_available,
           i_addr 		=>i_addr
			);

	ALU1 : ALU port map(
		A				=>	acc,
		B				=>	BUS2,
		C				=>	ALUout,
		ALUFunc		=>	ALUFunc,
		nBit			=>	shiftr(0),
		shiftrot		=>	shiftr(1),
		dir			=>	shiftr(2),
		n				=>	flags(0),
		z				=>	flags(1),
		cout			=>	flags(2),
		OV				=>	flags(3)
	);
		
--instantiation of MUX
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
control1: PathControlMultiplexer port map(
	  Sel_ALU_out	=>	Sel_ALU_out	,		
		Sel_Addr		=>	Sel_Addr	,	
		Sel_B_src	=>	Sel_B_src,	
		Sel_DB		=>	Sel_DB,								
		ALUFunc		=>	ALUFunc,
		oe				=>	oe	,
		wren			=>	wren	,
		shiftr		=>	shiftr,
		Sel_reg		=>	Sel_reg	,								
		Sel_reg_src	=>	Sel_reg_src	,
--		interrupts	=>	interrupts,
		enIFLAG		=>	enIFLAG,
		enGIE			=>	enGIE	,
		enALU			=>	enALU	,
		IE_Control  =>	IE_Control , 
		temp1			=>	temp1	,
		--MUX Inputs
		OPCODE		=>	OPCODE,
		Addr			=>	Addr,
		PSW			=>	PSW,
		clk			=>	clk,
		res			=>	res,
		i_addr		=> i_addr,
		i_available => i_available,
		en_i_addr	=> en_i_addr
		);
	
	
	
	with Sel_addr 	select
		addressbus<=
			PC 				when "00",
			addr 				when "01",				--GET Instruction
RM_Bus(11 downto 0)		when "10",				--LOADI/STOREI
			"------------"	when others;
			
	with Sel_B_src select
		BUS2<=
			x"0"&PC			when "00",				--Increment PC, or save PC to Register Mem (call subroutine?)
			DATAbus 			when "01",				--ADD, SUB, AND, save to ACC.
			x"0"&Addr		when "10",				--BZ, BN, JUMP to move addr to PC - Also CALL?
			RM_Bus			when "11",				--For LOADR command
			x"0000"			when others;
			
	with Sel_DB 	select
		DATAbus<=
					ALUOut	when '1',				--STORE Instr
	"ZZZZZZZZZZZZZZZZ"	when '0',				--All read Instructions
	"ZZZZZZZZZZZZZZZZ"	when others;
	
	with Sel_reg	select			--read from register. select RM_Bus and Sel_reg_src
		RM_Bus<=
			SP when "000",
			R0 when "001",
			R1 when "010",
			R2 when "011",
		  PSW when "100",								--Special register. not accessible with anything except STORER/LOADR
			IE when "101",
		IFLAG when "110",
		   RS when "111",
	 x"0000" when others;
	
	process (clk, res)
	begin
		if res = '1' then
			--Registers to zero
			addr		<=	 x"000";
			PC			<=	 x"000";
			ACC		<= x"0000";
			R0			<=	x"0000";
			R1			<=	x"0000";
			R2			<=	x"0000";
			RS			<=	x"0000";
			SP			<=	x"0000";
			IE			<=	x"0000";
			PSW		<=	x"0000";
			OPCODE	<=	 "0000";
			--Buses to High impedance
			
			flags		<=	"ZZZZ";
			shiftr	<=	"ZZZ";
			ALUout	<=	"ZZZZZZZZZZZZZZZZ";
			BUS2		<=	"ZZZZZZZZZZZZZZZZ";
			RM_Bus	<=	"ZZZZZZZZZZZZZZZZ";
		
		elsif rising_edge(clk) then
		--HANDLES WRITING TO REGISTERS.

--			if Sel_reg_src =	"01" then								--Write to basic registers. should be independent as we may need to write to 
																				--ACC and PSW flags in same cycle.
			
			case Sel_Alu_out is										--Select output register
				when "01" =>											--PC
					PC(11 downto 0)	<= ALUout(11 downto 0);
				when "10" =>											--ACC
					ACC(15 downto 0)	<=	ALUout(15 downto 0);
				when "11" =>											--Instruction Fetch
					OPCODE(3 downto 0)<=	ALUout(15 downto 12);
					addr(11 downto 0)	<=	ALUout(11 downto 0);
				when others =>
					null;
			end case;
			
		
			if Sel_reg_src = "01" then	
				if enALU = '1' then 								--write ALUOUT to 910 specific registers
					Case sel_reg is
						when "000"	=>
							SP				<=	ALUout;
						when "001"	=>
							R0				<=	ALUout;
						when "010"	=>
							R1				<=	ALUout;
						when "011"	=>
							R2				<=	ALUout;
						when "100"	=>
							PSW			<=	ALUout;
						when "101"	=>
							IE(15 downto 0)				<=	ALUout(15 downto 0);
						when "110"	=>    --writing to IFLAG from software
						   X_signal <= '1';
							null;
						when "111"	=>
							RS			<=	ALUout;
						when others	=>
							null;
					end case;
				end if;
					
			elsif Sel_reg_src = "11" then									--write FLAGS to 910 PSW
				PSW(3 downto 0)<=	flags(3 downto 0);
			end if;

			if enGIE = '1' then 
				IE(7)	<=	IE_Control;
			end if;	
			
			if en_i_addr = '1' then
				addr <= i_addr;
			END if;		
			
		end if;
	end process;
	
--	process (clk, interrupts, enIFLAG, temp1, res)						--for changing the IFLAG either by CU or interrupts
--		begin
--		if res = '1' then
--			IFLAG		<=	x"0000";
--		elsif rising_edge(clk) then
--		
--			if enALU = '1' then
--				if Sel_reg_src = "01" then
--					if sel_reg = "110" then
--						IFLAG <= ALUout;
--					end if;
--				end if;
--			end if;
--			
--			if enIFLAG ='1' then
--				IFLAG <= IFLAG and temp1;		--to set the Flag on processed interrut to '0'
--			end if;
--		
--		else
--			
--			if enIFLAG = '0' and res = '0' then
--				IFLAG (7 downto 0) <= IFLAG (7 downto 0) or (interrupts);
--			end if;
--		end if;
--	end process;	

end UKM901_behav;