-- ------------------------------------------------------------------------------------------
-- Author: Giovani Luigi Rubenich Brondani
-- Copyright (c) 2019: All rights reserved
-- ------------------------------------------------------------------------------------------

library IEEE;

use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.InstructionSet.all;

entity ComputerTest is
end ComputerTest;

architecture test of ComputerTest is
	
	component Computer is
		generic(
			MAIN_CLK				: integer := 50000000;
			BAUD_RATE			: integer := 57600
		);		
		port (
			ClkInputPin			: in  std_logic;
			ResetPin				: in  std_logic;
			SerialInputPin		: in  std_logic;
			SerialOutputPin   : out std_logic;
			DisplaySegments	: out std_logic_vector(7 downto 0);
			DisplaySelection  : out std_logic_vector(3 downto 0)
		);
	end component Computer;
	
  constant c_MAIN_CLK				: integer := 50000000;
	constant	c_BAUD_RATE			: integer := 57600;
	constant c_CLOCK_T		   : time := 20 ns;
	constant c_BIT_PERIOD 	: time := (c_CLOCK_T * (c_MAIN_CLK / c_BAUD_RATE)); -- Clk = 50MHZ; Clock Per Bit = 50000000 / 57600 = 868; bit period = clock period * 868 = 17360 ns

	constant CMD_RUN_NEXT		: std_logic_vector(7 downto 0) := x"01";	-- generates a pulse for CPU to run next instruction
	constant CMD_WRITE_MEMORY	: std_logic_vector(7 downto 0) := x"02";  -- start a process of programming one word of RAM memory
	constant CMD_READ_MEMORY	: std_logic_vector(7 downto 0) := x"03";  -- request the content of the memory at the specified address
	constant CMD_READ_CPU		: std_logic_vector(7 downto 0) := x"04";  -- request the content of the CPU registers
	constant CMD_RESET_CPU		: std_logic_vector(7 downto 0) := x"05";  -- resets the CPU registers (ACC, PC)
	
	signal Clk					: std_logic := '0';
	signal Reset				: std_logic := '1';
	signal SerialIn			: std_logic := '0';
	signal SerialOut			: std_logic := '0';
	signal DisplaySegments	: std_logic_vector(7 downto 0) := (others => '0');
	signal DisplaySelection : std_logic_vector(3 downto 0) := (others => '0');
	
	-- Byte to UART SERIAL signal serializer
	procedure UART_WRITE_BYTE (
		i_data_in       : in  std_logic_vector(7 downto 0);
		signal o_serial : out std_logic) is
	begin
		-- Send Start Bit
		o_serial <= '0';
		wait for c_BIT_PERIOD;
		-- Send Data Byte
		for ii in 0 to 7 loop
			o_serial <= i_data_in(ii);
			wait for c_BIT_PERIOD;
		end loop;  -- ii
		-- Send Stop Bit
		o_serial <= '1';
		wait for c_BIT_PERIOD;
	end UART_WRITE_BYTE;
	
begin

	MyComputer: Computer
		generic map(c_MAIN_CLK, c_BAUD_RATE)
		port map(
			ClkInputPin => Clk,
			ResetPin => Reset,
			SerialInputPin => SerialIn,
			SerialOutputPin => SerialOut,
			DisplaySegments => DisplaySegments,
			DisplaySelection => DisplaySelection
		);
	
	serial_stimulus: process
	begin

		-- program:
	
		-- address 0x00
		UART_WRITE_BYTE(CMD_WRITE_MEMORY, SerialIn);			-- write memory
		wait for 10 us;
		UART_WRITE_BYTE(x"00", SerialIn);						-- address 000
		wait for 10 us;
		UART_WRITE_BYTE(OP_MOVLA, SerialIn);					-- msb / opcode
		wait for 10 us;
		UART_WRITE_BYTE(x"07", SerialIn);						-- lsb / operand
		wait for 10 us;
		
		-- address 0x01
		UART_WRITE_BYTE(CMD_WRITE_MEMORY, SerialIn);			-- write memory
		wait for 10 us;
		UART_WRITE_BYTE(x"01", SerialIn);						-- address 001
		wait for 10 us;
		UART_WRITE_BYTE(OP_MOVAR, SerialIn);					-- msb / opcode
		wait for 10 us;
		UART_WRITE_BYTE(x"FF", SerialIn);						-- lsb / operand
		wait for 10 us;
		
		-- address 0x02
		UART_WRITE_BYTE(CMD_WRITE_MEMORY, SerialIn);			-- write memory
		wait for 10 us;
		UART_WRITE_BYTE(x"02", SerialIn);						-- address 001
		wait for 10 us;	
		UART_WRITE_BYTE(OP_MOVRA, SerialIn);					-- msb / opcode
		wait for 10 us;
		UART_WRITE_BYTE(x"FF", SerialIn);						-- lsb / operand
		wait for 10 us;

		UART_WRITE_BYTE(CMD_RUN_NEXT, SerialIn);				-- RUN CPU   	MOVLA '7'
		wait for 10 us;
		UART_WRITE_BYTE(CMD_RUN_NEXT, SerialIn);				-- RUN CPU		MOVAR 255
		wait for 10 us;
		UART_WRITE_BYTE(CMD_RUN_NEXT, SerialIn);				-- RUN CPU		MOVRA 255
		wait for 10 us;
		
		UART_WRITE_BYTE(CMD_READ_MEMORY, SerialIn);				-- READ MEMORY
		wait for 10 us;
		UART_WRITE_BYTE(x"FF", SerialIn);				-- ADDRESS 255
		wait for 1 ms;
		UART_WRITE_BYTE(CMD_READ_MEMORY, SerialIn);				-- READ MEMORY
		wait for 10 us;
		UART_WRITE_BYTE(x"FF", SerialIn);				-- ADDRESS 255
						
		wait; -- stall process
		
	end process serial_stimulus;
	
	clk_stimulus: process
	begin
		wait for 10 ns;
		Clk <= not Clk;
		wait for 10 ns;
		Clk <= not Clk;
	end process clk_stimulus;

end test;

