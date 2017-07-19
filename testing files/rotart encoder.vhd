library ieee;
use ieee.std_logic_1164.all;

entity rotary_encoder is
  port (
    -- clock and reset
    clk       : in  std_logic;
    rst       : in  std_logic; -- asynchronous, active high
    -- inputs from hardware
    rot_a     : in  std_logic;
    rot_b     : in  std_logic;
    -- decoded signals
    rot_event : out std_logic; -- '1' == knob was turned
    rot_dir   : out std_logic  -- '1' == right, '0' == left
  );
end entity rotary_encoder;

architecture rtl of rotary_encoder is

  -- signal definitions
  signal rot_in     : std_logic_vector(1 downto 0);
  signal rot_q1     : std_logic;
  signal rot_q2     : std_logic;
  signal rot_q1_del : std_logic; -- rot_q1 delayed by one clock cycle

begin

  -- For implementation details see Rotary Encoder Interface for Spartan-3E
  -- Starter Kit Ken Chapman Xilinx Ltd 20th February 2006, Rev. 2

  rotary_filter: process (rst, clk)
  begin
    if rst = '1' then
      rot_in <= "11";
      rot_q1 <= '1';
      rot_q2 <= '0';
    elsif rising_edge(clk) then
      -- concatinate rot_a and rot_b for clearer decoding
      rot_in <= rot_a&rot_b;
      -- decode state of encoder
      case rot_in is
        when "00" => rot_q1 <= '0';         
        when "01" => rot_q2 <= '0';
        when "10" => rot_q2 <= '1';
        when "11" => rot_q1 <= '1';
        when others =>
      end case;
    end if;
  end process rotary_filter;

  rotary_detection: process (rst, clk)
  begin
    if rst = '1' then
      rot_q1_del <= '1';
      rot_event  <= '0';
      rot_dir    <= '0';
    elsif rising_edge(clk) then
      -- delay rot_q1
      rot_q1_del <= rot_q1;
      -- rising edge on rot_q1
      if rot_q1 = '1' and rot_q1_del = '0' then
        rot_event <= '1';
        rot_dir   <= rot_q2;
      else
        rot_event <= '0';
      end if;
    end if;
  end process rotary_detection;

end architecture rtl;

