

/****************************************************************************************
* Module Name:     spi_reg
* Author:          wuqlan
* Email:           
* Date Created:    2023/4/9
* Description:     UART register module.
*                  
*
* Version:         0.1
*****************************************************************************************/
module   spi_reg #(     parameter   APB_DATA_WIDTH    =  32,
                        parameter   APB_ADDR_WIDTH    =  32,
                        parameter   SPI_REG_BASE      =  32'ha0300000 )
(
    input  apb_clk_in,
    input  apb_rstn_in,


    /*-----------apb bus signal------------*/
    input   [APB_ADDR_WIDTH -1: 0]  apb_addr_in,
    input   apb_penable_in,
    input   apb_psel_in,
    output  reg  [APB_DATA_WIDTH-1:0]  apb_rdata_out,
    output  reg  apb_ready_out,

    `ifdef  APB_WSTRB
        input   [(APB_DATA_WIDTH / 8) -1:0]  apb_strb_in,
    `endif

    input   apb_slverr_in,
    output  reg  apb_slverr_out,
    input   [APB_DATA_WIDTH-1:0]  apb_wdata_in,
    input   apb_write_in,

    /*-------UART register---------*/
    input   [7: 0]  rbr_in,
    output  [7: 0]  thr_out,

    output  reg  edssi_out,
    output  reg  elsi_out,
    output  reg  etbei_out,
    output  reg  erbi_out,
    input  fifoed_in,
    input  [2: 0]  intid_in,
    input  ipend_in,

    output  reg  [1:0]  rxfiftl_out,
    output  reg  rxclr_out,
    output  reg  txclr_out,
    output  reg  fifoen_out,
    output  reg  bc_reg,
    output  reg  sp_out,
    output  reg  eps_out,
    output  reg  pen_out,
    output  reg  stb_out,
    output  reg  wls_out,

    output  reg  afe_out,
    output  reg  out2_out,
    output  reg  out1_out,
    output  reg  rts_out,

    output  reg  [15:  0]  lmsr_out,

    output  reg  [15: 0]  dlr_out,

    output  reg  utrst_out,
    output  reg  uerst_out,
    output  reg  free_out,

    output  reg  osm_out

);



/*FSM state definition*/
localparam  STATE_RST       =   0;
localparam  STATE_IDLE      =   1;
localparam  STATE_SETUP     =   2;
localparam  STATE_TRANS     =   3;
localparam  STATE_ERROR     =   4;


reg  [4:0]  apb_state;
reg  [4:0]  next_state;


reg  [31: 0]  revid1;
reg  [7: 0]   revid2;


wire  addr_valid;
wire  [7: 0]  addr_offset;
wire  offset_valid;



 
//////////////////////////////////Combinatorial logic//////////////////////////////////////////


/*FSM state*/
always @(*) begin
    next_state  =  0;
    if (!apb_rstn_in)
        next_state[STATE_RST]  =  1'd1;
    else begin
        case (1'd1)
            apb_state[STATE_RST] || apb_state[STATE_IDLE] :begin
                    if (!apb_psel_in)
                        next_state[STATE_IDLE]    =  1'd1;
                    else if ( !apb_penable_in )
                        next_state[STATE_SETUP]   =  1'd1;
                    else
                        next_state[STATE_ERROR]   =  1'd1;
            end

            apb_state[STATE_SETUP]:begin
                if ( !apb_penable_in || !apb_psel_in || !addr_valid || !offset_valid)
                    next_state[STATE_ERROR]  =  1'd1;
                else
                    next_state[STATE_TRANS]  =  1'd1;

            end

            apb_state[STATE_TRANS]:begin
                if ( !apb_penable_in || !apb_psel_in )
                    next_state[STATE_ERROR]  =  1'd1;
                else
                    next_state[STATE_IDLE]  =  1'd1;
            end

            
            default:
                next_state[STATE_IDLE]  =  1'd1;

        endcase
        
    end

end





///////////////////////////////////Sequential logic/////////////////////////////////////////////


/*Set apb state*/
always @(negedge apb_clk_in) begin
    apb_state <= next_state;
end


/*Slave transfer data*/
always @( posedge  apb_clk_in  or  negedge  apb_rstn_in ) begin
    if (!apb_rstn_in) begin
        apb_ready_out       <=  0;        
        apb_slverr_out      <=  0;
    end
    else begin
        case (1'd1)
            apb_state[STATE_RST] || apb_state[STATE_SETUP]:begin
                apb_ready_out       <=  0;             
                apb_slverr_out      <=  0;
            end

            apb_state[STATE_IDLE]: begin
                apb_ready_out       <=  0;             
                apb_slverr_out      <=  0;

            end

            apb_state[STATE_TRANS]: begin
                apb_ready_out       <=  1;
            end

            apb_state[STATE_ERROR]:begin
                apb_ready_out        <=  1;                
                apb_slverr_out       <=  1;  
            end

            default:;
        endcase
    end
    
end



/*-----------SPI register offset-----*/
localparam   SPI_CR1_OFFSET  =  0;
localparam   SPI_CR2_OFFSET  =  4;
localparam   SPI_SPR_OFFSET  =  8;
localparam   SPI_SR_OFFSET   =  12;
localparam   SPI_DR_OFFSET   =  16;
localparam   MAX_REG_OFFSET  =  16;



always @(posedge  apb_clk_in  or  negedge  apb_rstn_in ) begin
    if (!apb_rstn_in  ||  apb_state[STATE_RST]) begin
        apb_rdata_out       <=  0;
    end
    else if (apb_state[STATE_TRANS]) begin
        if (is_cr1) begin
            apb_rdata_out       <=  apb_write_in?  0:  spi_cr1;
            apb_slverr_out      <=  apb_slverr_in || (apb_write_in && !write_valid)? 1: 0;

        end 
        else if (is_cr2) begin
            apb_rdata_out       <=  apb_write_in?  0:  spi_cr2;
            apb_slverr_out      <=  apb_slverr_in || (apb_write_in && !write_valid)? 1: 0;
            
        end
        else if (is_spr) begin
            apb_rdata_out       <=  apb_write_in?  0:  spi_spr;
            apb_slverr_out      <=  apb_slverr_in || (apb_write_in && !write_valid)? 1: 0;
            

        end
        else if (is_sr) begin
            apb_rdata_out       <=  apb_write_in?  0:  spi_sr;
            apb_slverr_out      <=  apb_slverr_in || apb_write_in? 1: 0;


        end
        else if(is_dr) begin
            apb_rdata_out       <=  apb_write_in?  0:  spi_dr;
            apb_slverr_out      <=  apb_slverr_in || (apb_write_in && !write_valid)? 1: 0;


        end
        else begin
            apb_rdata_out       <=  0;
            apb_slverr_out      <=  1;
        end 

    end
    else   ;

end


assign   addr_valid    =  (apb_addr_in[APB_ADDR_WIDTH -1: 8] != SPI_REG_BASE[APB_ADDR_WIDTH-1: 8])? 0: 1;
assign   addr_offset   =  apb_addr_in[7: 0];
assign   offset_valid  =  (addr_offset  >  MAX_REG_OFFSET )?0:  1;


assign   is_cr1  =  (addr_offset  ==  SPI_CR1_OFFSET)? 1: 0;
assign   is_cr2  =  (addr_offset  ==  SPI_CR2_OFFSET)? 1: 0;
assign   is_spr  =  (addr_offset  ==  SPI_SPR_OFFSET)? 1: 0;
assign   is_sr   =  (addr_offset  ==  SPI_SR_OFFSET )? 1: 0;
assign   is_dr   =  (addr_offset  ==  SPI_DR_OFFSET )? 1: 0;






`ifdef  APB_WSTRB
    assign   write_valid  =  (apb_write_in && apb_strb_in[0])? 1: 0;
`else
    assign   write_valid  =  apb_write_in? 1: 0;
`endif

endmodule




















