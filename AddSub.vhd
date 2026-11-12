

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity AddSub is
    Port (
        A      : in  STD_LOGIC_VECTOR(3 downto 0);
        B      : in  STD_LOGIC_VECTOR(3 downto 0);
        SUB    : in  STD_LOGIC;
        Result : out STD_LOGIC_VECTOR(4 downto 0)
    );
end AddSub;

architecture Structural of AddSub is

    component RCA5
        Port (
            A     : in  STD_LOGIC_VECTOR(4 downto 0);
            B     : in  STD_LOGIC_VECTOR(4 downto 0);
            C_in  : in  STD_LOGIC;
            Sum   : out STD_LOGIC_VECTOR(4 downto 0);
            Carry : out STD_LOGIC
        );
    end component;

    signal A_ext      : STD_LOGIC_VECTOR(4 downto 0);
    signal B_ext      : STD_LOGIC_VECTOR(4 downto 0);
    signal B_modified : STD_LOGIC_VECTOR(4 downto 0);

begin

    -- Sign Extension
    A_ext <= A(3) & A;
    B_ext <= B(3) & B;

    -- SUB = 0 : B 그대로
    -- SUB = 1 : B 반전
    B_modified <= B_ext xor (4 downto 0 => SUB);

    -- 5-bit Ripple Carry Adder
    U_RCA : RCA5
        port map (
            A     => A_ext,
            B     => B_modified,
            C_in  => SUB,
            Sum   => Result,
            Carry => open
        );

end Structural;
