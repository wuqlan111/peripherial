
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
    input   spc0_in,
    input   [7: 0]  spi_cr1_in,
    input   spie_in,
    input   [2: 0]  sppr,
    input   [2: 0]  spr,
    input   sptie_in,

    /*-------control signal----------*/
    input   new_tx_in,
    output  finished_out,

    /*------spi signal------*/
    input   miso_in,
    output  mosi_out,
    output  sck_out,
    input   ss_in,
    output  reg  ss_out
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
localparam   STATE_RST           =   3'd0;
localparam   STATE_DISABLE       =   3'd1;
localparam   STATE_WAIT          =   3'd2;    
localparam   STATE_IDLE          =   3'd3;
localparam   STATE_TRANS         =   3'd4;
localparam   STATE_FINISH        =   3'd5;


reg  [2: 0]  spi_state;
reg  [2: 0]  next_state;

reg  [3: 0]  edge_counter;
reg  start_trans;
reg  end_trans;

reg  last_finished;

wire  mode_fault;




/*--------FSM-----------*/
always @(*) begin
    next_state  =  0;
    if (!rstn_in)
        next_state   =  STATE_RST;
    else begin
        case (spi_state)
            STATE_RST || STATE_DISABLE : begin
                if (!spi_cr1_in[CR1_SPE] )
                    next_state   =   STATE_DISABLE;
                else  if  (new_tx_in || !last_finished)
                    next_state   =   STATE_TRANS;
                else
                    next_state   =   STATE_IDLE;

            end

            STATE_WAIT:  begin
                if (!spi_cr1_in[CR1_SPE] )
                    next_state   =   STATE_DISABLE;
                else  if  (spi_cr1_in[CR1_SPISWAI] )
                    next_state   =   STATE_WAIT;
                else if ( last_finished )
                    next_state   =   STATE_IDLE;
                else
                    next_state   =   STATE_TRANS;
            end


            STATE_IDLE: begin
                if (!spi_cr1_in[CR1_SPE])
                    next_state       =   STATE_DISABLE;
                else  if  (spi_cr1_in[CR1_SPISWAI] )
                    next_state   =   STATE_WAIT;
                else  if (new_tx_in)
                    next_state       =   STATE_TRANS;
                else
                    next_state       =   STATE_IDLE;
            end


            STATE_TRANS: begin
                if (!spi_cr1_in[CR1_SPE])
                    next_state       =  STATE_DISABLE;
                else  if  (spi_cr1_in[CR1_SPISWAI] )
                    next_state   =   STATE_WAIT;
                else  if  ( edge_counter ==  15 )
                    next_state   =   STATE_FINISH;
                else
                    next_state   =   STATE_TRANS;

            end


            STATE_FINISH:  begin
                if (!spi_cr1_in[CR1_SPE])
                    next_state       =  STATE_DISABLE;
                else  if  (spi_cr1_in[CR1_SPISWAI] )
                    next_state   =   STATE_WAIT;
                else  if  ( new_tx_in )
                    next_state   =   STATE_TRANS;
                else
                    next_state   =   STATE_IDLE;

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
        edge_counter            <=    0;
        end_trans               <=    0;
        last_finished           <=    1;        
        start_trans             <=    0;
        ss_out                  <=    1;
        
    end
    else  begin
        case (spi_state)
            STATE_RST || STATE_IDLE: begin
                edge_counter            <=    0;
                end_trans               <=    0;
                last_finished           <=    1;
                start_trans             <=    0;
                ss_out                  <=    1;
            end


            STATE_DISABLE:  begin

            end

            STATE_WAIT:  begin
                //sck_enable <=  0;

            end

            STATE_TRANS:  begin
                if (edge_counter &&  last_finished ) begin
                    edge_counter      <=    0;
                    ss_out            <=    0;
                    last_finished     <=    0;
                end
                else 
                end

            end

            STATE_FINISH:  begin
                last_finished          <=    1;
            end


            default:    ;

        endcase
                
    end
end


assign   mode_fault  =  (spi_cr1_in[CR1_MODFEN] && !spi_cr1_in[CR1_SSOE] && !ss_in)? 1:  0;



endmodule


