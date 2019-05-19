-- ------------------------------------------------------------------------------------------
-- Author: Giovani Luigi Rubenich Brondani
-- Copyright (c) 2019: All rights reserved
-- ------------------------------------------------------------------------------------------

library IEEE;

use IEEE.std_logic_1164.all;

entity Mux2to1 is
	generic (
		DataBits		: integer
	);
	port(
		Control		: in  std_logic; -- 1 bit = 2 input
		DataOut		: out std_logic_vector((DataBits-1) downto 0);
		DataIn1		: in  std_logic_vector((DataBits-1) downto 0);
		DataIn2		: in  std_logic_vector((DataBits-1) downto 0)
	);
end Mux2to1;

architecture Behavior of Mux2to1 is
begin
	
	DataOut <= DataIn1 when ( Control='0' ) else DataIn2;
	
end Behavior;
	