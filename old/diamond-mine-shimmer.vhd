library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity diamond_mine_shimmer is
    generic (
        CLK_HZ              : positive := 1000;
        OSC1_HALF_PERIOD_MS : positive := 280;
        OSC2_HALF_PERIOD_MS : positive := 320;
        FADE_STEP_MS        : positive := 184
    );
    port (
        clk            : in  std_logic;
        rst_n          : in  std_logic;
        dark           : in  std_logic;
        steady_drive   : out std_logic;
        twinkle1_drive : out std_logic;
        twinkle2_drive : out std_logic;
        fade_level     : out unsigned(7 downto 0)
    );
end entity;

architecture rtl of diamond_mine_shimmer is
    constant MS_TICKS : natural := CLK_HZ / 1000;

    signal ms_div      : natural range 0 to MS_TICKS - 1 := 0;
    signal tick_1ms    : std_logic := '0';

    signal osc1_ctr    : natural := 0;
    signal osc2_ctr    : natural := 0;
    signal tw1         : std_logic := '0';
    signal tw2         : std_logic := '0';

    signal fade_ctr    : natural := 0;
    signal fade_reg    : unsigned(7 downto 0) := (others => '0');
begin
    process (clk, rst_n)
    begin
        if rst_n = '0' then
            ms_div <= 0;
            tick_1ms <= '0';
        elsif rising_edge(clk) then
            if ms_div = MS_TICKS - 1 then
                ms_div <= 0;
                tick_1ms <= '1';
            else
                ms_div <= ms_div + 1;
                tick_1ms <= '0';
            end if;
        end if;
    end process;

    process (clk, rst_n)
    begin
        if rst_n = '0' then
            osc1_ctr <= 0;
            osc2_ctr <= 0;
            tw1 <= '0';
            tw2 <= '0';
        elsif rising_edge(clk) then
            if tick_1ms = '1' then
                if dark = '0' then
                    tw1 <= '0';
                    tw2 <= '0';
                    osc1_ctr <= 0;
                    osc2_ctr <= 0;
                else
                    if osc1_ctr >= OSC1_HALF_PERIOD_MS - 1 then
                        osc1_ctr <= 0;
                        tw1 <= not tw1;
                    else
                        osc1_ctr <= osc1_ctr + 1;
                    end if;

                    if osc2_ctr >= OSC2_HALF_PERIOD_MS - 1 then
                        osc2_ctr <= 0;
                        tw2 <= not tw2;
                    else
                        osc2_ctr <= osc2_ctr + 1;
                    end if;
                end if;
            end if;
        end if;
    end process;

    process (clk, rst_n)
    begin
        if rst_n = '0' then
            fade_reg <= (others => '0');
            fade_ctr <= 0;
        elsif rising_edge(clk) then
            if tick_1ms = '1' then
                if dark = '1' then
                    if fade_reg < to_unsigned(255, fade_reg'length) then
                        if fade_ctr >= FADE_STEP_MS - 1 then
                            fade_ctr <= 0;
                            fade_reg <= fade_reg + 1;
                        else
                            fade_ctr <= fade_ctr + 1;
                        end if;
                    end if;
                else
                    fade_reg <= (others => '0');
                    fade_ctr <= 0;
                end if;
            end if;
        end if;
    end process;

    steady_drive <= '1' when (dark = '1' and fade_reg > to_unsigned(20, fade_reg'length)) else '0';
    twinkle1_drive <= '1' when (dark = '1' and tw1 = '1') else '0';
    twinkle2_drive <= '1' when (dark = '1' and tw2 = '1') else '0';
    fade_level <= fade_reg;

end architecture;
