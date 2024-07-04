----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 06/12/2024 07:13:28 PM
-- Design Name: 
-- Module Name: TestBench - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity TestBench is
end TestBench;

architecture Behavioral of TestBench is
    constant clk_freq : real := 100.00E6;

    procedure clock_generator(signal CLK : out std_logic; 
                              constant FREQ : real; 
                              PHASE : time := 0 fs; 
                              signal RUN : std_logic) is
        constant HIGH_TIME   : time := 0.5 sec / FREQ;
        variable low_time_v  : time;
        variable cycles_v    : real := 0.0;
        variable freq_time_v : time := 0 fs;
    begin
        assert (HIGH_TIME /= 0 fs) report "clk_gen: High time is zero; time resolution to large for frequency" severity FAILURE;
        clk <= '0';
        wait for PHASE;
        loop
            if (run = '1') or (run = 'H') then
                clk <= run;
            end if;
            wait for HIGH_TIME;
            clk <= '0';
            low_time_v := 1 sec * ((cycles_v + 1.0) / FREQ) - freq_time_v - HIGH_TIME; 
            wait for low_time_v;
            cycles_v := cycles_v + 1.0;
            freq_time_v := freq_time_v + HIGH_TIME + low_time_v;
        end loop;
    end procedure;

    signal clock : std_logic := '0';
    signal clock_en : std_logic := '1';
    signal reset : std_logic := '1';

    signal awaddr : std_logic_vector(31 downto 0) := (others => '0');
    signal awvalid : std_logic := '0';
    signal awready : std_logic := '0';

    signal wdata : std_logic_vector(31 downto 0) := (others => '0');
    signal wstrb : std_logic_vector(3 downto 0) := (others => '0');
    signal wvalid : std_logic := '0';
    signal wready : std_logic := '0';
    
    signal bresp : std_logic_vector(1 downto 0) := (others => '0');
    signal bvalid : std_logic := '0';
    signal bready : std_logic := '0';

    signal araddr : std_logic_vector(31 downto 0) := (others => '0');
    signal arvalid : std_logic := '0';
    signal arready : std_logic := '0';

    signal rdata : std_logic_vector(31 downto 0) := (others => '0');
    signal rvalid : std_logic := '0';
    signal rready : std_logic := '0';
    signal rresp : std_logic_vector(1 downto 0) := (others => '0');

begin
    clock_generator(CLK => clock, FREQ => clk_freq, RUN => clock_en);
    UUT : entity work.AXI4_LITE_SLAVE port map(ACLK => clock,
                                               ARESETN => reset,

                                               S_AXI_AWADDR => awaddr,
                                               S_AXI_AWVALID => awvalid,
                                               S_AXI_AWREADY => awready,

                                               S_AXI_WDATA => wdata,
                                               S_AXI_WSTRB => wstrb,
                                               S_AXI_WVALID => wvalid,
                                               S_AXI_WREADY => wready,


                                               S_AXI_ARADDR => araddr,
                                               S_AXI_ARVALID => arvalid,
                                               S_AXI_ARREADY => arready,

                                               S_AXI_RDATA => rdata,
                                               S_AXI_RVALID => rvalid,
                                               S_AXI_RREADY => rready,
                                               S_AXI_RRESP => rresp,

                                               S_AXI_BRESP => bresp,
                                               S_AXI_BVALID => bvalid,
                                               S_AXI_BREADY => bready
                                               ); 
    
    awvalid <= '1' after 0.880 us,
               '0' after 0.900 us,
               '1' after 0.940 us,
               '0' after 0.960 us;
    awaddr <= X"00000014" after 0.880 us,
              X"00000000" after 0.900 us,
              X"00000004" after 0.940 us,
              X"00000000" after 0.960 us;
    wvalid <= '1' after 0.900 us,
              '0' after 0.920 us,
              '1' after 0.960 us,
              '0' after 0.980 us;
    wdata <= X"DEADBEEF" after 0.900 us,
             X"00000000" after 0.920 us,
             X"BA5EBA11" after 0.960 us,
             X"00000000" after 0.980 us;
    wstrb <= B"1111" after 0.900 us, 
             B"0000" after 0.920 us,
             B"1111" after 0.960 us, 
             B"0000" after 0.980 us; 
    bready <= '1' after 0.930 us,
              '0' after 0.940 us, 
              '1' after 0.990 us,
              '0' after 1.000 us;          
                                                        
    arvalid <= '1' after 1.010 us,
               '0' after 1.030 us,
               '1' after 1.050 us,
               '0' after 1.070 us;
    araddr <= X"00000004" after 1.010 us,
              X"00000000" after 1.030 us,
              X"00000014" after 1.050 us, 
              X"00000000" after 1.070 us;
    rready <= '1' after 1.040 us,
              '0' after 1.050 us,
              '1' after 1.080 us,
              '0' after 1.090 us;
end Behavioral;
