-- ------------------------------------------------------------------------------------------
-- Author: Giovani Luigi Rubenich Brondani
-- Copyright (c) 2019: All rights reserved
-- ------------------------------------------------------------------------------------------

library IEEE;

use IEEE.std_logic_1164.all;

entity MemoryController is
	port (
		Clk						: in  std_logic;
		Serial_RX_Received	: in  std_logic;
		Serial_RX_Data			: in  std_logic_vector(7 downto 0);
		Serial_TX_Data			: out std_logic_vector(7 downto 0) := (others => '0');
		Serial_TX_Enable		: out std_logic := '0';
		Serial_TX_Done			: in  std_logic;
		MemoryAddressBus		: out std_logic_vector(7 downto 0) := (others => '0');
		MemoryDataInBus		: out std_logic_vector(15 downto 0) := (others => '0');
		MemoryDataOutBus		: in 	std_logic_vector(15 downto 0);
		MemoryWrite				: out std_logic := '0';
		CpuAddressBus			: in	std_logic_vector(7 downto 0);
		CpuDataBusOut			: in  std_logic_vector(15 downto 0);
		CpuMemoryWrite			: in  std_logic;
		CpuRunNext				: out std_logic := '0';
		CpuReset					: out std_logic := '0';
		CpuAcc					: in  std_logic_vector(7 downto 0);
		CpuPc						: in  std_logic_vector(7 downto 0)
	);
end MemoryController;

architecture Behavior of MemoryController is

	-- CONTROLLER STATES
	type state_type is (
		S_IDLE,					-- no reception is in progress.
		S_MEM_WRITE_BYTE1,	-- byte 1 to be used in programming the memory
		S_MEM_WRITE_BYTE2,	-- byte 2 to be used in programming the memory
		S_MEM_WRITE_BYTE3,	-- byte 3 to be used in programming the memory
		S_MEM_READ_BYTE1,		-- byte 1 to be used in reading the memory
		S_PROGRAMMING_0, 		-- we are waiting RAM memory to be written (phase 0)
		S_PROGRAMMING_1, 		-- we are waiting RAM memory to be written (phase 1)
		S_PROGRAMMING_2, 		-- we are waiting RAM memory to be written (phase 2)
		S_READING_MEMORY_0,	-- we are waiting RAM memory to be read (phase 0)
		S_READING_MEMORY_1,	-- we are waiting RAM memory to be read (phase 1)
		S_READING_MEMORY_2,	-- we are waiting RAM memory to be read (phase 2)
		S_SEND_MEM_DATA, 		-- send the data read from SRAM to the device connected to the serial port
		S_SEND_CPU_DATA,		-- send the data read from CPU registers to the device connected to the serial port
		S_RESET_CPU_0,			-- reset registers from the CPU
		S_RESET_CPU_1,			-- wait until CPU is reset, then ACK
		S_SEND_ACK,				-- sending ACK
		S_WAIT_SENDING,		-- we are waiting the packet to be sent 
		S_RUNNING				-- cpu Run is being kept high for 1 cycle
	);
	
	-- states used when transmitting a byte to the computer using the serial port
	type tx_state_type is (  
		S_IDLE,				
		S_SENDING_BYTE_1, 	-- put the byte 1 and transmit
		S_WAITING_BYTE_1, 	-- wait transmitter to raise 'done' signal
		S_SENDING_BYTE_2, 	-- put the byte 2 and transmit
		S_WAITING_BYTE_2, 	-- wait transmitter to raise 'done' signal
		S_SENDING_BYTE_3, 	-- put the byte 3 and transmit
		S_WAITING_BYTE_3, 	-- wait transmitter to raise 'done' signal
		S_SENDING_BYTE_4, 	-- put the byte 4 and transmit
		S_WAITING_BYTE_4  	-- wait transmitter to raise 'done' signal
	);
	
	component Mux2to1 is
		generic (
			DataBits			: integer
		);
		port(
			Control			: in  std_logic;
			DataOut			: out std_logic_vector((DataBits-1) downto 0);
			DataIn1			: in  std_logic_vector((DataBits-1) downto 0);
			DataIn2			: in  std_logic_vector((DataBits-1) downto 0)
		);
	end component Mux2to1;

	-- Serial port commands
	
	constant CMD_RUN_NEXT		: std_logic_vector(7 downto 0) := x"01";	-- generates a pulse for CPU to run next instruction
	constant CMD_WRITE_MEMORY	: std_logic_vector(7 downto 0) := x"02";  -- start a process of programming one word of RAM memory
	constant CMD_READ_MEMORY	: std_logic_vector(7 downto 0) := x"03";  -- request the content of the memory at the specified address
	constant CMD_READ_CPU		: std_logic_vector(7 downto 0) := x"04";  -- request the content of the CPU registers
	constant CMD_RESET_CPU		: std_logic_vector(7 downto 0) := x"05";  -- resets the CPU registers (ACC, PC)
	constant CMD_ACK				: std_logic_vector(7 downto 0) := x"FF";  -- command acknowledgement. Introduced so the host won't overrun the serial port
	
	-- registers and local signals
	
	signal rx_byte_1				: std_logic_vector(7 downto 0) := (others => '0'); -- UART RX Buffer 1
	signal rx_byte_2				: std_logic_vector(7 downto 0) := (others => '0'); -- UART RX Buffer 2
	signal rx_byte_3				: std_logic_vector(7 downto 0) := (others => '0'); -- UART RX Buffer 3
	
	signal tx_byte_1				: std_logic_vector(7 downto 0) := (others => '0'); -- UART TX Buffer 1
	signal tx_byte_2				: std_logic_vector(7 downto 0) := (others => '0'); -- UART TX Buffer 2
	
	signal mux_data_control 	: std_logic	:= '0';
	signal mux_address_control : std_logic	:= '0';
	signal mux_write_control 	: std_logic := '0';
	
	signal mux_address_input2	: std_logic_vector(7 downto 0);
	signal mux_data_input2		: std_logic_vector(15 downto 0);
	signal mux_write_input2		: std_logic;
	
	signal state 					: state_type := S_IDLE;
	
	signal tx_state				: tx_state_type := S_IDLE;
	signal send_packet			: std_logic := '0'; -- used to start a transmission of a packet through the serial port
	signal packet_sent			: std_logic := '0'; -- used to alert when a packet transmission finished
	signal packet_byte1			: std_logic_vector(7 downto 0) := (others => '0'); -- buffer register of byte 1 to send
	signal packet_byte2			: std_logic_vector(7 downto 0) := (others => '0'); -- buffer register of byte 2 to send
	signal packet_byte3			: std_logic_vector(7 downto 0) := (others => '0'); -- buffer register of byte 3 to send
	signal packet_byte4			: std_logic_vector(7 downto 0) := (others => '0'); -- buffer register of byte 4 to send
	
begin

	-- mux: route RAM memory DATA INPUT from CPU or from PROGRAMMING interface
	RAM_DATA_MUX: Mux2to1 
		generic map(16)
		port map(
			Control => mux_data_control,
			DataOut => MemoryDataInBus,
			DataIn1 => CpuDataBusOut,
			DataIn2 => mux_data_input2
		);
	
	-- mux: route RAM memory ADDRESS INPUT from CPU (ctrl='0') or from PROGRAMMING (ctrl='1') interface
	RAM_ADDRESS_MUX: Mux2to1
		generic map (8)
		port map(
			Control => mux_address_control,
			DataOut => MemoryAddressBus,
			DataIn1 => CpuAddressBus,
			DataIn2 => mux_address_input2
		);
	
	-- mux: route RAM memory WRITE ENABLE INPUT from CPU (ctrl='0') or from PROGRAMMING (ctrl='1') interface
	RAM_WRITE_MUX: Mux2to1
		generic map (1)
		port map(
			Control => mux_write_control,
			DataOut(0) => MemoryWrite,
			DataIn1(0) => CpuMemoryWrite,
			DataIn2(0) => mux_write_input2
		);
	
	-- process to send 4 bytes to the serial port
	PacketSender: process(Clk)
	begin
		if rising_edge(Clk) then
			case (tx_state) is
				when S_IDLE =>
					packet_sent <= '0';
					if (send_packet = '1') then
						tx_state <= S_SENDING_BYTE_1;
					end if;
				when S_SENDING_BYTE_1 =>
					Serial_TX_Data <= packet_byte1;
					Serial_TX_Enable <= '1';
					tx_state <= S_WAITING_BYTE_1;
				when S_WAITING_BYTE_1 =>
					Serial_TX_Enable <= '0';
					if (Serial_TX_Done = '1') then
						tx_state <= S_SENDING_BYTE_2;
					end if;
				when S_SENDING_BYTE_2 =>
					Serial_TX_Data <= packet_byte2;
					Serial_TX_Enable <= '1';
					tx_state <= S_WAITING_BYTE_2;
				when S_WAITING_BYTE_2 =>
					Serial_TX_Enable <= '0';
					if (Serial_TX_Done = '1') then
						tx_state <= S_SENDING_BYTE_3;
					end if;
				when S_SENDING_BYTE_3 =>
					Serial_TX_Data <= packet_byte3;
					Serial_TX_Enable <= '1';
					tx_state <= S_WAITING_BYTE_3;
				when S_WAITING_BYTE_3 =>
					Serial_TX_Enable <= '0';
					if (Serial_TX_Done = '1') then
						tx_state <= S_SENDING_BYTE_4;
					end if;
				when S_SENDING_BYTE_4 =>
					Serial_TX_Data <= packet_byte4;
					Serial_TX_Enable <= '1';
					tx_state <= S_WAITING_BYTE_4;
				when S_WAITING_BYTE_4 =>
					Serial_TX_Enable <= '0';
					if (Serial_TX_Done = '1') then
						packet_sent <= '1';
						tx_state <= S_IDLE;
					end if;
			end case;
		end if;
	end process PacketSender;
		
	StateMachine: process(Clk)
	begin	
		if (rising_edge(Clk)) then 
		
			case (state) is
				when S_RUNNING => -- pulse CPU 1 cycle and ACK message
					CpuRunNext <= '0';
					state <= S_SEND_ACK;
				when S_IDLE =>
					if (Serial_RX_Received = '1') then 
						case (Serial_RX_Data) is
							when CMD_RUN_NEXT =>  				-- action = runs next instructions; reply = ACK 
								CpuRunNext <= '1'; 				-- pulse CPU RUN pin
								state <= S_RUNNING;
							when CMD_WRITE_MEMORY => 			-- action = write a word to SRAM; reply = ACK
								state <= S_MEM_WRITE_BYTE1;
							when CMD_READ_MEMORY =>				-- action = read a word from SRAM; reply = word read
								state <= S_MEM_READ_BYTE1;
							when CMD_RESET_CPU =>				-- action = resets CPU registers; reply = ACK
							   state <= S_RESET_CPU_0;
							when CMD_READ_CPU =>					-- action = read CPU registers; reply = data read
								state <= S_SEND_CPU_DATA;
							when others =>							-- unknown command; move back to IDLE;
								state <= S_IDLE;
						end case;
					end if;
				when S_MEM_WRITE_BYTE1 =>	-- 1ST BYTE: ADDRESS OF MEMORY
					if (Serial_RX_Received = '1') then -- wait for the first byte
						rx_byte_1 <= Serial_RX_Data;
						state <= S_MEM_WRITE_BYTE2;
					end if;
				when S_MEM_WRITE_BYTE2 => -- 2ND BYTE: OPCODE
					if (Serial_RX_Received = '1') then 
						rx_byte_2 <= Serial_RX_Data;
						state <= S_MEM_WRITE_BYTE3;
					end if;
				when S_MEM_WRITE_BYTE3 => -- 3RD BYTE: OPERAND
					if (Serial_RX_Received = '1') then 
						rx_byte_3 <= Serial_RX_Data;
						state <= S_PROGRAMMING_0;
					end if;
				when S_PROGRAMMING_0 =>
					-- configure RAM memory muxes for programming
					mux_address_control <= '1';
					mux_address_input2 <= rx_byte_1;
					mux_data_control <= '1';
					mux_data_input2 <= rx_byte_2 & rx_byte_3;
					mux_write_control <= '1';
					mux_write_input2 <= '0';
					state <= S_PROGRAMMING_1;
				when S_PROGRAMMING_1 =>
					mux_write_input2 <= '1'; -- cause a rising edge
					state <= S_PROGRAMMING_2;
				when S_PROGRAMMING_2 =>
					-- restore RAM memory muxes for cpu access
					mux_address_control <= '0';
					mux_data_control <= '0';
					mux_write_control <= '0';
					mux_write_input2 <= '0';
					state <= S_SEND_ACK; -- finished to write to the memory. Now ACK the command
					
				when S_MEM_READ_BYTE1 => -- 1ST BYTE: ADDRESS
					if (Serial_RX_Received = '1') then 
						rx_byte_1 <= Serial_RX_Data;
						state <= S_READING_MEMORY_0;
					end if;
				when S_READING_MEMORY_0 =>
					-- configure RAM memory muxes for reading
					mux_address_control <= '1';
					mux_address_input2 <= rx_byte_1;
					mux_write_control <= '1';
					mux_write_input2 <= '0';
					state <= S_READING_MEMORY_1;
				when S_READING_MEMORY_1 =>
					tx_byte_1 <= MemoryDataOutBus(15 downto 8);
					tx_byte_2 <= MemoryDataOutBus(7 downto 0);
					state <= S_READING_MEMORY_2;
				when S_READING_MEMORY_2 =>
					-- restore RAM memory muxes for cpu access
					mux_address_control <= '0';
					mux_data_control <= '0';
					mux_write_control <= '0';
					state <= S_SEND_MEM_DATA;
				when S_SEND_MEM_DATA =>
					packet_byte1 <= CMD_READ_MEMORY; -- tells that we are sending a response for a memory read command
					packet_byte2 <= rx_byte_1; 		-- tells the address of the memory that we read
					packet_byte3 <= tx_byte_1; 		-- sends first byte of the data read from memory
					packet_byte4 <= tx_byte_2; 		-- sends second byte of the data read from memory
					send_packet <= '1';
					state <= S_WAIT_SENDING;
				when S_SEND_CPU_DATA =>
					packet_byte1 <= CMD_READ_CPU;		-- tells that we are sending a response for a CPU read command
					packet_byte2 <= CpuAcc;
					packet_byte3 <= CpuPc;
					packet_byte4 <= (others => '0'); -- this byte is ignored
					send_packet <= '1';
					state <= S_WAIT_SENDING;	
				
				when S_RESET_CPU_0 =>
					CpuReset <= '1';
					state <= S_RESET_CPU_1;
				when S_RESET_CPU_1 =>	
					CpuReset <= '0';
					state <= S_SEND_ACK; -- CPU reset finished; send ACK;
				
				when S_SEND_ACK => -- we are sending ACK to a received command
					packet_byte1 <= CMD_ACK;
					packet_byte2 <= (others => '0');
					packet_byte3 <= (others => '0');
					packet_byte4 <= (others => '0');
					send_packet <= '1'; 	-- start transmission
					state <= S_WAIT_SENDING;
								
				when S_WAIT_SENDING =>
					send_packet <= '0';
					if (packet_sent = '1') then
						state <= S_IDLE;
					end if;
				
			end case;
			
		end if;
	end process StateMachine;
	
end Behavior;