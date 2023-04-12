

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
    output  reg  dmamode1_out,
    output  reg  rxclr_out,
    output  reg  txclr_out,
    output  reg  fifoen_out,
    output  reg  bc_out,
    output  reg  sp_out,
    output  reg  eps_out,
    output  reg  pen_out,
    output  reg  stb_out,
    output  reg  wls_out,

    output  reg  afe_out,
    output  reg  loop_out,
    output  reg  out2_out,
    output  reg  out1_out,
    output  reg  rts_out,

    input  rxfifoe_in,
    input  temt_in,
    input  thre_in,
    input  bi_in,
    input  fe_in,
    input  pe_in,
    input  oe_in,
    input  dr_in,
    input  cd_in,
    input  ri_in,
    input  sr_in,
    input  dsr_in,
    input  cts_in,
    input  dcd_in,
    input  teri_in,
    input  ddsr_in,
    input  dcts_in,  

    output  reg  [15: 0]  dlr_out,

    output  reg  utrst_out,
    output  reg  urrst_out,
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


reg  [7: 0]  rx_fifo[0: 15];
reg  [7: 0]  tx_fifo[0: 15];
reg  [3: 0]  rx_head;
reg  [3: 0]  rx_tail;
reg  [3: 0]  tx_head;
reg  [3: 0]  tx_tail;
reg  rx_fifo_full;
reg  tx_fifo_full;


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
wire  tx_fifo_empty;
wire  rx_fifo_empty;
wire  tx_fifo_one_empty;
wire  rx_fifo_one_entry;


always @(posedge  apb_clk_in  or  negedge  apb_rstn_in ) begin
    if (!apb_rstn_in  ||  apb_state[STATE_RST]) begin
        apb_rdata_out       <=  0;
    end
    else if (apb_state[STATE_TRANS]) begin
        if (is_dr) begin
            apb_rdata_out      <=  apb_write_in? 0: {16'd0, rx_fifo[rx_head], tx_fifo[tx_head]};
            
            if (fifoen_out) begin
                tx_fifo[tx_tail]  <= write_valid && !tx_fifo_full? apb_wdata_in[7:0]: tx_fifo[tx_tail];
                tx_tail           <= write_valid && !tx_fifo_full? (tx_tail+1): tx_tail;
                tx_fifo_full      <= write_valid? (!tx_fifo_full && !tx_fifo_one_empty?0: 1 ): tx_fifo_full;
            end
            else  begin
                tx_fifo[0]  <= write_valid && thre_in? apb_wdata_in[7: 0]: tx_fifo[0];
            end
            
        end
        else if (is_ier) begin
            apb_rdata_out  <=  apb_write_in?0: {20'd0, edssi_out, elsi_out, etbei_out, 
                                erbi_out, fifoen_out, 2'd0, intid_in, ipend_in};

            edssi_out  <=  write_valid? apb_wdata_in[11]: edssi_out;
            elsi_out   <=  write_valid? apb_wdata_in[10]: elsi_out;
            etbei_out  <=  write_valid? apb_wdata_in[9]: etbei_out;
            erbi_out   <=  write_valid? apb_wdata_in[8]: erbi_out;
        end
        else if (is_flcr) begin
            apb_rdata_out  <= apb_write_in? 0:  { 16'd0, rxfiftl_out, 2'd0, dmamode1_out, txclr_out, rxclr_out, fifoed_in,
                                                    1'd0,  bc_out, sp_out, eps_out, pen_out, stb_out,wls_out };

            rxfiftl_out   <=  write_valid? apb_wdata_in[15: 14]: rxfiftl_out;
            dmamode1_out  <=  write_valid? apb_addr_in[11]: dmamode1_out;
            txclr_out     <=  write_valid && apb_wdata_in[10]? 0:  txclr_out;
            rxclr_out     <=  write_valid && apb_wdata_in[9]?  0:  rxfiftl_out;
            fifoen_out    <=  write_valid? apb_wdata_in[8]:  fifoen_out;
            bc_out        <=  write_valid? apb_wdata_in[6]:  bc_out;
            sp_out        <=  write_valid? apb_wdata_in[5]:  sp_out;
            eps_out       <=  write_valid? apb_wdata_in[4]:  eps_out;
            pen_out       <=  write_valid? apb_wdata_in[3]:  pen_out;
            stb_out       <=  write_valid? apb_wdata_in[2]:  stb_out;
            wls_out       <=  write_valid? apb_wdata_in[1: 0]:  wls_out;
            
        end
        else if (is_mcr) begin
            apb_rdata_out    <=  apb_write_in? 0: {26'd0, afe_out, loop_out, out2_out, 
                                    out1_out, rts_out, 1'd0};
            afe_out    <=  write_valid? apb_wdata_in[5]: afe_out;
            loop_out   <=  write_valid? apb_wdata_in[4]: loop_out;
            out2_out   <=  write_valid? apb_wdata_in[3]: out2_out;
            out1_out   <=  write_valid? apb_wdata_in[2]: out1_out;
            rts_out    <=  write_valid? apb_wdata_in[1]: rts_out;
            
        end
        else if (is_lmsr) begin
            apb_rdata_out    <=  apb_write_in? 0: {16'd0, rxfifoe_in, temt_in, thre_in,
                                 bi_in, fe_in,  pe_in, oe_in, dr_in, cd_in, 
                                 ri_in, dsr_in};
            
        end
        else if (is_dlr) begin
            apb_rdata_out     <=  apb_write_in? 0:  {16'd0,  dlr_out};
            dlr_out           <=  write_valid? apb_wdata_in[15:  0]:  dlr_out;
        end
        else if (is_revd1) begin
            apb_rdata_out    <=   apb_write_in?  0:  32'h1102_0002;
        end
        else if (is_revd2) begin
            apb_rdata_out    <=   apb_write_in?  0:  {24'd0,  revid2};
        end
        else if (is_mgmt) begin
            apb_rdata_out    <=   apb_write_in?  0:  {17'd0,  utrst_out, urrst_out, 
                                    12'd0, free_out};
            utrst_out        <=   write_valid?  apb_wdata_in[14]:  utrst_out;
            urrst_out        <=   write_valid?  apb_wdata_in[13]:  urrst_out;
            free_out         <=   write_valid?  apb_wdata_in[0]:  free_out;
        end
        else if (is_mdr) begin
            apb_rdata_out    <=  apb_write_in?  0:  {31'd0,  osm_out};
            osm_out          <=  apb_write_in?  apb_wdata_in[0]:  osm_out;
        end
        else  ;

        apb_ready_out        <=  1;
        apb_slverr_out       <=   apb_slverr_in?  1: 0;

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


assign   rx_fifo_empty  =  !rx_fifo_full && (rx_head ==  rx_tail) ? 1:  0;
assign   tx_fifo_empty  =  !tx_fifo_full && (tx_head ==  tx_head) ? 1:  0;
assign   rx_fifo_one_entry  =  rx_head == (rx_tail + 1) ? 1:  0;
assign   tx_fifo_one_entry  =  tx_head == (tx_tail + 1) ? 1:  0;

endmodule



