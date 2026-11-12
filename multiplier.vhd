
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
--이것은 unsigned 곱셈기이다.
entity Multiplier is
    Port (
        Clk     : in STD_LOGIC; --레지스터를 갱신
        Reset   : in STD_LOGIC; --회로 초기화
        Start   : in STD_LOGIC; --곱셈 시작
        M_in    : in STD_LOGIC_VECTOR(3 downto 0); --절대값처리를 해야함
        Q_in    : in STD_LOGIC_VECTOR(3 downto 0);
        Product : out STD_LOGIC_VECTOR(7 downto 0);--8비트 곱셈의 결과
        Done    : out STD_LOGIC --곱셈완료 신호
    );
end Multiplier;
--  M_in  Q_in 은 negative_complement를 거친 값들이 들어와야함
architecture Structural of Multiplier is

    component RCA5
        Port (
            A     : in STD_LOGIC_VECTOR(4 downto 0);
            B     : in STD_LOGIC_VECTOR(4 downto 0);
            C_in  : in STD_LOGIC;
            Sum   : out STD_LOGIC_VECTOR(4 downto 0);
            Carry : out STD_LOGIC
        );
    end component;
--idle는 start=1이면 calc로 이동//calc에서 4번 계산 수행 이후 finish로 이동
    type State_Type is (IDLE, CALC, FINISH);
    signal State : State_Type := IDLE;
--만약 3*5 계산이면
    signal A_reg : STD_LOGIC_VECTOR(4 downto 0);--여기가 부분결과값
    signal M_reg : STD_LOGIC_VECTOR(4 downto 0);--여기는 3
    signal Q_reg : STD_LOGIC_VECTOR(3 downto 0);--여기는 5

    signal B_add  : STD_LOGIC_VECTOR(4 downto 0);--RCA5에서 A에 더할 값
    signal Sum    : STD_LOGIC_VECTOR(4 downto 0);--최종 덧셈 결과
    signal Carry  : STD_LOGIC; --최종 carry out

    signal Count : std_logic_vector(1 downto 0) := "00";--counter(00 01 10 11)

begin

    -- Q의 최하위 비트가 1일 때만 M을 더함
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

    -- 순차회로: 레지스터와 FSM
    process(Clk, Reset)
    begin
        if Reset = '1' then
        -- 초가화
            State <= IDLE;
            A_reg <= (others => '0');-- others => every bit to 0
            M_reg <= (others => '0');
            Q_reg <= (others => '0');
            Count <= "00";

        elsif rising_edge(Clk) then
            case State is

                when IDLE =>
                    if Start = '1' then
                        A_reg <= (others => '0');
                        M_reg <= '0' & M_in; --여기서 '0'랑
                        Q_reg <= Q_in;
                        Count <= "00";
                        State <= CALC;
                    end if;

                when CALC =>
                    -- Add 결과를 포함하여 Right Shift
                    A_reg <= Carry & Sum(4 downto 1);
                    Q_reg <= Sum(0) & Q_reg(3 downto 1);

                  if Count = "11" then
                         State <= FINISH;
                  else
                         Count <= (Count(1) xor Count(0))
                                    & (not Count(0));-- count(1)==count(1) 직합 count(0)//count(0)==~count(0)
                  end if;

                when FINISH =>
                    if Start = '0' then
                        State <= IDLE;
                    end if;

            end case;
        end if;
    end process;

    Product <= A_reg(3 downto 0) & Q_reg;
    Done <= '1' when State = FINISH else '0';

end Structural;
