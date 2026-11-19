
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity Multiplier is
    Port (
        Clk          : in  STD_LOGIC;
        Reset        : in  STD_LOGIC;
        Start        : in  STD_LOGIC;
        A            : in  STD_LOGIC_VECTOR(3 downto 0);
        B            : in  STD_LOGIC_VECTOR(3 downto 0);
        Product      : out STD_LOGIC_VECTOR(7 downto 0);
        Sign_Product : out STD_LOGIC;
        Done         : out STD_LOGIC
    );
end Multiplier;

architecture Structural of Multiplier is

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

    type State_Type is (IDLE, CALC, FINISH);
    signal State : State_Type := IDLE;

    signal A_mag : STD_LOGIC_VECTOR(3 downto 0);
    signal B_mag : STD_LOGIC_VECTOR(3 downto 0);

    signal A_reg : STD_LOGIC_VECTOR(4 downto 0);
    signal M_reg : STD_LOGIC_VECTOR(4 downto 0);
    signal Q_reg : STD_LOGIC_VECTOR(3 downto 0);

    signal B_add : STD_LOGIC_VECTOR(4 downto 0);
    signal Sum   : STD_LOGIC_VECTOR(4 downto 0);
    signal Carry : STD_LOGIC;

    signal Sign_reg : STD_LOGIC := '0';
    signal Count    : STD_LOGIC_VECTOR(1 downto 0) := "00";

begin

    U_ABS_A : negative_complement
        port map (
            A_in  => A,
            A_out => A_mag
        );

    U_ABS_B : negative_complement
        port map (
            A_in  => B,
            A_out => B_mag
        );

    B_add <= M_reg when Q_reg(0) = '1'
             else "00000";

    U_RCA : RCA5
        port map (
            A     => A_reg,
            B     => B_add,
            C_in  => '0',
            Sum   => Sum,
            Carry => Carry
        );

    process(Clk, Reset)
    begin
        if Reset = '1' then
            State <= IDLE;
            A_reg <= (others => '0');
            M_reg <= (others => '0');
            Q_reg <= (others => '0');
            Sign_reg <= '0';
            Count <= "00";

        elsif rising_edge(Clk) then
            case State is

                when IDLE =>
                    if Start = '1' then
                        A_reg <= (others => '0');
                        M_reg <= '0' & A_mag;
                        Q_reg <= B_mag;
                        Count <= "00";

                        if A_mag = "0000" or
                           B_mag = "0000" then
                            Sign_reg <= '0';
                        else
                            Sign_reg <= A(3) xor B(3);
                        end if;

                        State <= CALC;
                    end if;

                when CALC =>
                    A_reg <= Carry & Sum(4 downto 1);
                    Q_reg <= Sum(0) & Q_reg(3 downto 1);

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

    Product <= A_reg(3 downto 0) & Q_reg;

    Sign_Product <= Sign_reg;

    Done <= '1' when State = FINISH else '0';

end Structural;

