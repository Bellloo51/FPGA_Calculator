
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity Divider is
    Port (
        Clk       : in  STD_LOGIC;
        Reset     : in  STD_LOGIC;
        Start     : in  STD_LOGIC;
        Dividend  : in  STD_LOGIC_VECTOR(3 downto 0);
        Divisor   : in  STD_LOGIC_VECTOR(3 downto 0);
        Quotient  : out STD_LOGIC_VECTOR(3 downto 0);
        Remainder : out STD_LOGIC_VECTOR(3 downto 0);
        Done      : out STD_LOGIC
    );
end Divider;

architecture Structural of Divider is

    component RCA5
        Port (
            A     : in  STD_LOGIC_VECTOR(4 downto 0);
            B     : in  STD_LOGIC_VECTOR(4 downto 0);
            C_in  : in  STD_LOGIC;
            Sum   : out STD_LOGIC_VECTOR(4 downto 0);
            Carry : out STD_LOGIC
        );
    end component;

    type State_Type is (IDLE, CALC, FINISH);
    signal State : State_Type := IDLE;

    signal R_reg : STD_LOGIC_VECTOR(4 downto 0);--remainder
    signal Q_reg : STD_LOGIC_VECTOR(3 downto 0);--피제수 -> 이후에는 몫
    signal M_reg : STD_LOGIC_VECTOR(4 downto 0);--제수

    signal M_inverted : STD_LOGIC_VECTOR(4 downto 0);
    signal R_shift    : STD_LOGIC_VECTOR(4 downto 0);
    signal R_sub      : STD_LOGIC_VECTOR(4 downto 0);
    signal R_next     : STD_LOGIC_VECTOR(4 downto 0);
    signal Q_next     : STD_LOGIC_VECTOR(3 downto 0);
    signal Sub_Carry  : STD_LOGIC;

    signal Count : STD_LOGIC_VECTOR(1 downto 0) := "00";

begin

    -- Invert divisor for subtraction
    M_inverted <= not M_reg;

    -- Left shift of {R, Q}
    R_shift <= R_reg(3 downto 0) & Q_reg(3);

    -- R_shift - M_reg using RCA5
    U_RCA : RCA5
        port map (
            A     => R_shift,
            B     => M_inverted,
            C_in  => '1',
            Sum   => R_sub,
            Carry => Sub_Carry
        );

    -- Restore if subtraction borrows
    R_next <= R_sub when Sub_Carry = '1'
              else R_shift;

    -- Insert quotient bit
    Q_next <= Q_reg(2 downto 0) & Sub_Carry;

    -- FSM and register updates
    process(Clk, Reset)
    begin
        if Reset = '1' then
            State <= IDLE;
            R_reg <= (others => '0');
            Q_reg <= (others => '0');
            M_reg <= (others => '0');
            Count <= "00";

        elsif rising_edge(Clk) then
            case State is

                when IDLE =>
                    if Start = '1' then
                        R_reg <= (others => '0');
                        Count <= "00";

                        -- Special rule for division by zero
                        -- or zero dividend
                        if Dividend = "0000" or
                           Divisor = "0000" then

                            Q_reg <= (others => '0');
                            M_reg <= (others => '0');
                            State <= FINISH;

                        else
                            Q_reg <= Dividend;
                            M_reg <= '0' & Divisor;
                            State <= CALC;
                        end if;
                    end if;

                when CALC =>
                    R_reg <= R_next;
                    Q_reg <= Q_next;

                    if Count = "11" then
                        State <= FINISH;
                    else
                        Count <= (Count(1) xor Count(0))
                                 & (not Count(0));
                    end if;

                when FINISH =>
                    if Start = '0' then
                        State <= IDLE;
                    end if;

            end case;
        end if;
    end process;

    Quotient  <= Q_reg;
    Remainder <= R_reg(3 downto 0);

    Done <= '1' when State = FINISH else '0';

end Structural;


