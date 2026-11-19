library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity Divider is
    Port (
        Clk          : in  STD_LOGIC;
        Reset        : in  STD_LOGIC;
        Start        : in  STD_LOGIC;
        Dividend     : in  STD_LOGIC_VECTOR(3 downto 0);
        Divisor      : in  STD_LOGIC_VECTOR(3 downto 0);
        Quotient_mag : out STD_LOGIC_VECTOR(3 downto 0);
        Sign_Q       : out STD_LOGIC;
        Remainder    : out STD_LOGIC_VECTOR(3 downto 0);
        Done         : out STD_LOGIC
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

    component negative_complement
        Port (
            A_in  : in  STD_LOGIC_VECTOR(3 downto 0);
            A_out : out STD_LOGIC_VECTOR(3 downto 0)
        );
    end component;
    component Euclidean_Corrector
        Port (
            Sign_A       : in  STD_LOGIC;
            Sign_B       : in  STD_LOGIC;
            Divisor_mag  : in  STD_LOGIC_VECTOR(3 downto 0);
            Quotient_in  : in  STD_LOGIC_VECTOR(3 downto 0);
            Rem_mag      : in  STD_LOGIC_VECTOR(3 downto 0);
            Quotient_mag : out STD_LOGIC_VECTOR(3 downto 0);
            Sign_Q       : out STD_LOGIC;
            Remainder    : out STD_LOGIC_VECTOR(3 downto 0)
        );
    end component;

    type State_Type is (IDLE, CALC, FINISH);
    signal State : State_Type := IDLE;

    signal Sign_A : STD_LOGIC;
    signal Sign_B : STD_LOGIC;

    signal Sign_A_reg : STD_LOGIC := '0';
    signal Sign_B_reg : STD_LOGIC := '0';

    signal Dividend_mag : STD_LOGIC_VECTOR(3 downto 0);
    signal Divisor_mag  : STD_LOGIC_VECTOR(3 downto 0);

    signal R_reg : STD_LOGIC_VECTOR(4 downto 0);
    signal Q_reg : STD_LOGIC_VECTOR(3 downto 0);
    signal M_reg : STD_LOGIC_VECTOR(4 downto 0);

    signal M_inverted : STD_LOGIC_VECTOR(4 downto 0);
    signal R_shift    : STD_LOGIC_VECTOR(4 downto 0);
    signal R_sub      : STD_LOGIC_VECTOR(4 downto 0);
    signal R_next     : STD_LOGIC_VECTOR(4 downto 0);
    signal Q_next     : STD_LOGIC_VECTOR(3 downto 0);
    signal Sub_Carry  : STD_LOGIC;

    signal Q_corrected : STD_LOGIC_VECTOR(3 downto 0);
    signal R_corrected : STD_LOGIC_VECTOR(3 downto 0);
    signal Q_sign      : STD_LOGIC;

    signal Count : STD_LOGIC_VECTOR(1 downto 0) := "00";

begin

    Sign_A <= Dividend(3);
    Sign_B <= Divisor(3);

    U_ABS_A : negative_complement
        port map (
            A_in  => Dividend,
            A_out => Dividend_mag
        );

    U_ABS_B : negative_complement
        port map (
            A_in  => Divisor,
            A_out => Divisor_mag
        );

    M_inverted <= not M_reg;

    R_shift <= R_reg(3 downto 0) & Q_reg(3);

    U_RCA : RCA5
        port map (
            A     => R_shift,
            B     => M_inverted,
            C_in  => '1',
            Sum   => R_sub,
            Carry => Sub_Carry
        );

    R_next <= R_sub when Sub_Carry = '1'
              else R_shift;

    Q_next <= Q_reg(2 downto 0) & Sub_Carry;

    process(Clk, Reset)
    begin
        if Reset = '1' then
            State <= IDLE;
            R_reg <= (others => '0');
            Q_reg <= (others => '0');
            M_reg <= (others => '0');
            Count <= "00";

            Sign_A_reg <= '0';
            Sign_B_reg <= '0';

        elsif rising_edge(Clk) then
            case State is

                when IDLE =>
                    if Start = '1' then
                        R_reg <= (others => '0');
                        Count <= "00";

                        Sign_A_reg <= Sign_A;
                        Sign_B_reg <= Sign_B;

                        if Dividend_mag = "0000" or
                           Divisor_mag = "0000" then

                            Q_reg <= (others => '0');
                            M_reg <= (others => '0');
                            State <= FINISH;

                        else
                            Q_reg <= Dividend_mag;
                            M_reg <= '0' & Divisor_mag;
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

    U_Corrector : Euclidean_Corrector
        port map (
            Sign_A       => Sign_A_reg,
            Sign_B       => Sign_B_reg,
            Divisor_mag  => M_reg(3 downto 0),
            Quotient_in  => Q_reg,
            Rem_mag      => R_reg(3 downto 0),
            Quotient_mag => Q_corrected,
            Sign_Q       => Q_sign,
            Remainder    => R_corrected
        );

    Quotient_mag <= Q_corrected;
    Sign_Q       <= Q_sign;
    Remainder    <= R_corrected;

    Done <= '1' when State = FINISH else '0';

end Structural;


