`timescale 1ns / 1ps

//////////////////////////////////////////////////////////////////////////////////
// Modul wyboru wyswietlacza.
//
// Opis:
// Jest to modul realizujacy krazace 0. Wyswietlacz jest wybierany stanem 0 z
// czestotliwoscia 200 Hz.
//////////////////////////////////////////////////////////////////////////////////
module Wybor_wyswietlacza( input i_CLK,
                           output reg [3:0] or_Wyswietlacze );

    wire CE;
    Prescaler #(.B(19), .Hz(200))OdswiezanieEkranu(i_CLK, 1'b0, CE);

    always @(posedge i_CLK)
        if (CE)
            or_Wyswietlacze = {or_Wyswietlacze[2:0], ~&or_Wyswietlacze[2:0]};

endmodule

//////////////////////////////////////////////////////////////////////////////////
// Modul transkodera kodu BCD na kod wyswietlacza siedmiosegmentowego.
//
// Opis:
// Prosty uklad kombinacyjny, ktorego zadaniem jest zamiana kodu BCD na kod
// wyswietlacza 7 segmentowego.
// Najstarszy bitem jest DP (kropka), natomiast najmlodszym CA.
// W przypadku gdy zostanie podana liczba spoza zakresu nic sie nie wyswietli.
//////////////////////////////////////////////////////////////////////////////////
module Transkoder_BCD_7SEG( input [3:0] i_BCD,
                            output reg [7:0] or_7SEG );

    always @(i_BCD)
        case (i_BCD)
            4'd0 : or_7SEG <= 8'b11000000; // Cyfra 0
            4'd1 : or_7SEG <= 8'b11111001; // Cyfra 1
            4'd2 : or_7SEG <= 8'b10100100; // ...
            4'd3 : or_7SEG <= 8'b10110000;
            4'd4 : or_7SEG <= 8'b10011001;
            4'd5 : or_7SEG <= 8'b10010010;
            4'd6 : or_7SEG <= 8'b10000010;
            4'd7 : or_7SEG <= 8'b11111000; // ...
            4'd8 : or_7SEG <= 8'b10000000; // Cyfra 8
            4'd9 : or_7SEG <= 8'b10010000; // Cyfra 9
            default : or_7SEG <= 8'b11111111; // Cyfra spoza zakresu, wyswietlacz nie bedzie sie swiecil
        endcase

endmodule

//////////////////////////////////////////////////////////////////////////////////
// Modul wyswietlenia cyfry na wybranym wyswietlaczu siedmiosegmentowym.
//
// Opis:
// Uklad kombinacyjny, ktorego zadaniem wyswietlenie odpowiedniej cyfry na wybranym
// wyswietlaczu 7 segmentowym.
// W przypadku gdy wybrano zero lub wiecej ni jeden wyswietlaczy wtedy na
// transkoder BCD zostanie podana liczba spoza zakresu.
//////////////////////////////////////////////////////////////////////////////////
module Wyswietlenie_cyfry( input [12:0] i_Czas,
                           input [3:0] i_Wyswietlacze,
                           output [7:0] o_Segmenty );

    reg [3:0] Wyswietlana_cyfra; // aktualnie wyswietlana liczba
    Transkoder_BCD_7SEG tb7s(Wyswietlana_cyfra, o_Segmenty);

    always @(i_Wyswietlacze or i_Czas)
            case (i_Wyswietlacze)
                4'b1110 : Wyswietlana_cyfra <= (i_Czas%60)%10; // liczba jednosci sekund
                4'b1101 : Wyswietlana_cyfra <= (i_Czas%60)/10; // liczba dziesiatek sekund
                4'b1011 : Wyswietlana_cyfra <= (i_Czas/60)%10; // liczba jednosci minut
                4'b0111 : Wyswietlana_cyfra <= (i_Czas/60)/10; // liczba dziesiatek minut
                default : Wyswietlana_cyfra <= 4'd15; // Cyfra spoza zakresu transkodera
            endcase

endmodule

//////////////////////////////////////////////////////////////////////////////////
// Modul obslugi wyswietlaczy.
//
// Opis:
// Modul laczacy inne moduly odpowiadajace za obsluge wyswietlacza.
// Zawiera instancje 'Wybor_wyswietlacza' oraz 'Wyswietlenie_cyfry'.
//////////////////////////////////////////////////////////////////////////////////
module Obsluga_wyswietlaczy( input i_CLK,
                             input [12:0] i_Czas,
                             output [3:0] o_Wyswietlacze,
                             output [7:0] o_Segmenty );

    Wybor_wyswietlacza ww( .i_CLK(i_CLK),
                            .or_Wyswietlacze(o_Wyswietlacze) );

    Wyswietlenie_cyfry wc( .i_Czas(i_Czas),
                           .i_Wyswietlacze(o_Wyswietlacze),
                           .o_Segmenty(o_Segmenty) );

endmodule
