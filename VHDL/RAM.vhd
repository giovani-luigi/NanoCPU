-- ------------------------------------------------------------------------------------------
-- Author: Giovani Luigi Rubenich Brondani
-- Copyright (c) 2019: All rights reserved
-- ------------------------------------------------------------------------------------------

library IEEE;

use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity RAM is
	port(
		Reset						: in 	std_logic := '0';
		Clk						: in  std_logic := '0';
		MemWrite					: in  std_logic := '0';
		DataBusOut				: out std_logic_vector(15 downto 0) := "0000000000000000";
		DataBusIn				: in	std_logic_vector(15 downto 0) := "0000000000000000";
		AddressBus				: in  std_logic_vector(7 downto 0) := "00000000";
		Register_0xFF_Out   	: out std_logic_vector(7 downto 0) := "00000000" -- output used to map address to peripheral
	);
end RAM;

architecture Behavior of RAM is

	TYPE MemoryArray is array (0 to 255) of std_logic_vector(15 downto 0);

	signal Memory : MemoryArray := (
		x"0000", x"0000", x"0000", x"0000", x"0000", x"0000", x"0000", x"0000",  -- 0x00
		x"0000", x"0000", x"0000", x"0000", x"0000", x"0000", x"0000", x"0000",	 -- 0x08
		x"0000", x"0000", x"0000", x"0000", x"0000", x"0000", x"0000", x"0000",	 -- 0x10
		x"0000", x"0000", x"0000", x"0000", x"0000", x"0000", x"0000", x"0000",	 -- 0x18
		x"0000", x"0000", x"0000", x"0000", x"0000", x"0000", x"0000", x"0000",  -- 0x20
		x"0000", x"0000", x"0000", x"0000", x"0000", x"0000", x"0000", x"0000",  -- 0x28
		x"0000", x"0000", x"0000", x"0000", x"0000", x"0000", x"0000", x"0000",  -- 0x30
		x"0000", x"0000", x"0000", x"0000", x"0000", x"0000", x"0000", x"0000",  -- 0x38
		x"0000", x"0000", x"0000", x"0000", x"0000", x"0000", x"0000", x"0000",  -- 0x40
		x"0000", x"0000", x"0000", x"0000", x"0000", x"0000", x"0000", x"0000",  -- 0x48
		x"0000", x"0000", x"0000", x"0000", x"0000", x"0000", x"0000", x"0000",  -- 0x50
		x"0000", x"0000", x"0000", x"0000", x"0000", x"0000", x"0000", x"0000",  -- 0x58
		x"0000", x"0000", x"0000", x"0000", x"0000", x"0000", x"0000", x"0000",  -- 0x60
		x"0000", x"0000", x"0000", x"0000", x"0000", x"0000", x"0000", x"0000",  -- 0x68
		x"0000", x"0000", x"0000", x"0000", x"0000", x"0000", x"0000", x"0000",  -- 0x70
		x"0000", x"0000", x"0000", x"0000", x"0000", x"0000", x"0000", x"0000",  -- 0x78
		x"0000", x"0000", x"0000", x"0000", x"0000", x"0000", x"0000", x"0000",  -- 0x80
		x"0000", x"0000", x"0000", x"0000", x"0000", x"0000", x"0000", x"0000",  -- 0x88
		x"0000", x"0000", x"0000", x"0000", x"0000", x"0000", x"0000", x"0000",  -- 0x90
		x"0000", x"0000", x"0000", x"0000", x"0000", x"0000", x"0000", x"0000",  -- 0x98
		x"0000", x"0000", x"0000", x"0000", x"0000", x"0000", x"0000", x"0000",  -- 0xA0
		x"0000", x"0000", x"0000", x"0000", x"0000", x"0000", x"0000", x"0000",  -- 0xA8
		x"0000", x"0000", x"0000", x"0000", x"0000", x"0000", x"0000", x"0000",  -- 0xB0
		x"0000", x"0000", x"0000", x"0000", x"0000", x"0000", x"0000", x"0000",  -- 0xB8
		x"0000", x"0000", x"0000", x"0000", x"0000", x"0000", x"0000", x"0000",  -- 0xC0
		x"0000", x"0000", x"0000", x"0000", x"0000", x"0000", x"0000", x"0000",  -- 0xC8
		x"0000", x"0000", x"0000", x"0000", x"0000", x"0000", x"0000", x"0000",  -- 0xD0
		x"0000", x"0000", x"0000", x"0000", x"0000", x"0000", x"0000", x"0000",  -- 0xD8
		x"0000", x"0000", x"0000", x"0000", x"0000", x"0000", x"0000", x"0000",  -- 0xE0
		x"0000", x"0000", x"0000", x"0000", x"0000", x"0000", x"0000", x"0000",  -- 0xE8
		x"0000", x"0000", x"0000", x"0000", x"0000", x"0000", x"0000", x"0000",  -- 0xF0
		x"0000", x"0000", x"0000", x"0000", x"0000", x"0000", x"0000", x"0000"   -- 0xF8
		
	);
	
begin
	
	-- Mirror the value of the register on the output
	Register_0xFF_Out <= Memory(255)(7 downto 0);
	
	-- Asynchronous Read process
	process(Reset, MemWrite, AddressBus, DataBusIn) is
	begin
		if (Reset = '1') then
			DataBusOut <= (others => '0');
		else
			if (MemWrite = '1') then
				DataBusOut <= DataBusIn;
			else
				DataBusOut <= Memory(to_integer(unsigned(AddressBus)));
			end if;
		end if;
	end process;
	
	-- Synchoronous Write process
	process(Clk) is
	begin
		if (rising_edge(Clk)) then
			if (MemWrite='1') then
				Memory(to_integer(unsigned(AddressBus))) <= DataBusIn;
			end if;
		end if;
	end process;
	
end Behavior;