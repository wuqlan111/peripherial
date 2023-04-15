

/********************************************************************
* Module Name:     uart_rx_shift
* Author:          wuqlan
* Email:           
* Date Created:    2023/4/15
* Description:     UART rx shift module.
*                  
*
* Version:         0.1
***********************************************************************/

module   uart_tx_shift (
    input  rstn_in,

    input   bclk_in,
    output  reg  data_parity_out,
    input   esp_in,
    input   enable_in,
    output  reg  finish_out,
    input   osm_sel_in,
    input   pen_in,
    input   serial_in,
    input   sp_in,
    input   stb_in,
    output  reg  [7: 0]  shift_out,
    input   [1: 0]  wls_in
);
    


localparam   STATE_RST     =   2'd0;
localparam   STATE_START   =   2'd1;
localparam   STATE_SHIFT   =   2'd2;
localparam   STATE_FINISH  =   2'd3;

reg  [1: 0]  cur_state;
reg  [1: 0]  next_state;

reg  [3: 0]  shift_counter;

reg  [4: 0]  cycle_counter;


wire  can_shift;
wire  data_width_valid;
wire  odd_parity;
wire  stop_w2;
wire  stop_w1;
wire  stop_w1_5;

wire  trans_next;
wire  shift_end;

wire  is_data_5;
wire  is_data_6;
wire  is_data_7;
wire  is_data_8;


always @(*) begin
    next_state  =  0;
    if (!rstn_in) begin
        next_state  =  STATE_RST;
    end
    else begin
        case (cur_state)
            STATE_RST: begin
                if (!enable_in || !data_width_valid)
                    next_state  =  STATE_RST;
                else
                    next_state  =  STATE_START;
            end

            STATE_START: begin

                if (!enable_in || !data_width_valid || serial_in)
                    next_state  =  STATE_RST;
                else if (trans_next)
                    next_state  =  STATE_SHIFT;
                else
                    next_state  =  STATE_START;
            end


            STATE_SHIFT: begin
                if (!enable_in || !data_width_valid )
                    next_state  =  STATE_RST;
                else  if  (shift_end && trans_next)
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


always @(posedge bclk_in or negedge rstn_in) begin

    if (!rstn_in) begin
        cycle_counter     <=  0;
        shift_counter     <=  1;
        shift_out         <=  0;        
        finish_out        <=  0;
    end
    else  begin
        case (cur_state)
            STATE_RST: begin
                cycle_counter     <=  0;
                shift_out         <=  0;
                shift_counter     <=  0;
                finish_out        <=  0;
            end

            STATE_START: begin
                cycle_counter     <=  (shift_counter+1);
            end

            STATE_SHIFT: begin
                cycle_counter  <=  trans_next? 0: (cycle_counter+1);
                shift_out[shift_counter]  <=  can_shift? serial_in: shift_out[shift_counter];
                shift_counter             <=  can_shift? (shift_counter+1): shift_counter;
            end

            STATE_FINISH: begin
                finish_out     <=  1;
                cycle_counter  <=  trans_next? 0: (cycle_counter+1);
            end

            default :   ; 

        endcase
    end
end



assign   data_width_valid  =  !is_data_5 && !is_data_6 && !is_data_7 && !is_data_8? 0:  1;

assign  is_data_5 = (stb_in && !wls_in) ? 1:  0;
assign  is_data_6 = (stb_in && (wls_in == 1) ) ? 1:  0;
assign  is_data_7 = (stb_in && (wls_in == 2) ) ? 1:  0;
assign  is_data_8 = (stb_in && (wls_in == 3) ) ? 1:  0;



assign   stop_w1     =  !stb_in ? 1:  0;
assign   stop_w1_5   =  stb_in && !wls_in? 1: 0;
assign   stop_w2     =  stb_in && wls_in? 1:  0;

assign   finish_out  =  (shift_counter ==  7)? 1: 0;

assign   trans_next  =  (osm_sel_in && (cycle_counter == 13)) || ( !osm_sel_in && (cycle_counter == 16) )? 1:  0;
assign   shift_end   =  (is_data_5 && (shift_counter == 4)) || (is_data_6 && (shift_counter == 5))
                             || (is_data_7 && (shift_counter == 6)) || (is_data_8 && (shift_counter == 7) )? 1:  0;
assign  can_shift  =  (osm_sel_in && (cycle_counter == 6)) || ( !osm_sel_in && (cycle_counter == 8)) ? 1:  0;


endmodule




















