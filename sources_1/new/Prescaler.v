`timescale 1ns / 1ps

//////////////////////////////////////////////////////////////////////////////////
// Modul prescalera.
//
// Opis:
// Prescaler generuje 10 ns impulsy z zadana czestotliwoscia.
// Domyslnie prescaler generuje impulsy z czestotliwoscia 1 s.
//////////////////////////////////////////////////////////////////////////////////
module Prescaler(i_CLK, i_Reset, o_CEO);
parameter B = 27;
parameter Hz = 1;
input i_CLK, i_Reset;
output o_CEO;
    reg [(B-1):0] Q;
    reg MCV = (1e08 / Hz) - 1;

    always @(posedge i_CLK or posedge i_Reset)
        if(i_Reset)
            Q <= {(B-1){1'b0}};
        else begin
                if(Q != MCV)
                    Q <= Q + 1;
                else
                    Q <= {(B-1){1'b0}};
        end
    assign o_CEO = (Q == MCV );
endmodule
