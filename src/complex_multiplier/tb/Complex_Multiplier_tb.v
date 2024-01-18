
`timescale 1ns/1ps
module tb () ;
    parameter input_signed = 1'b0 ; 
    parameter INR = 1'b0 ; 
    parameter OUTR = 1'b1 ; 
    parameter PIPER = 1'b0 ; 
    parameter N = 8 ; 
    parameter RESET_MODE = "SYNC" ; 
    parameter mul = ((N <= 9) ? 9 : ((N <= 18) ? 18 : 36)) ; 
    reg signed [(N - 1):0] real1, real2, imag1, imag2 ; 
    reg clk, rst ; 
    reg ce ; 
    reg signed [(mul + mul):0] golden_realo, golden_imago ; 
    reg signed [(mul + mul):0] golden_realo_T, golden_imago_T ; 
    reg signed [(mul + mul):0] golden_realo_2T, golden_imago_2T ; 
    reg signed [(mul + mul):0] golden_realo_3T, golden_imago_3T ; 
    wire signed [(mul + mul):0] realo, imago ; 
    wire valid_flag ; 
    reg [1:0] valid_cnt ; 
    integer delay = ((INR + OUTR) + PIPER) ; 
    assign valid_flag = (valid_cnt == delay) ; 
    reg signed [(N - 1):0] numArray [0:3] ; 
    reg [7:0] cnt = 0 ; 
    reg result ; 
    GSR GSR (.GSRI(1'b1)) ; 
    always
        @(posedge clk)
        begin
            cnt <=  (cnt + 1) ;
        end
    always
        @(posedge clk or posedge rst)
        begin
            if (rst) 
                valid_cnt <=  0 ;
            else
                if ((valid_cnt == delay)) 
                    valid_cnt <=  valid_cnt ;
                else
                    valid_cnt <=  (valid_cnt + 1) ;
        end
    initial
        begin
            numArray[0] = 0 ;
            numArray[1] = 0 ;
            numArray[2] = ({1'b0,{(N - 1){1'b1}}} / 2) ;
            numArray[3] = {1'b0,{(N - 1){1'b1}}} ;
        end
    always
        @(posedge clk)
        begin
            #(0.1) ;
            real1 = numArray[cnt[1:0]] ;
            imag1 = numArray[cnt[3:2]] ;
            real2 = numArray[cnt[5:4]] ;
            imag2 = numArray[cnt[7:6]] ;
            golden_realo = ((real1 * real2) - (imag1 * imag2)) ;
            golden_imago = ((real1 * imag2) + (real2 * imag1)) ;
        end
    always
        @(posedge clk)
        begin
            golden_realo_T <=  golden_realo ;
            golden_imago_T <=  golden_imago ;
        end
    always
        @(posedge clk)
        begin
            golden_realo_2T <=  golden_realo_T ;
            golden_imago_2T <=  golden_imago_T ;
        end
    always
        @(posedge clk)
        begin
            golden_realo_3T <=  golden_realo_2T ;
            golden_imago_3T <=  golden_imago_2T ;
        end
    always
        @(posedge clk)
        begin
            if ((!ce)) 
                begin
                    result <=  1 ;
                end
            else
                begin
                    if ((!valid_flag)) 
                        result <=  1 ;
                    else
                        if ((!result)) 
                            result <=  0 ;
                        else
                            if ((((delay == 0) && (golden_realo == realo)) && (golden_imago == imago))) 
                                result <=  1 ;
                            else
                                if ((((delay == 1) && (golden_realo_T == realo)) && (golden_imago_T == imago))) 
                                    result <=  1 ;
                                else
                                    if ((((delay == 2) && (golden_realo_2T == realo)) && (golden_imago_2T == imago))) 
                                        result <=  1 ;
                                    else
                                        if ((((delay == 3) && (golden_realo_3T == realo)) && (golden_imago_3T == imago))) 
                                            result <=  1 ;
                                        else
                                            result <=  0 ;
                end
        end
    initial
        begin
            clk = 0 ;
            ce = 0 ;
            rst = 1 ;
            #(40) ce = 1 ;
            rst = 0 ;
            #(10000) ;
            if ((result == 1)) 
                $display ("result=true") ;
            else
                $display ("result=false") ;
            $stop  ;
        end
    always
        begin
            #(10) clk = (~clk) ;
        end
    Complex_Multiplier_Top u1 (.clk(clk), .reset(rst), .ce(ce), .real1(real1), .real2(real2), .imag1(imag1), .imag2(imag2), .realo(realo), .imago(imago)) ; 
endmodule


