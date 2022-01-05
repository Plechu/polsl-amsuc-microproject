`timescale 1ns / 1ps

// define'y ulatwiajace dostep do przyciskow
`define Przycisk_O i_Przyciski[4]
`define Przycisk_IS i_Przyciski[3]
`define Przycisk_DS i_Przyciski[2]
`define Przycisk_IM i_Przyciski[1]
`define Przycisk_DM i_Przyciski[0]

//////////////////////////////////////////////////////////////////////////////////
// Modul sprawdzajacy czy przycisk zostal przytrzymany.
//
// Opis:
// Modul sluzy do sprawdzenia czy przycisk zostal nacisniety na czas co najmniej
// 2 sekund. Modul sygnalizuje to wpisujac do wyjscia 'Przycisk_przytrzymany'
// logiczna '1'. W przypadku puszczenia przycisku stan wyjscia zostaje
// zmieniony na '0' w kolejnym takcie zegara.
//////////////////////////////////////////////////////////////////////////////////
module Przytrzymanie_przycisku( input i_CLK,
                                input i_Stan_przycisku,
                                output reg or_Przycisk_przytrzymany );
    
    wire CE;
    Prescaler #(.B(28), .Hz(0.5))dwie_sekundy(i_CLK, !i_Stan_przycisku, CE); // Prescaler zostaje wlaczony w momencie wcisniecia przycisku
    
    always @(posedge i_CLK)
    begin
        if(CE)
            or_Przycisk_przytrzymany = 1'b1;
        
        if(!i_Stan_przycisku)
            or_Przycisk_przytrzymany = 1'b0;
    end
endmodule

//////////////////////////////////////////////////////////////////////////////////
// Modul obslugi przycisku.
//
// Opis:
// Jest to modul odpowiadajacy za eliminacje drgan stykow. Do eliminacji drgan
// uzyto rejestr przesuwajacy taktowany czestotliwoscia 1 kHz. Gdy w rejestrze
// znajda sie trzy '1' na wyjsciu 'o_Impuls' zostanie wygenerowany impuls
// (o dlugosci 1 ms), oraz na wyjsciu 'o_Stan_przycisku' stan bedzie utrzymany do
// puszczenia przycisku.
//////////////////////////////////////////////////////////////////////////////////
module Obsluga_przycisku( input i_CLK,
                          input i_Przycisk,
                          output o_Impuls,
                          output o_Stan_przycisku,
                          output o_Przycisk_przytrzymany );

    reg [4:0] SISO;
    wire CE;

    Prescaler #(.B(17), .Hz(1000))ZegarSISO(i_CLK, 1'b0, CE);

    Przytrzymanie_przycisku pp( .i_CLK(i_CLK),
                                .i_Stan_przycisku(o_Stan_przycisku),
                                .or_Przycisk_przytrzymany(o_Przycisk_przytrzymany) );

    always @(posedge i_CLK)
	begin
		if (CE)
			SISO <= {SISO[3:0], i_Przycisk}; // rejestr przesuwajacy 
	end

	assign o_Impuls = (&SISO[3:0]) & ~SISO[4] & CE;	// generacja pojedynczego impulsu po eliminacji drgan
    assign o_Stan_przycisku = &SISO[3:0]; // stan przycisku po eliminacji drgan
    
endmodule

//////////////////////////////////////////////////////////////////////////////////
// Modul obslugi przyciskow.
//
// Opis:
// Modul laczacy funkcjonalnosci odpowiadajace za obsluge przyciskow.
// Przyjmuje na wejscie stan 5 przyciskow. Przyciski odpowiadajace za
// inkrementacje/dekrementacje czasu sa traktowane w ten sam sposob, wyjatkiem
// jest przycisk odpowiadajacy za odliczanie (z tego powodu sa z nim skojarzone
// dwa osobne wyjscia).
//////////////////////////////////////////////////////////////////////////////////
module Obsluga_przyciskow( input i_CLK,
                           input [4:0] i_Przyciski,
                           output [3:0] o_Przyciski_stan,
                           output o_Przyciski_impuls,
                           output o_Przyciski_przytrzymanie,
                           output o_Przycisk_odliczanie_impuls,
                           output o_Przycisk_odliczanie_przytrzymanie );
    
    // przycisk odliczanie
    wire Stan_O; // zmienna stanu przycisku odliczania
    Obsluga_przycisku opo( .i_CLK(i_CLK),
                           .i_Przycisk(`Przycisk_O),
                           .o_Impuls(o_Przycisk_odliczanie_impuls),
                           .o_Stan_przycisku(Stan_O),
                           .o_Przycisk_przytrzymany(o_Przycisk_odliczanie_przytrzymanie) );
   
    // przycisk inkrementacji sekund
    wire Stan_IS, Impuls_IS, Przytrzymany_IS;
    Obsluga_przycisku opis( .i_CLK(i_CLK),
                            .i_Przycisk(`Przycisk_IS),
                            .o_Impuls(Impuls_IS),
                            .o_Stan_przycisku(Stan_IS),
                            .o_Przycisk_przytrzymany(Przytrzymany_IS) );
    
    // przycisk dekrementacji sekund
    wire Stan_DS, Impuls_DS, Przytrzymany_DS;
    Obsluga_przycisku opds( .i_CLK(i_CLK),
                            .i_Przycisk(`Przycisk_DS),
                            .o_Impuls(Impuls_DS),
                            .o_Stan_przycisku(Stan_DS),
                            .o_Przycisk_przytrzymany(Przytrzymany_DS) );                              

    // przycisk inkrementacji minut
    wire Stan_IM, Impuls_IM, Przytrzymany_IM;
    Obsluga_przycisku opim( .i_CLK(i_CLK),
                            .i_Przycisk(`Przycisk_IM),
                            .o_Impuls(Impuls_IM),
                            .o_Stan_przycisku(Stan_IM),
                            .o_Przycisk_przytrzymany(Przytrzymany_IM) );

    // przycisk dekrementacji minut
    wire Stan_DM, Impuls_DM, Przytrzymany_DM;
    Obsluga_przycisku opdm( .i_CLK(i_CLK),
                            .i_Przycisk(`Przycisk_DM),
                            .o_Impuls(Impuls_DM),
                            .o_Stan_przycisku(Stan_DM),
                            .o_Przycisk_przytrzymany(Przytrzymany_DM) );

    // wyjscia zwiazane z przyciskami
    assign o_Przyciski_stan = {Stan_IS, Stan_DS, Stan_IM, Stan_DM}; // wektor przechowujacy informaje o stabilnym stanie przyciskow inkrementacji/dekrementacji
    assign o_Przyciski_impuls = Impuls_IS | Impuls_DS | Impuls_IM | Impuls_DM; // jesli ktoryskolwiek przycisk zostal nacisniety
    assign o_Przyciski_przytrzymanie = Przytrzymany_IS | Przytrzymany_DS | Przytrzymany_IM | Przytrzymany_DM; // jesli ktoryskolwiek przycisk zostal przytrzymany

endmodule
