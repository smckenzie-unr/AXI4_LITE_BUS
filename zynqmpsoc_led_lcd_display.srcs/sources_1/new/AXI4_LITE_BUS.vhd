library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
--use ieee.std_logic_arith.all;

entity AXI4_LITE_BUS is
    generic(
            --AXI Data width: 32 Bits or 64 Bits
            C_AXI_DATA_WIDTH : positive range 16 to 64 := 32;

            --AXI Address width: 32 Bits or 64 Bits
            C_AXI_ADDRESS_WIDTH : positive range 16 to 64 := 32;

            --Strobe width
            C_STROBE_WIDTH : positive := 4;

            --Number or internal registers
            C_NUM_REGISTERS : positive := 32
           );

    port(
        --Clock and Reset
         ACLK : in std_logic;
         ARESETN : in std_logic;
         
         --Write Address Channel
         S_AXI_AWADDR : in std_logic_vector(C_AXI_ADDRESS_WIDTH-1 downto 0);
         S_AXI_AWVALID : in std_logic;
         S_AXI_AWREADY : out std_logic;

         --Write Data Channel
         S_AXI_WDATA : in std_logic_vector(C_AXI_DATA_WIDTH-1 downto 0);
         S_AXI_WSTRB : in std_logic_vector(C_STROBE_WIDTH-1 downto 0);
         S_AXI_WVALID : in std_logic;
         S_AXI_WREADY : out std_logic;

         --Read Address Channel
         S_AXI_ARADDR : in std_logic_vector(C_AXI_ADDRESS_WIDTH-1 downto 0);
         S_AXI_ARVALID : in std_logic;
         S_AXI_ARREADY : out std_logic;

         --Read Data Channel
         S_AXI_RDATA : out std_logic_vector(C_AXI_DATA_WIDTH-1 downto 0);
         S_AXI_RVALID : out std_logic;
         S_AXI_RREADY : in std_logic;
         S_AXI_RRESP : out std_logic_vector(1 downto 0);
         
         --Write Response Channel
         S_AXI_BRESP : out std_logic_vector(1 downto 0);
         S_AXI_BVALID : out std_logic;
         S_AXI_BREADY : in std_logic
        );
end AXI4_LITE_BUS;

architecture LOGIC of AXI4_LITE_BUS is
    --Type array of std_logic_vector used as addressable registers.
    type register_array is array (C_NUM_REGISTERS downto 0) of std_logic_vector(C_AXI_DATA_WIDTH-1 downto 0);
    
    --Type read state machine
    type read_state_machine is (IDLE, ADDRESS_LATCH, DATA_OUTPUT);

    pure function SLAVE_REG_INIT(array_length : positive) return register_array is
        variable ret_registers : register_array := (others => (others => '0'));
    begin
        for i in 0 to array_length-1 loop
            ret_registers(i) := std_logic_vector(to_unsigned(array_length-1-i, ret_registers(i)'length));
        end loop;
        return ret_registers;
    end function;
    
    pure function ADDRESS_INT(stv_address : std_logic_vector(C_AXI_ADDRESS_WIDTH-1 downto 0)) return integer is
        constant ADDR_LSB  : integer := (C_AXI_DATA_WIDTH/32)+1;
    begin
        return to_integer(unsigned(stv_address(stv_address'high downto ADDR_LSB)));
    end function;

    --constant AXI_RESPONSE_OKAY : std_logic_vector(1 downto 0) := 2X"0";
    --constant AXI_RESPONSE_EXOKAY : std_logic_vector(1 downto 0) := 2X"1";
    --constant AXI_RESPONSE_SLVERR : std_logic_vector(1 downto 0) := 2X"2";
    --constant AXI_RESPONSE_DECERR : std_logic_vector(1 downto 0) := 2X"3";

    signal data_registers : register_array := SLAVE_REG_INIT(C_NUM_REGISTERS); --(others => (others => '0'));
    signal read_state : read_state_machine := IDLE;
    
    signal read_address_reg : natural := 0;
    signal slv_reg_rden : std_logic := '0';

    signal axi_arready : std_logic := '0';
    signal axi_rdata : std_logic_vector(C_AXI_DATA_WIDTH-1 downto 0) := (others => '0');
    signal axi_rvalid : std_logic := '0';
    signal axi_rresp : std_logic_vector(1 downto 0) := (others => '0');
    
    signal axi_awready : std_logic := '0';
    signal axi_bresp : std_logic_vector(1 downto 0) := (others => '0');
    signal axi_bvalid : std_logic := '0';
    signal axi_wready : std_logic := '0';
begin
    S_AXI_ARREADY <= axi_arready;
    S_AXI_RDATA <= axi_rdata;
    S_AXI_RVALID <= axi_rvalid;
    S_AXI_RRESP <= axi_rresp;
    
    S_AXI_WREADY <= axi_wready;
    S_AXI_AWREADY <= axi_awready;
    S_AXI_BRESP <= axi_bresp;
    S_AXI_BVALID <= axi_bvalid;
    
    
    read_state_proc : process(ACLK) is
    begin
        if rising_edge(ACLK) then
            if ARESETN = '0' then
                read_state <= IDLE;
                axi_arready <= '0';
                axi_rvalid <= '0';
                axi_rdata <= (others => '0');
            else
                case read_state is
                    when ADDRESS_LATCH =>
                        axi_arready <= '1';
                        read_address_reg <= ADDRESS_INT(S_AXI_ARADDR);
                        read_state <= DATA_OUTPUT;
                    when DATA_OUTPUT =>
                        axi_arready <= '0';
                        axi_rvalid <= '1';
                        axi_rdata <= data_registers(read_address_reg);
                        if S_AXI_RREADY = '1' then
                            read_state <= IDLE;
                        else
                            read_state <= DATA_OUTPUT;
                        end if;
                    when others => --IDLE
                        axi_rvalid <= '0';
                        if S_AXI_ARVALID = '1' then
                            read_state <= ADDRESS_LATCH;
                        else
                            read_state <= IDLE;
                        end if;
                end case;
            end if;
        end if;
    end process;
end LOGIC;
