

/********************************************************************
* Module Name:     uart_tx_shift
* Author:          wuqlan
* Email:           
* Date Created:    2023/4/2
* Description:     UART tx shift module.
*                  
*
* Version:         0.1
***********************************************************************/

module   uart_tx_shift (
    input  rstn_in,

    input   bclk_in,
    input   esp_in,
    input   enable_in,
    output  reg  finish_out,
    input   osm_sel_in,
    input   pen_in,
    output  serial_out,
    input   sp_in,
    input   stb_in,
    input   [7: 0]  thr_in,
    input   [1: 0]  wls_in
);
    


localparam   STATE_RST     =   2'd0;
localparam   STATE_SHIFT   =   2'd1;
localparam   STATE_FINISH  =   2'd2;

reg  [1: 0]  cur_state;
reg  [1: 0]  next_state;

reg  [3: 0]  shift_counter;
reg  [7: 0]  shift_bits;

reg  [4: 0]  cycle_counter;


wire  can_shift;
wire  data_parity;
wire  even_parity;
wire  odd_parity;
wire  stop_w2;
wire  stop_w1;
wire  stop_w1_5;


always @(*) begin
    next_state  =  0;
    if (!rstn_in) begin
        next_state  =  STATE_RST;
    end
    else begin
        case (cur_state)
            STATE_RST: begin
                if (!enable_in)
                    next_state  =  STATE_RST;
                else
                    next_state  =  STATE_SHIFT;
            end

            STATE_SHIFT: begin
                if (!enable_in )
                    next_state  =  STATE_RST;
                else  if  (finish_out)
                    next_state  =  STATE_FINISH;
                else
                    next_state  =  STATE_SHIFT;
            end

            default :  next_state  =  STATE_RST;

        endcase

    end

end

always @(posedge bclk_in or negedge bclk_in  or  negedge  rstn_in ) begin
    if (!rstn_in)
        cur_state  <=  STATE_RST;
    else
        cur_state  <=  next_state;
end


always @(posedge bclk_in or negedge sck_in  or  negedge  rstn_in) begin

    if (!rstn_in) begin
        shift_counter     <=  0;
        shift_bits        <=  0;
    end
    else  begin
        case (cur_state)
            STATE_RST: begin
                shift_bits[0]     <=  spe_in? (lsbfe_in?  spi_dr_in[7]: spi_dr_in[0]) : 0;
                shift_bits[1]     <=  spe_in? (lsbfe_in?  spi_dr_in[6]: spi_dr_in[1]) : 0;
                shift_bits[2]     <=  spe_in? (lsbfe_in?  spi_dr_in[5]: spi_dr_in[2]) : 0;
                shift_bits[3]     <=  spe_in? (lsbfe_in?  spi_dr_in[4]: spi_dr_in[3]) : 0;
                shift_bits[4]     <=  spe_in? (lsbfe_in?  spi_dr_in[3]: spi_dr_in[4]) : 0;
                shift_bits[5]     <=  spe_in? (lsbfe_in?  spi_dr_in[2]: spi_dr_in[5]) : 0;
                shift_bits[6]     <=  spe_in? (lsbfe_in?  spi_dr_in[1]: spi_dr_in[6]) : 0;
                shift_bits[7]     <=  spe_in? (lsbfe_in?  spi_dr_in[0]: spi_dr_in[7]) : 0;

                shift_counter     <=  0;
            end

            STATE_SHIFT: begin
                if (can_shift && shift_counter) begin
                    shift_bits[7]      <=    shift_bits[6];
                    shift_bits[6]      <=    shift_bits[5];
                    shift_bits[4]      <=    shift_bits[3];
                    shift_bits[3]      <=    shift_bits[2];
                    shift_bits[2]      <=    shift_bits[1];
                    shift_bits[1]      <=    shift_bits[0];
                    shift_bits[0]      <=    serial_in;
                end
                else ;

                shift_counter      <=    can_shift? (shift_counter + 1): shift_counter;

            end

            default :   ; 

        endcase
    end
end


assign  even_parity  =  
assign  data_parity  =  ;

assign   stop_w1    =  !stb_in ? 1:  0;
assign   stop_w1_5  =  stb_in && !wls_in? 1: 0;
assign   stop_w2    =  stb_in && wls_in? 1:  0;

assign   finish_out =  (shift_counter ==  7)? 1: 0;



endmodule

