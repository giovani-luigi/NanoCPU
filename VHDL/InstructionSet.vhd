-- ------------------------------------------------------------------------------------------
-- INSTRUCION SET OF THE CPU
-- ------------------------------------------------------------------------------------------
-- The instruction set contains 21 instructions only, making this CPU a RISC machine.
-- The instructions are classified in the following 3 categories:
-- 	- flow control
-- 	- load/store
-- 	- arithmetic/logic
-- ------------------------------------------------------------------------------------------
-- Author: Giovani Luigi Rubenich Brondani
-- Copyright (c) 2019: All rights reserved
-- ------------------------------------------------------------------------------------------
library IEEE;

use IEEE.std_logic_1164.all;

package InstructionSet is

	-- [000xxxxxx]: Flow control instructions: 
	constant OP_HALT 		: std_logic_vector(7 downto 0) := "11111111"; --  - Stop program execution
	constant OP_NOP 		: std_logic_vector(7 downto 0) := "00000000"; --  - No OPeration
	constant OP_JMP 		: std_logic_vector(7 downto 0) := "00000001"; --  - JuMP
	constant OP_JIZ		: std_logic_vector(7 downto 0) := "00000010"; --  - Jump If Zero (jump to the address $address if ALU flag Zero is set)
	constant OP_JINZ		: std_logic_vector(7 downto 0) := "00000011"; --  - Jump If Not Zero (jump to the address $address if ALU flag Zero is set)
	constant OP_JIC		: std_logic_vector(7 downto 0) := "00000100"; --  - Jump If Carry (jump to the address $address if ALU flag Carry is set)
	constant OP_JINC		: std_logic_vector(7 downto 0) := "00000101"; --  - Jump If Not Carry (jump to the address $address if ALU flag Carry is clear)
	
	-- [001xxxxxx]: Load/Store instructions: 
	constant OP_MOVLA 	: std_logic_vector(7 downto 0) := "00100100"; --  - MOVe Literal to Accumulator
	constant OP_MOVRA 	: std_logic_vector(7 downto 0) := "00100101"; --  - MOVe Register to Accumulator
	constant OP_MOVAR 	: std_logic_vector(7 downto 0) := "00100110"; --  - MOVe Accumulator to Register
	
	-- [100xxxxxx]: Arithmetic/Logic instructions between Literal and Accumulator
	constant OP_NOT 		: std_logic_vector(7 downto 0) := "10001000"; --  - NOT Accumulator (operand literal = bit mask)
	constant OP_SET 		: std_logic_vector(7 downto 0) := "10001001"; --  - SET bits on Accumulator (operand literal  = bit mask)
	constant OP_CLR 		: std_logic_vector(7 downto 0) := "10001010"; --  - CLEAR bits on Accumulator (operand literal  = bit mask)

	constant OP_ADDL 		: std_logic_vector(7 downto 0) := "10001011"; --  - ADDition between Literal and Accumulator
	constant OP_SUBL 		: std_logic_vector(7 downto 0) := "10001100"; --  - SUBtraction between Literal and Accumulator
	constant OP_ANDL 		: std_logic_vector(7 downto 0) := "10001111"; --  - AND (bitwise operation) between Literal and Accumulator
	constant OP_IORL 		: std_logic_vector(7 downto 0) := "10010000"; --  - Inclusive OR (bitwise operation) between Literal and Accumulator
	constant OP_XORL 		: std_logic_vector(7 downto 0) := "10010001"; --  - XOR (bitwise operation) between Literal and Accumulator
	
	-- [111xxxxxx]: Arithmetic/Logic instructions between Register and Accumulator
	constant OP_ADDR 		: std_logic_vector(7 downto 0) := "11101011"; --  - ADDition between Register and Accumulator
	constant OP_SUBR 		: std_logic_vector(7 downto 0) := "11101100"; --  - SUBtraction between Register and Accumulator
	constant OP_ANDR 		: std_logic_vector(7 downto 0) := "11101111"; --  - AND (bitwise operation) between Register and Accumulator
	constant OP_IORR 		: std_logic_vector(7 downto 0) := "11110000"; --  - Inclusive OR (bitwise operation) between Register and Accumulator
	constant OP_XORR 		: std_logic_vector(7 downto 0) := "11110001"; --  - XOR (bitwise operation) between Register and Accumulator
	
end package;

package body InstructionSet is
end package body InstructionSet;