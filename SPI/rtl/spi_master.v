
/****************************************************************************************
* Module Name:     spi_master
* Author:          wuqlan
* Email:           
* Date Created:    2023/4/2
* Description:     SPI core module.
*                  
*
* Version:         0.1
*****************************************************************************************/
module spi_master (

    /*-------system clk and reset signal*/
    input  clk_in,
    input  rstn_in,

    /*-------ctrl regs--------*/
    input   bidiroe_in,
    input   errie_in,
    output  modf_out,
    output  ovrf_out,      
    input   spc0_in,
    input   [7: 0]  spi_cr1_in,
    input   spie_in,
    output  spif_out,    
    input   [2: 0]  sppr,
    input   [2: 0]  spr,
    output  sptef_out,
    input   sptie_in,


    /*------spi signal------*/
    input   miso_in,
    output  mosi_out,
    output  sck_out,
    input   ss_in,
    output  ss_out
);

/*-------SPI_CR1 Filed------------*/
localparam  CR1_SPE         =    7;
localparam  CR1_MTSR        =    6;
localparam  CR1_CPOL        =    5;
localparam  CR1_CPHA        =    4;
localparam  CR1_SSOE        =    3;
localparam  CR1_LSBFE       =    2;
localparam  CR1_MODFEN      =    1;
localparam  CR1_SPISWAI     =    0;



/*------------spi state-------------*/
localparam   STATE_RST        =   3'd0;
localparam   STATE_DISABLE    =   3'd1;
localparam   STATE_WAIT       =   3'd2;
localparam   STATE_TRANS      =   3'd3;
localparam   STATE_FINISH     =   3'd4;



reg  [2: 0]  spi_state;
reg  [2: 0]  next_state;



/*--------FSM-----------*/
always @(*) begin
    next_state  =  0;
    if (!rstn_in)
        next_state   =  STATE_RST;
    else begin
        case (spi_state)
            STATE_RST: begin
                



            end


            STATE_WAIT: begin
                




            end



            STATE_TRANS: begin
                




            end



            STATE_FINISH:  begin
                





            end


            default:  next_state  =  STATE_RST;

        endcase

    end

end

always @(posedge clk_in or negedge rstn_in) begin
    if (!rstn_in)
        spi_state       <=    STATE_RST;
    else
        spi_state       <=    next_state;
end





/*-----------data control---------------*/
always @(posedge clk_in or negedge rstn_in) begin
    if (!rstn_in) begin
        
    end
    else  begin
        






    end
end


endmodule


