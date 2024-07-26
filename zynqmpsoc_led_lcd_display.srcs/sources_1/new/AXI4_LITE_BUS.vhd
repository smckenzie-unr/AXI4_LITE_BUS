library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity AXI4_LITE_SLAVE is
    generic(C_AXI_ADDRESS_WIDTH : positive range 32 to 128 := 32;
            C_AXI_DATA_WIDTH : positive range 32 to 128 := 32;
            C_AXI_STRB_WIDTH : positive range 4 to 8 := 4;
            C_NUM_REGISTERS : positive range 1 to 4096 := 32);
    port(
         -- Clock and Reset
         ACLK : in std_logic;
         ARESETN : in std_logic;
         
         -- Read Address Channel
         S_AXI_ARADDR : in std_logic_vector(C_AXI_ADDRESS_WIDTH-1 downto 0);
         S_AXI_ARVALID : in std_logic;
         S_AXI_ARREADY : out std_logic;
         
         -- Read Data Channel
         S_AXI_RDATA : out std_logic_vector(C_AXI_DATA_WIDTH-1 downto 0);
         S_AXI_RRESP : out std_logic_vector(1 downto 0);
         S_AXI_RVALID : out std_logic;
         S_AXI_RREADY : in std_logic;
         
         -- Write Address Channel
         S_AXI_AWADDR : in std_logic_vector(C_AXI_ADDRESS_WIDTH-1 downto 0);
         S_AXI_AWVALID : in std_logic;
         S_AXI_AWREADY : out std_logic;

         -- Write Data Channel
         S_AXI_WDATA : in std_logic_vector(C_AXI_DATA_WIDTH-1 downto 0);
         S_AXI_WSTRB : in std_logic_vector(C_AXI_STRB_WIDTH-1 downto 0);
         S_AXI_WVALID : in std_logic;
         S_AXI_WREADY : out std_logic;
 
         -- Write Response Channel
         S_AXI_BRESP : out std_logic_vector(1 downto 0);
         S_AXI_BVALID : out std_logic;
         S_AXI_BREADY : in std_logic
        );
end AXI4_LITE_SLAVE;

architecture LOGIC of AXI4_LITE_SLAVE is
    constant ADDR_LSB : integer := (C_AXI_DATA_WIDTH / 32) + 1;
    
    constant AXI_RESPONSE_OKAY : std_logic_vector(1 downto 0) := B"00";
    constant AXI_RESPONSE_EXOKAY : std_logic_vector(1 downto 0) := B"01";
    constant AXI_RESPONSE_SLVERR : std_logic_vector(1 downto 0) := B"10";
    constant AXI_RESPONSE_DECERR : std_logic_vector(1 downto 0) := B"11";
    
    type register_array is array (C_NUM_REGISTERS downto 0) of std_logic_vector(C_AXI_DATA_WIDTH-1 downto 0);
    type read_state_machine is (IDLE, READ_ADDR_LATCH, READ_DATA_OUT);
    type write_state_machine is (NOOP, ADDRESS_LATCH, WAIT_FOR_VALID_DATA, DATA_LATCH, RESPONSE_OUT);
    
    --pure function SLAVE_REG_INIT(array_length : positive) return register_array is
    --    variable ret_registers : register_array := (others => (others => '0'));
    --begin
    --    for i in 0 to array_length-1 loop
    --        ret_registers(i) := std_logic_vector(to_unsigned(array_length-1-i, ret_registers(i)'length));
    --    end loop;
    --    return ret_registers;
    --end function;
    
    signal registers : register_array := (others => (others => '0')); --SLAVE_REG_INIT(C_NUM_REGISTERS);
    signal read_state : read_state_machine := IDLE;
    signal write_state : write_state_machine := NOOP;
    
    signal axi_arready : std_logic := '0';
    signal axi_rvalid : std_logic := '0';
    signal axi_awready : std_logic := '0';
    signal axi_wready : std_logic := '0';
    signal axi_bvalid : std_logic := '0';
    
    signal axi_rresp : std_logic_vector(1 downto 0) := AXI_RESPONSE_SLVERR;
    signal axi_bresp : std_logic_vector(1 downto 0) := (others => '0');
    signal axi_rdata : std_logic_vector(C_AXI_DATA_WIDTH-1 downto 0) := (others => '0');
begin
    S_AXI_ARREADY <= axi_arready;
    S_AXI_RVALID <= axi_rvalid;
    S_AXI_AWREADY <= axi_awready;
    S_AXI_WREADY <= axi_wready;
    S_AXI_BVALID <= axi_bvalid;
    
    S_AXI_BRESP <= axi_bresp;
    S_AXI_RDATA <= axi_rdata;
    S_AXI_RRESP <= axi_rresp;
    
    READ_STATE_PROC : process(ACLK) is
        variable address : natural := 0;
    begin
        if rising_edge(ACLK) then
            if ARESETN = '0' then
                read_state <= IDLE;
                axi_arready <= '0';
                axi_rvalid <= '0';
                axi_rdata <= (others => '0');
                axi_rresp <= AXI_RESPONSE_SLVERR;
            else
                case read_state is
                    when READ_ADDR_LATCH =>
                        axi_arready <= '1';
                        address := to_integer(unsigned(S_AXI_ARADDR(C_AXI_ADDRESS_WIDTH - 1 downto ADDR_LSB)));
                        read_state <= READ_DATA_OUT;
                    when READ_DATA_OUT =>
                        axi_arready <= '0';
                        axi_rvalid <= '1';
                        axi_rdata <= registers(address);
                        axi_rresp <= AXI_RESPONSE_OKAY;
                        if S_AXI_RREADY = '1' then
                            read_state <= IDLE;
                        else
                            read_state <= READ_DATA_OUT;
                        end if;
                    when others => --IDLE
                        axi_rvalid <= '0';
                        axi_rresp <= AXI_RESPONSE_SLVERR;
                        if S_AXI_ARVALID = '1' then
                            read_state <= READ_ADDR_LATCH;
                        else
                            read_state <= IDLE;
                        end if;
                end case;
            end if;
        end if;
    end process;
    
    WRITE_STATE_PROC : process(ACLK) is
        variable address : natural := 0;
    begin
        if rising_edge(ACLK) then
            if ARESETN = '0' then
                write_state <= NOOP;
                axi_awready <= '0';
                axi_wready <= '0';
                axi_bvalid <= '0';
                axi_bresp <= AXI_RESPONSE_SLVERR;
            else
                case write_state is
                    when ADDRESS_LATCH =>
                        axi_awready <= '1';
                        address := to_integer(unsigned(S_AXI_AWADDR(C_AXI_ADDRESS_WIDTH - 1 downto ADDR_LSB)));
                        write_state <= WAIT_FOR_VALID_DATA;
                    when WAIT_FOR_VALID_DATA =>
                        axi_awready <= '0';
                        if S_AXI_WVALID = '1' then
                            write_state <= DATA_LATCH;
                        else
                            write_state <= WAIT_FOR_VALID_DATA;
                        end if;
                    when DATA_LATCH =>
                        axi_wready <= '1';
                        registers(address) <= S_AXI_WDATA;
                        write_state <= RESPONSE_OUT;
                    when RESPONSE_OUT =>
                        axi_wready <= '0';
                        axi_bvalid <= '1';
                        axi_bresp <= AXI_RESPONSE_OKAY;
                        if S_AXI_BREADY = '1' then
                            write_state <= NOOP;
                        else
                            write_state <= RESPONSE_OUT;
                        end if;
                    when others => --NOOP
                        axi_bvalid <= '0';
                        axi_bresp <= AXI_RESPONSE_SLVERR;
                        if S_AXI_AWVALID = '1' then
                            write_state <= ADDRESS_LATCH;
                        else
                            write_state <= NOOP;
                        end if;
                end case;
            end if;
        end if;
    end process;
    
end LOGIC;
