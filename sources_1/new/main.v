//////////////////////////////////////////////////////////////////////////////////
// Algorytmiczne metody syntezy ukladow cyfrowych
//
// Temat projektu: Minutnik
//
// Sklad sekcji:
//   - Lukasz Plech
//   - Grzegorz Mrozek
//////////////////////////////////////////////////////////////////////////////////

`timescale 1ns / 1ps

//////////////////////////////////////////////////////////////////////////////////
// Modul main laczacy wszystkie funkcjonalnosci minutnika.
//
// Opis:
// Mozna wyroznic 5 scenariuszy pracy ukladu:
//     * Nastawianie minutnika klikajac przyciski - czas jest inkrementowany lub
//       dekrementowany zgodnie z wola uzytkownika w momencie naciskania przycisku.
//
//     * Nastawianie minutnika przytrzymujac przycisk -  czas jest inkrementowany
//       lub dekrementowany zgodnie z wola uzytkownika z czestotliwoscia 10 Hz po
//       przytrzymaniu przycisku na co najmniej 2 sekundy. 
//
//     * Wlaczenie minutnika - po nacisnieciu przycisku odliczania nastepuje
//       zliczanie od zadanej wartosci do zera z czestotliwoscia 1Hz.
//
//     * Wylaczanie minutnika - podczas zliczania w dol uzytkownik naciskajac
//       ponownie przycisk odliczania zatrzyma minutnik.
//
//     * Reset minutnika - przytrzymujac przycisk odliczania na co najmniej
//       2 sekundy uzytkownik zresetuje timer.
//
// Podczas gdy minutnik jest w trakcie pracy, nie jest mozliwe wykonywanie 
// operacji na czasie. Jest to ponownie mozliwe w momencie skonczenia odliczania
// lub po zatrzymaniu minutnika.
//////////////////////////////////////////////////////////////////////////////////

module main( input CLK,
             input Przycisk_odliczania,
             input Przycisk_inkrementacji_sekund,
             input Przycisk_dekrementacji_sekund,
             input Przycisk_inkrementacji_minut,
             input Przycisk_dekrementacji_minut,
             output [7:0] Segmenty,
             output [3:0] Wyswietlacze,
             output [3:0] Wylaczone_wyswietlacze );

    //assign Wylaczone_wyswietlacze = 4'b1111; // wylaczenie nieuzywanych wyswietlaczy
    wire [4:0] Przyciski = { Przycisk_odliczania,
                             Przycisk_inkrementacji_sekund,
                             Przycisk_dekrementacji_sekund,
                             Przycisk_inkrementacji_minut,
                             Przycisk_dekrementacji_minut };
    wire [12:0] Czas;
    wire [3:0] Przyciski_stan;
    wire Przycisk_odliczanie_impuls, Przyciski_impuls, Przyciski_przytrzymanie, Reset;

    Obsluga_wyswietlaczy oe( .i_CLK(CLK),
                             .i_Czas(Czas),
                             .o_Wyswietlacze(Wyswietlacze),
                             .o_Segmenty(Segmenty) );
    
    Obsluga_przyciskow op( .i_CLK(CLK),
                           .i_Przyciski(Przyciski),
                           .o_Przyciski_stan(Przyciski_stan),
                           .o_Przyciski_impuls(Przyciski_impuls),
                           .o_Przyciski_przytrzymanie(Przyciski_przytrzymanie),
                           .o_Przycisk_odliczanie_impuls(Przycisk_odliczanie_impuls),
                           .o_Przycisk_odliczanie_przytrzymanie(Reset) );
    
    Obsluga_czasu oc( .i_CLK(CLK),
                      .i_Przyciski_stan(Przyciski_stan),
                      .i_Przyciski_impuls(Przyciski_impuls),
                      .i_Przyciski_przytrzymanie(Przyciski_przytrzymanie),
                      .i_Przycisk_odliczanie_impuls(Przycisk_odliczanie_impuls),
                      .i_Reset(Reset),
                      .o_Czas(Czas) );

endmodule