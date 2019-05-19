-- ------------------------------------------------------------------------------------------
-- Author: Giovani Luigi Rubenich Brondani
-- Copyright (c) 2019: All rights reserved
-- ------------------------------------------------------------------------------------------

library IEEE;
library work;

use IEEE.std_logic_1164.all;
use work.InstructionSet.all;

entity CPU_Test is
end;

architecture test of CPU_Test is
	
	component CPU
		port(
			CLK 							: in  std_logic := '0';
			Reset							: in	std_logic := '0';
			AddressBusOut				: out std_logic_vector(7 downto 0); -- used to feed the address input of the memory unit
			DataBusIn					: in  std_logic_vector(15 downto 0); -- used to feed the CPU with memory data
			DataBusOut					: out std_logic_vector(15 downto 0); -- used to feed the memory with data from the CPU
			MemWrite						: out std_logic;	-- used to tell memory if we need to read/write on it
			RunNext						: in  std_logic
		);
	end component CPU;

	signal data_in 		: std_logic_vector(15 downto 0) := (others =>'0');
	signal data_out 		: std_logic_vector(15 downto 0) := (others =>'0');
	signal address_out	: std_logic_vector( 7 downto 0) := (others =>'0');
	signal clk				: std_logic := '0';
	signal reset			: std_logic := '0';
	signal mem_write		: std_logic := '0';
	signal cpu_run_next	: std_logic := '0';
	
begin

	device_to_test: CPU
		port map(
			CLK => clk,
			Reset => reset,
			AddressBusOut => address_out,
			DataBusIn => data_in,
			DataBusOut => data_out,
			MemWrite => mem_write,
			RunNext => cpu_run_next
		);
	
	data_stimulus: process
	begin
		-- PERFORM 2+2
		wait for 90 ns;
		
		data_in <= OP_MOVLA & x"02";
		wait for 100 ns; -- wait execution of instruction
		
		data_in <= OP_ADDL & x"02";
		wait for 100 ns; -- wait execution of instruction
		
		data_in <= OP_MOVAR & x"FF";
		
		wait;
	end process data_stimulus;
	
	run_stimulus: process
	begin
		wait for 100 ns;
		
		cpu_run_next <= '1';
		wait for 10 ns;
		cpu_run_next <= '0';
		
		wait for 100 ns; -- WAIT INSTRUCTION TOP RUN
		
		cpu_run_next <= '1';
		wait for 10 ns;
		cpu_run_next <= '0';
		
		wait for 100 ns; -- WAIT INSTRUCTION TOP RUN
		
		cpu_run_next <= '1';
		wait for 10 ns;
		cpu_run_next <= '0';
		
		wait;
	end process run_stimulus;
	
	reset_stimulus: process
	begin
		wait for 10 ns;
		reset <= '0';
	end process reset_stimulus;
	
	clk_stimulus: process
	begin
		wait for 5 ns;
		clk <= not clk;
	end process clk_stimulus;

end test;