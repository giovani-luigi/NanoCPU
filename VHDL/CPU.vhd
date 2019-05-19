-- ------------------------------------------------------------------------------------------
-- Author: Giovani Luigi Rubenich Brondani
-- Copyright (c) 2019: All rights reserved
-- ------------------------------------------------------------------------------------------

library IEEE;
library work;

use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.math_real.all;
use work.InstructionSet.all;

entity CPU is 
	Port(
		CLK 							: in  std_logic := '0';
		Reset							: in	std_logic := '0';
		AddressBusOut				: out std_logic_vector(7 downto 0) := (others => '0'); -- used to feed the address input of the memory unit
		DataBusIn					: in  std_logic_vector(15 downto 0); -- used to feed the CPU with memory data
		DataBusOut					: out std_logic_vector(15 downto 0) := (others => '0'); -- used to feed the memory with data from the CPU
		MemWrite						: out std_logic := '0';	-- used to tell memory if we need to read/write on it
		RunNext						: in  std_logic := '0'; -- set to 1 to run the next instruction, or 0 to stop after current instruction finishes
		AccOut						: out std_logic_vector(7 downto 0); -- output for watch/debug
		PcOut							: out std_logic_vector(7 downto 0) -- output for watch/debug
	);
end CPU;

architecture Behavior of CPU is

	component ALU is
		port(
			InputA					: in  std_logic_vector(7 downto 0) := "00000000";
			InputB					: in  std_logic_vector(7 downto 0) := "00000000";
			Operation				: in  std_logic_vector(4 downto 0) := "00000";
			Output					: out std_logic_vector(7 downto 0) := "00000000";
			Zero						: out std_logic;
			Carry						: out std_logic;
			Negative					: out std_logic
		);
	end component ALU;

	-- CPU STATES
	type state_type is (
		FETCH_0,  			-- ADD <= PC
		FETCH_1,  			-- IR <= DATA_IN
		DECODE_LITERAL,	-- WHEN (OPERAND_IN_MEMORY) / ADD <= IR.OPERAND / ELSE / OPERAND <= IR.OPERAND
		DECODE_OPERAND,	-- OPERAND <= DATA_IN
		DECODE_ALU_0,		-- ALU.A <= OPERAND / ALU.B <= ACC / ALU.OP <= IR.OPCODE
		DECODE_ALU_1,		-- ACC <= ALU.OUT / PC++
		DECODE_FLOW,		-- PC = NEW PC
		DECODE_STORE_0, 	-- ADD <= OPERAND / DATA_OUT <= ACC / WRITE=1 / PC++
		DECODE_STORE_1 	-- WRITE=0
	);
	-- CURRENT STATE
	signal state 						: state_type	:= FETCH_0;
		
	signal alu_inputA					: std_logic_vector(7 downto 0) := "00000000";
	signal alu_inputB					: std_logic_vector(7 downto 0) := "00000000";
	signal alu_operation				: std_logic_vector(4 downto 0) := "00000";
	signal alu_output					: std_logic_vector(7 downto 0) := "00000000";
	
	-- internal registers
	signal OPERAND						: std_logic_vector(7 downto 0) := "00000000"; -- holds the value of the operand of current instruction
	signal IR							: std_logic_vector(15 downto 0) := (others => '0'); -- Instruction register: holds current 16-bit instruction
	signal ACC							: std_logic_vector(7 downto 0) := "00000000"; -- Accumulator: synchronous output of the ALU
	signal PC							: std_logic_vector(7 downto 0) := "00000000"; -- Program Counter: holds the current adress of the program
	signal cpu_flag_zero				: std_logic;
	signal cpu_flag_negative		: std_logic;
	signal cpu_flag_carry			: std_logic;
	
	-- others
	signal IR_opcode					: std_logic_vector(7 downto 0); -- op-code from the IR
	signal IR_operand					: std_logic_vector(7 downto 0); -- operand from the IR
	
	signal operand_in_memory		: std_logic; -- TRUE when the instruction requires reading the operand from the memory
	signal flow_instruction			: std_logic; -- TRUE when the instruction operation affects the PC directly
	signal alu_instruction			: std_logic; -- TRUE when the instruction requires the ALU to perform data manipulation
	signal store_instruction		: std_logic; -- TRUE when the instruction is a STORE, i.e. move data from ACC to SRAM	

begin

	-- internal logic harnessing:
	operand_in_memory <= '1' when (IR_opcode = OP_ADDR) else
								'1' when	(IR_opcode = OP_SUBR) else
								'1' when	(IR_opcode = OP_ANDR) else
								'1' when	(IR_opcode = OP_IORR) else
								'1' when	(IR_opcode = OP_XORR) else 
								'1' when	(IR_opcode = OP_NOT) else 
								'1' when	(IR_opcode = OP_SET) else 
								'1' when	(IR_opcode = OP_CLR) else 
								'1' when	(IR_opcode = OP_MOVRA) else
								'0';
	
	flow_instruction	<= '1' when (IR_opcode(7 downto 5) = "000") else -- instructions that control flow starts with 000
								'0';
	
	alu_instruction   <= '1' when (IR_opcode(7) = '1') else -- instruction that are ALU data manipulation have 1 on MSB
								'1' when (IR_opcode = OP_MOVLA) else -- we will implement load instruction using ALU because 
								'1' when (IR_opcode = OP_MOVRA) else -- we wont manipulate the ACC directly due to the status flags
								'0';
		
	store_instruction <= '1' when (IR_opcode = OP_MOVAR) else
								'0';

	IR_opcode 	<= IR(15 downto 8); -- wires the opcode to the IR register MSBs
	IR_operand 	<= IR( 7 downto 0); -- wires the operand to the IR register LSBs
	
	AccOut <= ACC;
	PcOut  <= PC;
	
	-- component instances
	MODULE_ALU: ALU
		port map(
			InputA 		=> alu_inputA,
			InputB 		=> alu_inputB,
			Operation 	=> alu_operation,
			Output 		=> alu_output,
			Zero			=> cpu_flag_zero,
			Carry 		=> cpu_flag_carry,
			Negative 	=> cpu_flag_negative
		);

	process (clk) is
	begin
		if (rising_edge(Clk)) then
			if (Reset = '1') then
				state <= FETCH_0;
				alu_inputA <= (others => '0');
				alu_inputB <= (others => '0');
				alu_operation <= (others => '0');
				OPERAND <= (others => '0');
				PC <= (others => '0');
				ACC <= (others => '0');
				IR <= (others => '0');
			else
				case (state) is 
					when FETCH_0 =>  -- we only fetch next instruction if RunNext signal is asserted
						if (RunNext = '1') then
							AddressBusOut <= PC;
							state <= FETCH_1;
						end if;
					when FETCH_1 =>
						IR <= DataBusIn;
						state <= DECODE_LITERAL;
						
					when DECODE_LITERAL => -- prepare the operand
						if (operand_in_memory = '1') then
							AddressBusOut <= IR_operand; -- Get the operand from the memory
							state <= DECODE_OPERAND;
						else
							OPERAND <= IR_operand; -- if the operand is a literal, we then use it directly
							if ( flow_instruction = '1' ) then
								state <= DECODE_FLOW;
							elsif ( alu_instruction = '1') then
								state <= DECODE_ALU_0;
							elsif ( store_instruction = '1' ) then
								state <= DECODE_STORE_0;
							end if;
						end if;
					when DECODE_OPERAND => -- OPERAND <= DATA_IN
						OPERAND <= DataBusIn(7 downto 0); -- lower byte only
						if ( flow_instruction = '1' ) then
							state <= DECODE_FLOW;
						elsif ( alu_instruction = '1') then
							state <= DECODE_ALU_0;
						elsif ( store_instruction = '1' ) then
							state <= DECODE_STORE_0;
						end if;
					
					-- ALU instructions will jump here:
					when DECODE_ALU_0 =>  -- ALU.A <= OPERAND / ALU.B <= ACC / ALU.OP <= IR.OPCODE
						alu_inputA <= OPERAND;
						alu_inputB <= ACC;
						alu_operation <= IR_opcode(4 downto 0);
						state <= DECODE_ALU_1;
					when DECODE_ALU_1 =>  -- ACC <= ALU.OUT / PC++
						ACC <= alu_output;
						PC <= std_logic_vector(unsigned(PC) + 1);
						state <= FETCH_0; -- finished for this instruction
					
					-- Prog. Flow instructions will jump here:
					when DECODE_FLOW => 	-- PC = NEW PC
						if (IR_opcode /= OP_HALT) then -- if its not HALT
							state <= FETCH_0; -- prepare for next instruction
						end if;
						if (IR_opcode = OP_JMP) then
							PC <= OPERAND;
						elsif (IR_opcode = OP_NOP) then
							PC <= std_logic_vector(unsigned(PC) + 1);
						elsif (IR_opcode = OP_JIZ) then 
							-- if last ALU operation is Zero, Jump to $operand, otherswise go to next instruction
							if (cpu_flag_zero = '1') then
								PC <= OPERAND;
							else
								PC <= std_logic_vector(unsigned(PC) + 1);
							end if;
						elsif (IR_opcode = OP_JINZ) then
							-- if last ALU operation is not Zero, Jump to $operand, otherswise go to next instruction
							if (cpu_flag_zero = '0') then
								PC <= OPERAND;
							else
								PC <= std_logic_vector(unsigned(PC) + 1);
							end if;
						elsif (IR_opcode = OP_JIC ) then
							-- if last ALU operation resulted in Carry, Jump to $operand, otherswise go to next instruction
							if (cpu_flag_carry = '1') then
								PC <= OPERAND;
							else
								PC <= std_logic_vector(unsigned(PC) + 1);
							end if;
						elsif (IR_opcode = OP_JINC) then
							-- if last ALU operation did NOT resulted in Carry, Jump to $operand, otherswise go to next instruction
							if (cpu_flag_carry = '0') then
								PC <= OPERAND;
							else
								PC <= std_logic_vector(unsigned(PC) + 1);
							end if;
						end if;
					
					-- Store instructions will jump here:
					when DECODE_STORE_0 => -- ADD <= OPERAND / DATA_OUT <= ACC / WRITE=1 / PC++
						AddressBusOut <= OPERAND;
						DataBusOut <= "00000000" & ACC;
						MemWrite <= '1';
						PC <= std_logic_vector(unsigned(PC) + 1);
						state <= DECODE_STORE_1;
					when DECODE_STORE_1 =>
						MemWrite <= '0';
						state <= FETCH_0; -- finished for this instruction
					when others => 
						state <= FETCH_0;
				end case;
			end if;
		end if;
	end process;
	
end Behavior;