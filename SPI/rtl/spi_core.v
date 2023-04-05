
/****************************************************************************************
* Module Name:     spi_core
* Author:          wuqlan
* Email:           
* Date Created:    2023/4/2
* Description:     SPI core module.
*                  
*
* Version:         0.1
*****************************************************************************************/
module spi_core (

    /*-------system clk and reset signal*/
    input  clk_in,
    input  rstn_in,

    /*-------ctrl regs--------*/
    input   bidiroe_in,
    input   errie_in,
    input   spc0_in,
    input   [7: 0]  spi_cr1_in,
    input   [7: 0]  spi_dr_in,
    input   spie_in,
    input   [2: 0]  sppr,
    input   [2: 0]  spr,
    input   sptie_in,
    output  [7: 0]  shift_out,

    /*-------control signal----------*/
    input   new_tx_in,
    output  finished_out,

    /*------spi signal------*/
    input   serial_in,
    output  serial_out,
    input   sck_in,
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

reg  sck_temp;
reg  start_trans;
reg  end_trans;

reg  last_finished;

reg  shift_enable;

wire  mode_fault;
wire  sck;
wire  sck_enable;
wire  shift_sck;
wire  trans_valid;
wire  spi_stop;
wire  spi_wait;

/*--------FSM-----------*/
always @(*) begin
    next_state  =  0;
    if (!rstn_in)
        next_state   =  STATE_RST;
    else begin
        case (spi_state)
            STATE_RST || STATE_DISABLE : begin
                if (spi_stop)
                    next_state   =   STATE_DISABLE;
                else  if  (new_tx_in || !last_finished)
                    next_state   =   STATE_TRANS;
                else
                    next_state   =   STATE_IDLE;

            end

            STATE_WAIT:  begin
                if (spi_stop)
                    next_state   =   STATE_DISABLE;
                else  if  (spi_wait )
                    next_state   =   STATE_WAIT;
                else if ( last_finished )
                    next_state   =   STATE_IDLE;
                else
                    next_state   =   STATE_TRANS;
            end


            STATE_IDLE: begin
                if (spi_stop)
                    next_state       =   STATE_DISABLE;
                else  if  (spi_wait)
                    next_state   =   STATE_WAIT;
                else  if (new_tx_in)
                    next_state       =   STATE_TRANS;
                else
                    next_state       =   STATE_IDLE;
            end


            STATE_TRANS: begin
                if (spi_stop)
                    next_state       =  STATE_DISABLE;
                else  if  (spi_wait )
                    next_state   =   STATE_WAIT;
                else  if  ( finished_out)
                    next_state   =   STATE_FINISH;
                else
                    next_state   =   STATE_TRANS;

            end


            STATE_FINISH:  begin
                if (spi_stop)
                    next_state   =  STATE_DISABLE;
                else  if  (spi_wait)
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
        end_trans               <=    0;
        last_finished           <=    1;        
        start_trans             <=    0;
        ss_out                  <=    1;
        
    end
    else  begin
        case (spi_state)
            STATE_RST || STATE_IDLE: begin
                end_trans               <=    0;
                last_finished           <=    1;
                start_trans             <=    0;
                ss_out                  <=    1;
            end

            STATE_TRANS:  begin
            end

            STATE_FINISH:  begin
                last_finished          <=    1;
            end


            default:    ;

        endcase
                
    end
end



sck_generator   gen_sck(    .clk_in(clk_in),
                            .enable_in(sck_enable),
                            .rstn_in(rstn_in),
                            .sck_out(sck_out),
                            .sppr_in(sppr),
                            .spr_in(spr)
                        );

spi_shift   shift_reg(
                            .cpol_in(spi_cr1_in[CR1_CPOL]),
                            .cpha_in(spi_cr1_in[CR1_CPHA]),
                            .enable_in(shift_enable),
                            .finish_out(finished_out),
                            .lsbfe_in(spi_cr1_in[CR1_LSBFE]),
                            .rstn_in(rstn_in),
                            .sck_in(shift_sck),
                            .serial_out(serial_out),
                            .serial_in(serial_in),
                            .shift_out(shift_out),

                            .spe_in(spi_cr1_in[CR1_SPE]),    
                            .spi_dr_in(spi_dr_in)

                        );





assign   mode_fault  =  (spi_cr1_in[CR1_MODFEN] && !spi_cr1_in[CR1_SSOE] && !ss_in)? 1:  0;
assign   sck_enable  =  ( spi_cr1_in[CR1_SPE] && spi_cr1_in[CR1_MTSR] && !spi_cr1_in[CR1_SPISWAI] ) ? 1:  0;
assign   sck_out     =  (spi_state == STATE_TRANS) && !last_finished ? sck_temp: (spi_cr1_in[CR1_CPOL]?  1: 0);

assign   shift_sck  =  spi_cr1_in[CR1_MTSR] ? sck_out: sck_in ;

assign   trans_valid  =  spi_cr1_in[CR1_MTSR]  ||  !ss_in ?  1:  0;

assign   spi_stop     =  spi_cr1_in[CR1_MTSR]  &&  !spi_cr1_in[CR1_SPE] ? 1: 0;
assign   spi_wait     =  spi_cr1_in[CR1_MTSR]  &&  !spi_cr1_in[CR1_SPISWAI] ? 1: 0;

endmodule


