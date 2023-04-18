
/********************************************************************
* Module Name:     i2c_generator
* Author:          wuqlan
* Email:           
* Date Created:    2023/4/18
* Description:     I2C sck generator module.
*                  
*
* Version:         0.1
***********************************************************************/

module  i2c_generator(
    input   clk_in,
    input   rstn_in,
    output  reg  sck_out,
    input   [5: 0]  dividor_in,
    input   [9: 0]  ccr_in
);


wire  [11: 0]  half_counter;
wire  change_clk;
reg   [11: 0]  counter;  

/*----get half counter----*/
always @(posedge  clk_in or  negedge rstn_in) begin
    if (!rstn_in ) begin
        counter       <=    0;
        sck_out       <=    0;
    end
    else begin
        counter       <=    enable_in?  (counter + 1):  0;
        sck_out       <=    enable_in && change_clk ? ~sck_out:  0;
    end
end



assign   half_counter  =   ( sppr_in + 1) << ( spr_in + 1);
assign   change_clk    =   (counter  ==  half_counter);

endmodule


