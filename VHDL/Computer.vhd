-- ------------------------------------------------------------------------------------------
-- Component Computer: A TOP LEVEL entity of a computer system with RAM memory and CPU.
-- ------------------------------------------------------------------------------------------
-- Author: Giovani Luigi Rubenich Brondani
-- Copyright (c) 2019: All rights reserved
-- ------------------------------------------------------------------------------------------

library IEEE;

use IEEE.std_logic_1164.all;
use IEEE.math_real.all;
use IEEE.numeric_std.all;

entity Computer is

	generic(
		MAIN_CLK				: integer := 50000000;
		BAUD_RATE			: integer := 115200
	);
	
	port (
		ClkInputPin			: in  std_logic;
		ResetPin				: in  std_logic;
		SerialInputPin		: in  std_logic;
		SerialOutputPin   : out std_logic;
		DisplaySegments	: out std_logic_vector(7 downto 0);
		DisplaySelection  : out std_logic_vector(3 downto 0)
	);

end Computer;

architecture Behavior of Computer is

	component RAM is
		port(
			Reset						: in 	std_logic;
			Clk						: in  std_logic;
			MemWrite					: in  std_logic;
			DataBusOut				: out std_logic_vector(15 downto 0);
			DataBusIn				: in 	std_logic_vector(15 downto 0);
			AddressBus				: in  std_logic_vector(7 downto 0);
			Register_0xFF_Out   	: out std_logic_vector(7 downto 0)
		);
	end component RAM;

	component CPU is
		Port(
			Clk 				: in  std_logic := '0';
			Reset				: in	std_logic := '0';
			AddressBusOut	: out std_logic_vector(7 downto 0); -- used to feed the address input of the memory unit
			DataBusIn		: in  std_logic_vector(15 downto 0); -- used to feed the CPU with memory data
			DataBusOut		: out std_logic_vector(15 downto 0); -- used to feed the memory with data from the CPU
			MemWrite			: out std_logic;	-- used to tell memory if we need to read/write on it
			RunNext			: in	std_logic;
			AccOut			: out std_logic_vector(7 downto 0); -- output for watch/debug
			PcOut				: out std_logic_vector(7 downto 0) -- output for watch/debug
		);
	end component CPU;

	component MemoryController is
		port (
			Clk						: in  std_logic;
			Serial_RX_Received	: in  std_logic;
			Serial_RX_Data			: in  std_logic_vector(7 downto 0);
			Serial_TX_Data			: out std_logic_vector(7 downto 0);
			Serial_TX_Enable		: out std_logic;
			Serial_TX_Done			: in  std_logic;
			MemoryAddressBus		: out std_logic_vector(7 downto 0);
			MemoryDataInBus		: out std_logic_vector(15 downto 0);
			MemoryDataOutBus		: in  std_logic_vector(15 downto 0);
			MemoryWrite				: out std_logic;
			CpuAddressBus			: in	std_logic_vector(7 downto 0);
			CpuDataBusOut			: in  std_logic_vector(15 downto 0);
			CpuMemoryWrite			: in  std_logic;
			CpuRunNext				: out std_logic;
			CpuReset					: out std_logic;
			CpuAcc					: in  std_logic_vector(7 downto 0);
			CpuPc						: in  std_logic_vector(7 downto 0)
		);
	end component MemoryController;
	
	component UART_RX is
		generic (
			g_CLKS_PER_BIT 		: integer
		);
		port (
			i_Clk       			: in  std_logic;
			i_RX_Serial 			: in  std_logic;
			o_RX_DV     			: out std_logic;
			o_RX_Byte   			: out std_logic_vector(7 downto 0)
		);
	end component UART_RX;
	
	component UART_TX is
	  generic (
		 g_CLKS_PER_BIT : integer
		 );
	  port (
		 i_Clk       : in  std_logic;
		 i_TX_DV     : in  std_logic;
		 i_TX_Byte   : in  std_logic_vector(7 downto 0);
		 o_TX_Active : out std_logic;
		 o_TX_Serial : out std_logic;
		 o_TX_Done   : out std_logic
		 );
	end component UART_TX;
	
	component Display is
		port(
			Clk			: in  std_logic;
			Reset			: in  std_logic;
			DataInput	: in  std_logic_vector(7 downto 0);
			LedPinVal	: out std_logic_vector(7 downto 0); -- 7 segments/digit
			LedPinSel	: out std_logic_vector(3 downto 0)  -- 4 digits scan
		);
	end component Display;
	
	-- Components signals

	signal ram_data_input		 : std_logic_vector(15 downto 0);
	signal ram_data_output		 : std_logic_vector(15 downto 0);
	signal ram_address_input	 : std_logic_vector(7 downto 0);
	signal ram_write_enable		 : std_logic := '0';
	
	signal cpu_data_input		 : std_logic_vector(15 downto 0);
	signal cpu_data_output		 : std_logic_vector(15 downto 0);
	signal cpu_address_output	 : std_logic_vector(7 downto 0);
	signal cpu_write_enable		 : std_logic := '0';
	signal cpu_run_next			 : std_logic := '0';
	signal cpu_accumulator		 : std_logic_vector(7 downto 0);
	signal cpu_prog_cnt			 : std_logic_vector(7 downto 0);
	signal cpu_reset       :	std_logic := '0';
	
	signal uart_received_byte	 : std_logic_vector(7 downto 0) := "00000000";
	signal uart_received_ready	 : std_logic := '0';
	
	signal uart_transmit_data   : std_logic_vector(7 downto 0) := "00000000";
	signal uart_transmit_enable : std_logic := '0';
	signal uart_transmit_done   : std_logic := '0';
	
	signal display_data_input   : std_logic_vector(7 downto 0);
	
	signal ResetInv				 : std_logic := '0';
	signal MemMap_0xFF_Out 		 : std_logic_vector(7 downto 0) := "00000000";
	signal ctrl_cpu_reset 		 : std_logic := '0'; -- output from memory controller used to force a reset on CPU registers
	
begin

	ENTITY_UART_RX: UART_RX
		generic map( MAIN_CLK / BAUD_RATE )
		port map(
			i_Clk 		=> ClkInputPin, 
			i_RX_Serial => SerialInputPin,
			o_RX_DV 		=> uart_received_ready, 
			o_RX_Byte 	=> uart_received_byte
		);
		
	ENTITY_UART_TX: UART_TX
		generic map( MAIN_CLK / BAUD_RATE )
		port map(
			i_Clk       => ClkInputPin,
			i_TX_DV     => uart_transmit_enable,
			i_TX_Byte   => uart_transmit_data,
			o_TX_Active => open,
			o_TX_Serial => SerialOutputPin,
			o_TX_Done   => uart_transmit_done
		);
		
	ENTITY_CPU: CPU
		port map(
			Clk 				=> ClkInputPin,
			Reset				=> cpu_reset,
			AddressBusOut	=> cpu_address_output,
			DataBusIn		=> cpu_data_input,
			DataBusOut		=> cpu_data_output,
			MemWrite			=> cpu_write_enable,
			RunNext			=> cpu_run_next,
			AccOut			=> cpu_accumulator,
			PcOut				=> cpu_prog_cnt
		);
	
	ENTITY_RAM: RAM
		port map(
			Reset			=> ResetInv,
			Clk			=> ClkInputPin,
			MemWrite		=>	ram_write_enable,
			DataBusOut	=> ram_data_output,
			DataBusIn	=> ram_data_input,
			AddressBus	=> ram_address_input,
			Register_0xFF_Out => MemMap_0xFF_Out
		);
	
	ENTITY_MEM_CONTROLLER: MemoryController
		port map(
			Clk						=> ClkInputPin,
			Serial_RX_Received	=> uart_received_ready,
			Serial_RX_Data			=> uart_received_byte,
			Serial_TX_Data			=> uart_transmit_data,
			Serial_TX_Enable		=> uart_transmit_enable,
			Serial_TX_Done			=> uart_transmit_done,
			MemoryAddressBus		=> ram_address_input,
			MemoryDataInBus		=> ram_data_input,
			MemoryDataOutBus		=> ram_data_output,
			MemoryWrite				=> ram_write_enable,
			CpuAddressBus			=> cpu_address_output,
			CpuDataBusOut			=> cpu_data_output,
			CpuMemoryWrite			=> cpu_write_enable,
			CpuRunNext				=> cpu_run_next,
			CpuReset					=> ctrl_cpu_reset,
			CpuAcc					=> cpu_accumulator,
			CpuPc						=> cpu_prog_cnt
		);
		
	ENTITY_DISPLAY: Display
		port map(
			Clk			=> ClkInputPin,
			Reset			=> ResetInv,
			DataInput	=> MemMap_0xFF_Out,
			LedPinVal	=> DisplaySegments,
			LedPinSel	=> DisplaySelection
		);

	cpu_data_input <= ram_data_output;
	ResetInv <= not ResetPin;
	cpu_reset <= ResetInv or ctrl_cpu_reset;
	
end Behavior;

