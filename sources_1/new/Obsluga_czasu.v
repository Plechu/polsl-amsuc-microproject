`timescale 1ns / 1ps

// define'y ulatwiajace dostep do przyciskow
`define Bity_Przycisk_IS 4'b1000
`define Bity_Przycisk_DS 4'b0100
`define Bity_Przycisk_IM 4'b0010
`define Bity_Przycisk_DM 4'b0001

//////////////////////////////////////////////////////////////////////////////////
// Modul wykonujacy operacje na czasie.
//
// Opis:
// Modul sluzy do wykonania takich operacji na czasie jak inkrementacja/dekrementacja
// sekund lub minut. Modul pilnuje rowniez zakresow (Maksymalny czas do nastawienia
// to 99 minut i 59 sekund (5999 sekund)). Gdy gdy uzytkownik operuje wiecej niz
// jednym przyciskiem na raz, to wtedy zadna operacja nie jest wykonywana.
//////////////////////////////////////////////////////////////////////////////////
module Operacje_czasowe( input i_CLK,
                         input i_CE,
                         input i_Reset,
                         input [3:0] i_Przyciski_stan,
                         output reg [12:0] or_Czas );

    always @(posedge i_CLK)
    begin
        if (i_Reset)
                or_Czas <= 13'd0;
        else
        if (i_CE)
        begin
            if ( |{(i_Przyciski_stan == `Bity_Przycisk_IS && or_Czas == 5999),
                   (i_Przyciski_stan == `Bity_Przycisk_IM && or_Czas >= 5940),
                   (i_Przyciski_stan == `Bity_Przycisk_DS && or_Czas == 0),
                   (i_Przyciski_stan == `Bity_Przycisk_DM && or_Czas <= 59)} )
                or_Czas <= or_Czas;
            else
            case (i_Przyciski_stan)
                `Bity_Przycisk_IS : or_Czas <= or_Czas + 1;
                `Bity_Przycisk_DS : or_Czas <= or_Czas - 1;
                `Bity_Przycisk_IM : or_Czas <= or_Czas + 60;
                `Bity_Przycisk_DM : or_Czas <= or_Czas - 60;
                default : or_Czas <= or_Czas;
            endcase
        end
    end
endmodule

//////////////////////////////////////////////////////////////////////////////////
// Modul obslugi czasu.
//
// Opis:
// Modul laczacy funkcjonalnosci odpowiadajace za obsluge czasu.
// Modul zawiera prescalery 1 Hz oraz 10 Hz, multiplekser zegarow dzialacy 
// w zaleznosci od wejsc oraz stanu minutnika, instancje modulu 'Operacje_czasowe'
// i obsluge stanu minutnika (nastawianie/odliczanie)
//////////////////////////////////////////////////////////////////////////////////
module Obsluga_czasu( input i_CLK,
                      input [3:0] i_Przyciski_stan,
                      input i_Przyciski_impuls,
                      input i_Przyciski_przytrzymanie,
                      input i_Przycisk_odliczanie_impuls,
                      input i_Reset,
                      output [12:0] o_Czas );
    
    reg odliczanie; // zmienna przechowyjaca informacje o stanie minutnika
    wire CE_1Hz, CE_10Hz, CE_mux;

    Prescaler sekunda(i_CLK, !odliczanie, CE_1Hz);
    Prescaler #(.B(24), .Hz(10))dziesiec_na_sekunde(i_CLK, 1'b0, CE_10Hz);

    // multiplekser CE w zaleznosci od scenariusza.
    assign CE_mux = ( (i_Przyciski_przytrzymanie ^ i_Przyciski_impuls) && !odliczanie) ? ( (i_Przyciski_impuls) ? i_Przyciski_impuls : CE_10Hz ) : CE_1Hz; 
    
    Operacje_czasowe oc( .i_CLK(i_CLK),
                         .i_CE(CE_mux),
                         .i_Reset(i_Reset),
                         .i_Przyciski_stan( (odliczanie) ? `Bity_Przycisk_DS : i_Przyciski_stan ), // gdy odliczanie trwa, mozliwa jest tylko operacja dekrementacji sekund
                         .or_Czas(o_Czas) );

    always @(posedge i_CLK)
    begin
         if (i_Przycisk_odliczanie_impuls) 
            odliczanie <= ~odliczanie;
         if ( odliczanie && (o_Czas == 13'd0) )
            odliczanie <= 1'b0;
    end
    
endmodule
