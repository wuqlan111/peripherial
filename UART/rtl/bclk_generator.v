
/********************************************************************
* Module Name:     bclk_generator
* Author:          wuqlan
* Email:           
* Date Created:    2023/4/12
* Description:     UART bclk generator module.
*                  
*
* Version:         0.1
***********************************************************************/

module  sck_generator(
    input   clk_in,
    input   enable_in,
    input   rstn_in,
    output  reg  bclk_out,
    input   [15: 0]  divisor
);


reg   [11: 0]  counter;
reg   top_half;

wire  [11: 0]  half_counter;
wire  change_clk;
wire  top_half_end;
wire  next_half_end;


/*----get half counter----*/
always @(clk_in or rstn_in) begin
    if (!rstn_in ) begin
        counter        <=    0;
        bclk_out       <=    1;
        top_half       <=    1;
    end
    else begin
        counter       <=     enable_in?  (counter + 1):  0;
        bclk_out      <=     enable_in && change_clk ? ~bclk_out:  bclk_out;
        top_half      <=     enable_in && change_clk ? ~top_half:  top_half;
    end
end



assign   half_counter  =   divisor >> 1;
assign   change_clk    =   top_half_end || next_half_end?  1:  0;
assign   top_half_end  =   top_half && ((half_counter + divisor[0]) == counter) ? 1:  0;
assign   next_half_end  =  !top_half && (half_counter ==  counter) ? 1:  0;

endmodule




