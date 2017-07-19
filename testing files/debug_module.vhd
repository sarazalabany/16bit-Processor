library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity debug_module is
  port (
    -- clock and reset
    clk     : in    std_logic;
    rst     : in    std_logic; -- asynchronous, active high
    -- processor bus
    dataIO  : inout std_logic_vector(15 downto 0);
    oe      : in    std_logic;
    wren    : in    std_logic;
    -- inputs from rotation encoder hardware
    rot_a   : in    std_logic;
    rot_b   : in    std_logic;
    rot_btn : in    std_logic;
    -- outputs to LEDs
    leds    : out   std_logic_vector( 7 downto 0)
  );
end entity debug_module;

architecture rtl of debug_module is

  -- component declarations
  component rotary_encoder is
    port (
      -- clock and reset
      clk       : in  std_logic;
      rst       : in  std_logic; -- asynchronous, active high
      -- inputs from hardware
      rot_a     : in  std_logic;
      rot_b     : in  std_logic;
      -- decoded signals
      rot_event : out std_logic; -- '1' == knob was turned
      rot_dir   : out std_logic  -- '1' == left, '0' == right
    );
  end component;

  -- signal definitions
  signal led_toggle_en    : std_logic_vector( 7 downto 0);
  signal led_state        : std_logic_vector( 7 downto 0);
  signal led_out          : std_logic_vector( 7 downto 0);

  constant clk_div_value  : std_logic_vector(24 downto 0) := "1"&x"7d783f"; -- 24_999_999
  signal clk_div_counter  : std_logic_vector(24 downto 0);
  signal toggle_led       : std_logic;
  signal led_clk          : std_logic;

  signal rot_btn_del      : std_logic_vector(1 downto 0); -- rot_btn delayed by
                                                          -- one/two clock cycle
  signal rot_push         : std_logic;
  signal rot_right        : std_logic;
  signal rot_left         : std_logic;

  signal rot_event        : std_logic;
  signal rot_dir          : std_logic;
 

begin

  -- handles the communication with the processor through the data bus
  bus_handler: process (rst, clk)
  begin
    if rst = '1' then
      dataIO        <= (others => 'Z');
      led_toggle_en <= (others => '0');
      led_state     <= x"AA";
    elsif rising_edge(clk) then
      -- processor writes to this component
      if wren = '1' then
        led_toggle_en <= dataIO(15 downto 8);
        led_state     <= dataIO( 7 downto 0);
      end if;
      -- processor reads from this component
      if oe = '1' then
        dataIO(15)  <= rot_push;
		  dataIO(14)  <=rot_left;
		  dataIO(13)  <=rot_right;
		  dataIO(12 downto 8) <= "00000";
		  dataIO(7 downto 0) <= led_out;
		  
      else
        dataIO  <= (others => 'Z');
      end if;
    end if;
  end process bus_handler;

  -- process the rotary encoder and button inputs, reset the values, when they
  -- were read by the processor bus
  input_handler: process (rst, clk)
  begin
    if rst = '1' then
      rot_btn_del <= (others => '0');
      rot_push    <= '0';
      rot_right   <= '0';
      rot_left    <= '0';
    elsif rising_edge(clk) then
      -- delay rot_btn by one/two clock cycle(s)
      rot_btn_del <= rot_btn_del(0)&rot_btn;
      -- rising edge of rot_btn
      if rot_btn_del = "01" then
        rot_push  <= '1';
      elsif oe = '1' then
        rot_push  <= '0';
      end if;
      -- knob was turned, determine direction
      if rot_event = '1' then
        rot_left  <= rot_dir;
        rot_right <= not(rot_dir);
      elsif oe = '1' then
        rot_left  <= '0';
        rot_right <= '0';
      end if;
    end if;
  end process input_handler;

  -- create a pulse twice a second (2Hz period) from the 50Mhz input clock
  clk_divider: process (rst, clk)
  begin
    if rst = '1' then
      clk_div_counter <= (others => '0');
      toggle_led      <= '0';
    elsif rising_edge(clk) then
      if clk_div_counter = clk_div_value then
        clk_div_counter <= (others => '0');
        toggle_led      <= '1';
      else
        clk_div_counter <= std_logic_vector(unsigned(clk_div_counter) + 1);
        toggle_led      <= '0';
      end if;
    end if;
  end process clk_divider;

  -- create a 1Hz, 50-50 duty cycle clock from the 2Hz-frequency, 1-clk-cycle
  -- long 'toggle_led' pulses, effectivly implmenenting a toggle-flip-flop
  led_clk_div: process (rst, clk)
  begin
    if rst = '1' then
      led_clk <= '0';
    elsif rising_edge(clk) then
      if toggle_led = '1' then
        led_clk <= not(led_clk);
      end if;
    end if;
  end process led_clk_div;

  -- set the leds to either the value from the cpu or to the 1Hz led_clk signal
  -- depending on whether led_toggle_en is set for a particular led or not
  led_select: for i in 7 downto 0 generate
    led_out(i)  <= led_state(i) when led_toggle_en(i) = '0' else led_clk;
  end generate led_select;

  -- asign the led values to the output pins
  leds  <= led_out;

  -- component instantiations
  rotary_encoder_inst: rotary_encoder
    port map (
      -- clock and reset
      clk       => clk,
      rst       => rst,
      -- inputs from hardware
      rot_a     => rot_a,
      rot_b     => rot_b,
      -- decoded signals
      rot_event => rot_event,
      rot_dir   => rot_dir
    );

end architecture;

