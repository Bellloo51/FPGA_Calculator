
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity Euclidean_Corrector is
    Port (
        Sign_A        : in  STD_LOGIC;
        Sign_B        : in  STD_LOGIC;
        Divisor_mag   : in  STD_LOGIC_VECTOR(3 downto 0);
        Quotient_in   : in  STD_LOGIC_VECTOR(3 downto 0);
        Rem_mag       : in  STD_LOGIC_VECTOR(3 downto 0);

        Quotient_mag  : out STD_LOGIC_VECTOR(3 downto 0);
        Sign_Q        : out STD_LOGIC;
        Remainder     : out STD_LOGIC_VECTOR(3 downto 0)
    );
end Euclidean_Corrector;

architecture Structural of Euclidean_Corrector is

    component RCA5
        Port (
            A     : in  STD_LOGIC_VECTOR(4 downto 0);
            B     : in  STD_LOGIC_VECTOR(4 downto 0);
            C_in  : in  STD_LOGIC;
            Sum   : out STD_LOGIC_VECTOR(4 downto 0);
            Carry : out STD_LOGIC
        );
    end component;

    signal Adjust        : STD_LOGIC;

    signal Q_extended    : STD_LOGIC_VECTOR(4 downto 0);
    signal Q_increment   : STD_LOGIC_VECTOR(4 downto 0);
    signal Q_adjusted    : STD_LOGIC_VECTOR(4 downto 0);

    signal Divisor_ext   : STD_LOGIC_VECTOR(4 downto 0);
    signal Rem_extended  : STD_LOGIC_VECTOR(4 downto 0);
    signal Rem_inverted  : STD_LOGIC_VECTOR(4 downto 0);
    signal R_sub         : STD_LOGIC_VECTOR(4 downto 0);

begin

    Adjust <= '1' when
        Sign_A = '1' and
        Rem_mag /= "0000" and
        Divisor_mag /= "0000"
        else '0';

    Q_extended  <= '0' & Quotient_in;
    Q_increment <= "0000" & Adjust;

    U_Q_Adjust : RCA5
        port map (
            A     => Q_extended,
            B     => Q_increment,
            C_in  => '0',
            Sum   => Q_adjusted,
            Carry => open
        );

    Divisor_ext  <= '0' & Divisor_mag;
    Rem_extended <= '0' & Rem_mag;
    Rem_inverted <= not Rem_extended;

    U_R_Adjust : RCA5
        port map (
            A     => Divisor_ext,
            B     => Rem_inverted,
            C_in  => '1',
            Sum   => R_sub,
            Carry => open
        );

    Quotient_mag <= "0000"
                    when Divisor_mag = "0000"
                    else Q_adjusted(3 downto 0);

    Sign_Q <= '0'
              when Divisor_mag = "0000" or
                   Q_adjusted = "00000"
              else Sign_A xor Sign_B;

    Remainder <= "0000"
                 when Divisor_mag = "0000"
                 else R_sub(3 downto 0)
                 when Adjust = '1'
                 else Rem_mag;

end Structural;
