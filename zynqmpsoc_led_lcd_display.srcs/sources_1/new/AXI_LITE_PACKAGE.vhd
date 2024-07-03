library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package AXI_LITE_PACKAGE is
    function BUS_WIDTH(BIT_WIDTH_64 : boolean := true) return integer;
    function NIBBLE_WIDTH(BIT_WIDTH_64 : boolean := true) return integer;
end package AXI_LITE_PACKAGE;

package body AXI_LITE_PACKAGE is
    function BUS_WIDTH(BIT_WIDTH_64 : boolean := true) return integer is
        variable ret_width : integer := 32;
    begin
        if BIT_WIDTH_64 then
            ret_width := 64;
        end if;
        return ret_width;
    end function;
    function NIBBLE_WIDTH(BIT_WIDTH_64 : boolean := true) return integer is
        variable nibble_width : integer := 4;
    begin
        if BIT_WIDTH_64 then
            nibble_width := 32;
        end if;
        return nibble_width;
    end function;
end package body AXI_LITE_PACKAGE;