
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity negative_complement is
    Port (
        A_in  : in  STD_LOGIC_VECTOR(3 downto 0);
        A_out : out STD_LOGIC_VECTOR(3 downto 0)
    );
end negative_complement;

architecture Structural of negative_complement is

    component RCA5
        Port (
            A     : in  STD_LOGIC_VECTOR(4 downto 0);
            B     : in  STD_LOGIC_VECTOR(4 downto 0);
            C_in  : in  STD_LOGIC;
            Sum   : out STD_LOGIC_VECTOR(4 downto 0);
            Carry : out STD_LOGIC
        );
    end component;

    signal Sign_bit : STD_LOGIC;
    signal A_modified : STD_LOGIC_VECTOR(3 downto 0);
    signal A_extended : STD_LOGIC_VECTOR(4 downto 0);
    signal Result_5bit : STD_LOGIC_VECTOR(4 downto 0);

begin

    Sign_bit <= A_in(3);

    -- 양수: A 그대로 / 음수: A 반전
    A_modified <= A_in xor (3 downto 0 => Sign_bit);

    -- 5비트 RCA에 입력하기 위한 확장
    A_extended <= '0' & A_modified;

    U_RCA : RCA5
        port map (
            A     => A_extended,
            B     => "00000",
            C_in  => Sign_bit,
            Sum   => Result_5bit,
            Carry => open
        );

    -- 절댓값은 0~8이므로 하위 4비트 출력
    A_out <= Result_5bit(3 downto 0);

end Structural;
