
/********************************************************************
* Module Name:     sck_generator
* Author:          wuqlan
* Email:           
* Date Created:    2023/4/2
* Description:     SPI sck generator module.
*                  
*
* Version:         0.1
***********************************************************************/

module  sck_generator(
    input   clk_in,
    input   cpol_in,
    input   enable_in,
    input   rstn_in,
    output  reg  sck_out,
    input   [2: 0]  sppr_in,
    input   [2: 0]  spr_in
);


wire  [11: 0]  half_counter;
wire  change_clk;
reg   [11: 0]  counter;  

/*----get half counter----*/
always @(clk_in or rstn_in) begin
    if (!rstn_in ) begin
        counter       <=    0;
        sck_out       <=    cpol_in? 0: 1;
    end
    else begin
        counter       <=    enable_in?  (counter + 1):  0;
        sck_out       <=    enable_in && change_clk ? ~sck_out:  (cpol_in? 0: 1);
    end
end



assign   half_counter  =   ( sppr_in + 1) << ( spr_in + 1);
assign   change_clk    =   (counter  ==  half_counter);

endmodule




