

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
wire  write_valid;


 
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
localparam   UART_DR_OFFET        =   0;
localparam   UART_IER_OFFET       =   4;
localparam   UART_FLCR_OFFET      =   8;
localparam   UART_MCR_OFFET       =   12;
localparam   UART_LMSR_OFFET      =   16;
localparam   UART_DLR_OFFET       =   20;
localparam   UART_REVD1_OFFET     =   24;
localparam   UART_REVD2_OFFET     =   28;
localparam   UART_MGMT_OFFET      =   32;
localparam   UART_MDR_OFFET       =   36;
localparam   MAX_REG_OFFSET       =   36;

wire  is_dr;
wire  is_ier;
wire  is_flcr;
wire  is_mcr;
wire  is_lmsr;
wire  is_dlr;
wire  is_revd1;
wire  is_revd2;
wire  is_mgmt;
wire  is_mdr;



always @(posedge  apb_clk_in  or  negedge  apb_rstn_in ) begin
    if (!apb_rstn_in  ||  apb_state[STATE_RST]) begin
        apb_rdata_out       <=  0;
    end
    else if (apb_state[STATE_TRANS]) begin
        if (is_dr) begin
            
        end
        else if (is_ier) begin
            edssi_out  <=  write_valid? apb_wdata_in[11]: edssi_out;
            elsi_out   <=  write_valid? apb_wdata_in[]
            
        end
        else if (is_flcr) begin
            
        end
        else if (is_mcr) begin
            
        end
        else if (is_lmsr) begin
            
        end
        else if (is_dlr) begin
            
        end
        else if (is_revd1) begin
            
        end
        else if (is_revd2) begin
            
        end
        else if (is_mgmt) begin
            
        end
        else if (is_mdr) begin
            
        end
        else begin
            

        end

    end
    else   ;

end


assign   addr_valid    =  (apb_addr_in[APB_ADDR_WIDTH -1: 8] != SPI_REG_BASE[APB_ADDR_WIDTH-1: 8])? 0: 1;
assign   addr_offset   =  apb_addr_in[7: 0];
assign   offset_valid  =  (addr_offset  >  MAX_REG_OFFSET )?0:  1;

assign  is_dr     =   (apb_addr_in[7: 0]  ==  UART_DR_OFFET)? 1: 0;
assign  is_ier    =   (apb_addr_in[7: 0]  ==  UART_IER_OFFET)? 1: 0;
assign  is_flcr   =   (apb_addr_in[7: 0]  ==  UART_FLCR_OFFET)? 1: 0;
assign  is_mcr    =   (apb_addr_in[7: 0]  ==  UART_MCR_OFFET)? 1: 0;
assign  is_lmsr   =   (apb_addr_in[7: 0]  ==  UART_LMSR_OFFET)? 1: 0;
assign  is_dlr    =   (apb_addr_in[7: 0]  ==  UART_DLR_OFFET)? 1: 0;
assign  is_revd1  =   (apb_addr_in[7: 0]  ==  UART_REVD1_OFFET)? 1: 0;
assign  is_revd2  =   (apb_addr_in[7: 0]  ==  UART_REVD2_OFFET)? 1: 0;
assign  is_mgmt   =   (apb_addr_in[7: 0]  ==  UART_MGMT_OFFET)? 1: 0;
assign  is_mdr    =   (apb_addr_in[7: 0]  ==  UART_MDR_OFFET)? 1: 0;


`ifdef  APB_WSTRB
    assign   write_valid  =  (apb_write_in && apb_strb_in[0])? 1: 0;
`else
    assign   write_valid  =  apb_write_in? 1: 0;
`endif








endmodule



