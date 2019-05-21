-- ------------------------------------------------------------------------------------------
-- Author: Giovani Luigi Rubenich Brondani
-- Copyright (c) 2019: All rights reserved
-- ------------------------------------------------------------------------------------------

library IEEE;

use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity Display is
	port(
		Clk			: in  std_logic;
		Reset			: in  std_logic;
		DataInput	: in  std_logic_vector(7 downto 0);
		LedPinVal	: out std_logic_vector(7 downto 0); -- 7 segments/digit
		LedPinSel	: out std_logic_vector(3 downto 0)  -- 4 digits scan
	);
end Display;

architecture arc of Display is

	component BinToBcd is
		Port ( 
			number   : in  std_logic_vector (7 downto 0);
			hundreds : out std_logic_vector (3 downto 0);
			tens     : out std_logic_vector (3 downto 0);
			ones     : out std_logic_vector (3 downto 0)
		);
	end component BinToBcd;

	signal selected_digit : std_logic_vector(3 downto 0);
	signal counter_scan	 : std_logic_vector(15 downto 0);
	
	-- registers to store 4 digits on the display
	signal digit_value_0  : std_logic_vector(3 downto 0) := (others => '0'); -- 0 ~ F = 16 values = 2^4 combinations
	signal digit_value_1  : std_logic_vector(3 downto 0) := (others => '0'); -- 0 ~ F = 16 values
	signal digit_value_2  : std_logic_vector(3 downto 0) := (others => '0'); -- 0 ~ F = 16 values
	signal digit_value_3  : std_logic_vector(3 downto 0) := (others => '0'); -- 0 ~ F = 16 values (not used for now)

	signal digit_value	 : std_logic_vector(3 downto 0); -- value of the digit currently selected
	
begin

	BCD_ENCODER: BinToBcd
		port map(
			number => DataInput,
			hundreds => digit_value_2,
			tens => digit_value_1,
			ones => digit_value_0
		);

	LedPinSel <= selected_digit;

	-- generate scanning clock
	process(Clk) is
	begin
		if (rising_edge(Clk)) then
			counter_scan <= std_logic_vector(unsigned(counter_scan) + 1);
		end if;
	end process;
	
	-- scan digits (changing currently selected digit) based on 16-bit prescaler derived from main clock
	process (counter_scan(15 downto 14)) is
	begin
		case (counter_scan(15 downto 14)) is
			when "00" => 
				selected_digit <= "1110";
			when "01" =>
				selected_digit <= "1101";
			when "10" =>
				selected_digit <= "1011";
			when "11" =>
				selected_digit <= "0111";
			when others =>
				selected_digit <= "1110";
		end case;
	end process;
	
	-- output the value according to sel. digit
	process(selected_digit) is -- upon change in the selected digit
	begin
		case selected_digit is
			when "1110" => -- MSB/RIGHT (Digit 0)
				digit_value <= digit_value_0;
			when "1101" => -- 	 		 (Digit 1)
				digit_value <= digit_value_1;
			when "1011" => -- 	 		 (Digit 2)
				digit_value <= digit_value_2;
			when "0111" => -- LSB/LEFT  (Digit 3)
				digit_value <= digit_value_3;
			when others =>
				digit_value <= "0000";
		end case;
	end process;

	-- Encode BCD value into the appropriate output to display the desired number (0-F) on the digit
	-- Warning: The sequence of segments depends on the pin assignment on the board layout, so it is hardware dependent
	--       A
	--   	 -----
	--  	|		|
	--  F |	G	| B
	--  	|-----|
	--  E	|     | C
	--  	|	D	|	
	--   	 -----
	--  output bits = "PGFEDCBA" using 1 = OFF, 0 = ON (P = DP = Decimal Place)
	process(digit_value) is
	begin
		case(digit_value) is
			when "0000" => --PGFEDCBA
				LedPinVal <= "11000000"; -- segments draw a '0' = A+B+C+D+E+F
			when "0001" => --PGFEDCBA
				LedPinVal <= "11111001"; -- segments draw a '1' = B+C
			when "0010" => --PGFEDCBA
				LedPinVal <= "10100100"; -- segments draw a '2' = A+B+G+E+D
			when "0011" => --PGFEDCBA
				LedPinVal <= "10110000"; -- segments draw a '3' = A+B+G+C+D
			when "0100" => --PGFEDCBA
				LedPinVal <= "10011001"; -- segments draw a '4' = F+G+B+C
			when "0101" => --PGFEDCBA
				LedPinVal <= "10010010"; -- segments draw a '5' = A+F+G+C+D
			when "0110" => --PGFEDCBA
				LedPinVal <= "10000010"; -- segments draw a '6' = A+F+E+D+C+G
			when "0111" => --PGFEDCBA
				LedPinVal <= "11111000"; -- segments draw a '7' = A+B+C
			when "1000" => --PGFEDCBA
				LedPinVal <= "10000000"; -- segments draw a '8' = all segments
			when "1001" => --PGFEDCBA
				LedPinVal <= "10010000"; -- segments draw a '9' = A+F+G+B+C+D
			when others =>
				LedPinVal <= "11111111"; -- ALL OFF
		end case;
	end process;
	
end arc;