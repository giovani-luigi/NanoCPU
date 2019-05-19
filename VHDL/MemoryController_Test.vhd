-- ------------------------------------------------------------------------------------------
-- Author: Giovani Luigi Rubenich Brondani
-- Copyright (c) 2019: All rights reserved
-- ------------------------------------------------------------------------------------------

library IEEE;

use IEEE.std_logic_1164.all;

entity MemoryController_Test is
end MemoryController_Test;

architecture Test of MemoryController_Test is

	constant CMD_RUN_NEXT		: std_logic_vector(7 downto 0) := x"01";	-- generates a pulse for CPU to run next instruction
	constant CMD_WRITE_MEMORY	: std_logic_vector(7 downto 0) := x"02";  -- start a process of programming one word of RAM memory
	constant CMD_READ_MEMORY	: std_logic_vector(7 downto 0) := x"03";  -- request the content of the memory at the specified address

	component MemoryController
		port (
			Clk						: in  std_logic;
			Serial_RX_Received	: in  std_logic;
			Serial_RX_Data			: in  std_logic_vector(7 downto 0);
			Serial_TX_Data			: out std_logic_vector(7 downto 0);
			Serial_TX_Enable		: out std_logic;
			Serial_TX_Done			: in  std_logic;
			MemoryAddressBus		: out std_logic_vector(7 downto 0);
			MemoryDataInBus		: out std_logic_vector(15 downto 0);
			MemoryDataOutBus		: in 	std_logic_vector(15 downto 0);
			MemoryWrite				: out std_logic;
			CpuAddressBus			: in	std_logic_vector(7 downto 0);
			CpuDataBusOut			: in  std_logic_vector(15 downto 0);
			CpuMemoryWrite			: in  std_logic;
			CpuRunNext				: out std_logic
		);	
	end component MemoryController;

	signal clk 					: std_logic := '0';
	signal rx_received 		: std_logic := '0';
	signal rx_data				: std_logic_vector(7 downto 0) := (others => '0');
	signal tx_data				: std_logic_vector(7 downto 0) := (others => '0');
	signal tx_enable			: std_logic := '0';
	signal tx_done				: std_logic := '0';
	signal mem_address		: std_logic_vector(7 downto 0) := (others => '0');
	signal mem_data_input	: std_logic_vector(15 downto 0) := (others => '0');
	signal mem_write			: std_logic := '0';
	signal mem_data_out		: std_logic_vector(15 downto 0) := (others => '0');
	signal cpu_address		: std_logic_vector(7 downto 0) := (others => '0');
	signal cpu_data			: std_logic_vector(15 downto 0) := (others => '0');
	signal cpu_run_next		: std_logic :='0';
	signal cpu_mem_write		: std_logic := '0';
	
begin

	MEMCTRL: MemoryController
		port map(
			clk => clk,
			Serial_RX_Received => rx_received,
			Serial_RX_Data => rx_data,
			Serial_TX_Data => tx_data,
			Serial_TX_Enable => tx_enable,
			Serial_TX_Done => tx_done,
			MemoryAddressBus => mem_address,
			MemoryDataInBus => mem_data_input,
			MemoryDataOutBus => mem_data_out,
			MemoryWrite => mem_write,
			CpuAddressBus => cpu_address,
			CpuDataBusOut => cpu_data,
			CpuMemoryWrite => cpu_mem_write,
			CpuRunNext => cpu_run_next
		);

	uart_rx_test: process
	begin
	

		wait for 20 ns;
		
		rx_data <= CMD_RUN_NEXT;
		rx_received <= '1';
		wait for 10 ns;
		rx_received <= '0';
		
		wait;		
		
	end process uart_rx_test;

	clock_stimulus: process
	begin
		wait for 5 ns;
		clk <= not clk;		
	end process clock_stimulus;

end Test;