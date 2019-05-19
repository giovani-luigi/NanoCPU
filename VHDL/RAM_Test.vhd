-- ------------------------------------------------------------------------------------------
-- Author: Giovani Luigi Rubenich Brondani
-- Copyright (c) 2019: All rights reserved
-- ------------------------------------------------------------------------------------------

library IEEE;
library work;

use IEEE.std_logic_1164.all;
use work.InstructionSet.all;

entity RAM_Test is
end;

architecture test of RAM_Test is
	
	component RAM
		port(
			Reset				: in 	std_logic := '0';
			Clk				: in  std_logic := '0';
			MemWrite			: in  std_logic := '0';
			DataBusOut		: out std_logic_vector(15 downto 0) := "0000000000000000";
			DataBusIn		: in	std_logic_vector(15 downto 0) := "0000000000000000";
			AddressBus		: in  std_logic_vector(7 downto 0) := "00000000";
      Register_0xFF_Out   	: out std_logic_vector(7 downto 0) := "00000000" -- output used to map address to peripheral
		);
	end component RAM;

	signal reset     	: std_logic := '1';
	signal clk 			: std_logic := '1';
	signal address		: std_logic_vector(7 downto 0) := "00000000";
	signal data_out	: std_logic_vector(15 downto 0) := (others =>'1');
	signal data_in		: std_logic_vector(15 downto 0) := (others =>'0');
	signal mem_write  : std_logic := '0';
	signal reg_out_FF : std_logic_vector(7 downto 0) := "00000000";

begin

	device_to_test: RAM
		port map(
			Reset			=> reset,
			Clk			=> clk,
			MemWrite		=> mem_write,
			DataBusOut	=> data_out,
			DataBusIn	=> data_in,
			AddressBus	=> address,
			Register_0xFF_Out => reg_out_FF
		);
	
	main_stimulus: process
	begin
		wait for 10 ns;
		address <= "00000000";
		wait for 10 ns;
		address <= "00000001";
		data_in <= "0000000000001111";
		mem_write <= '1';
		wait for 10 ns;
		address <= "00000010";
		data_in <= "0000000000000000";
		mem_write <= '0';
		wait for 10 ns;
		address <= "00000001";		
		wait;
	end process main_stimulus;

	
	reset_stimulus: process
	begin
		wait for 5 ns;
		reset <= '0';
		wait;
	end process reset_stimulus;
	
	clk_stimulus: process
	begin
		wait for 5 ns;
		clk <= not clk;
	end process clk_stimulus;

end test;