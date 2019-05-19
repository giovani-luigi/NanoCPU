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

entity ALU is
		
	port(
		InputA		: in  std_logic_vector(7 downto 0) := "00000000";
		InputB		: in  std_logic_vector(7 downto 0) := "00000000";
		Operation	: in  std_logic_vector(4 downto 0) := "00000";
		Output		: out std_logic_vector(7 downto 0) := "00000000";
		Zero			: out std_logic := '0';
		Carry			: out std_logic := '0';
		Negative		: out std_logic := '0'
	);
	
end ALU;

architecture Behavior of ALU is

	-- ALU operations
	constant ALU_ADD  : std_logic_vector(4 downto 0) := "01011";
	constant ALU_SUB  : std_logic_vector(4 downto 0) := "01100";
	constant ALU_AND  : std_logic_vector(4 downto 0) := "01111";
	constant ALU_IOR  : std_logic_vector(4 downto 0) := "10000";
	constant ALU_XOR  : std_logic_vector(4 downto 0) := "10001";
	constant ALU_MOVL : std_logic_vector(4 downto 0) := "00100";
	constant ALU_MOVR : std_logic_vector(4 downto 0) := "00101";
	constant ALU_CLR  : std_logic_vector(4 downto 0) := "01010";
	constant ALU_SET  : std_logic_vector(4 downto 0) := "01001";
	constant ALU_NOT  : std_logic_vector(4 downto 0) := "01000";
		
	-- temporary register (9-bit so we can preserve carry)
	signal result 			: std_logic_vector(8 downto 0) := "000000000"; -- 9-bit result of an operation to preserve carry bit
	
begin

	Output <= result(7 downto 0); -- store 8-bits from the result in the output
	
	Zero <= '1' when (result = "000000000") else '0';
	
	-- Carry flag CF represents the 9th bit for 8-bit operands and is defined for ADD and SUB only
	Carry <= result(8) when (Operation = ALU_ADD) else
				result(8) when (Operation = ALU_SUB) else
				'0'; 

	-- Negative flag is indicated by the MSB of the 8-bit result
	Negative <= result(7);
	
	resultProcess: process(InputA, InputB, Operation) is
	begin
		case Operation is
			when ALU_ADD =>
				result <= std_logic_vector(unsigned('0' & InputB) + unsigned('0' & InputA));
			when ALU_SUB =>
				result <= std_logic_vector(unsigned('0' & InputB) - unsigned('0' & InputA));
			when ALU_CLR =>
				result <= '0' & (InputB AND (NOT InputA));
			when ALU_AND =>
				result <= ('0' & InputB) AND ('0' & InputA);
			when ALU_IOR | ALU_SET => -- SET with bitmask == OR
				result <= ('0' & InputB) OR ('0' & InputA);
			when ALU_XOR | ALU_NOT => -- NOT with bitmask == XOR
				result <= ('0' & InputB) XOR ('0' & InputA);
			when ALU_MOVL | ALU_MOVR =>  -- same as MOVR
				result <= ('0' & InputA);
			when others =>
				result <= (others => '0');
		end case;
	end process resultProcess;

end Behavior;