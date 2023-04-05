
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

module   spi_shift (

    input   cpol_in,
    input   cpha_in,
    input   enable_in,
    output  finish_out,
    input   lsbfe_in,
    input   rstn_in,
    input   sck_in,
    output  serial_out,
    input   serial_in,
    output  [7:  0]  shift_out,

    input   spe_in,    
    input   [7: 0]   spi_dr_in
);
    


localparam   STATE_RST     =   2'd0;
localparam   STATE_SHIFT   =   2'd1;
localparam   STATE_FINISH  =   2'd2;

reg  [1: 0]  cur_state;
reg  [1: 0]  next_state;

reg  [3: 0]  shift_counter;
reg  [7: 0]  shift_bits;


wire  can_shift;

always @(*) begin
    next_state  =  0;
    if (!rstn_in) begin
        next_state  =  STATE_RST;
    end
    else begin
        case (cur_state)
            STATE_RST: begin
                if (!spe_in || !enable_in)
                    next_state  =  STATE_RST;
                else
                    next_state  =  STATE_SHIFT;
            end

            STATE_SHIFT: begin
                if (!spe_in || !enable_in )
                    next_state  =  STATE_RST;
                else  if  (finish_out)
                    next_state  =  STATE_SHIFT;
                else
                    next_state  =  STATE_SHIFT;
            end

            default :  next_state  =  STATE_RST;

        endcase

    end

end

always @(posedge sck_in or negedge sck_in  or  negedge  rstn_in ) begin
    if (!rstn_in)
        cur_state  <=  STATE_RST;
    else
        cur_state  <=  STATE_SHIFT;
end


always @(posedge sck_in or negedge sck_in  or  negedge  rstn_in) begin

    if (!rstn_in) begin
        shift_counter    <=  0;
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



assign   serial_out =  shift_out[7];
assign   serial_in  =  shift_out[0];

assign   finish_out =  (shift_counter ==  8)? 1: 0;

assign   can_shift  =  (!cpha_in && ( cpol_in ^ sck_in )) || ((cpha_in && !(cpol_in ^ sck_in) )) ? 1: 0;


endmodule


