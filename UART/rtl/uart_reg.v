

/****************************************************************************************
* Module Name:     spi_reg
* Author:          wuqlan
* Email:           
* Date Created:    2023/4/2
* Description:     SPI register module.
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

    /*-------SPI register---------*/
    output  reg   [7: 0]  spi_cr1_out,
    output  reg   spie_out,
    output  reg   sptie_out,
    output  reg   errie_out,
    output  reg   bidiroe_out,
    output  reg   spc0_out,
    output  reg  [2: 0]  sppr_out,
    output  reg  [2: 0]  spr_out,
    input   shift_end_in,
    input   modf_in,
    input   over_in,
    output  reg  [7: 0] dr_out

);



/*FSM state definition*/
localparam  STATE_RST       =   0;
localparam  STATE_IDLE      =   1;
localparam  STATE_SETUP     =   2;
localparam  STATE_TRANS     =   3;
localparam  STATE_ERROR     =   4;


reg  [4:0]  apb_state;
reg  [4:0]  next_state;


reg  modf;
reg  overf;
reg  spif;
reg  sptef;
reg  read_sr;

wire  addr_valid;
wire  [7: 0]  addr_offset;
wire  offset_valid;

wire  is_cr1;
wire  is_cr2;
wire  is_spr;
wire  is_sr;
wire  is_dr;

wire  [7: 0]  spi_cr1;
wire  [7: 0]  spi_cr2;
wire  [7: 0]  spi_spr;
wire  [7: 0]  spi_sr;
wire  [7: 0]  spi_dr;

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
                
                spif                <=  shift_end_in? 1:  0;
                modf                <=  modf_in?  1: 0;
                overf               <=  over_in? 1: 0;


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
        dr_out              <=  0;
        spi_cr1_out         <=  (1<<4);
        spie_out            <=  0;
        sptie_out           <=  0;
        errie_out           <=  0;
        bidiroe_out         <=  0;
        spc0_out            <=  0;
        sppr_out            <=  0;
        spr_out             <=  0;

        spif                <=  0;
        sptef               <=  1;
        modf                <=  0;
        overf               <=  0;
    end
    else if (apb_state[STATE_TRANS]) begin
        if (is_cr1) begin
            apb_rdata_out       <=  apb_write_in?  0:  spi_cr1;
            apb_slverr_out      <=  apb_slverr_in || (apb_write_in && !write_valid)? 1: 0;
            spi_cr1_out         <=  write_valid?  apb_wdata_in[7: 0]: spi_cr1_out;

            modf                <=  !read_sr || !write_valid ? modf:  0;
            read_sr             <=  0;

        end 
        else if (is_cr2) begin
            apb_rdata_out       <=  apb_write_in?  0:  spi_cr2;
            apb_slverr_out      <=  apb_slverr_in || (apb_write_in && !write_valid)? 1: 0;
            
            spie_out            <=  write_valid?  apb_wdata_in[7]: spie_out;
            sptie_out           <=  write_valid?  apb_wdata_in[6]: sptie_out;
            errie_out           <=  write_valid?  apb_wdata_in[5]: errie_out;
            bidiroe_out         <=  write_valid?  apb_wdata_in[1]: bidiroe_out;
            spc0_out            <=  write_valid?  apb_wdata_in[0]: spc0_out;
        end
        else if (is_spr) begin
            apb_rdata_out       <=  apb_write_in?  0:  spi_spr;
            apb_slverr_out      <=  apb_slverr_in || (apb_write_in && !write_valid)? 1: 0;
            
            sppr_out            <=  write_valid?  apb_wdata_in[6: 4]: sppr_out;
            spr_out             <=  write_valid?  apb_wdata_in[2: 0]: spr_out;
        end
        else if (is_sr) begin
            apb_rdata_out       <=  apb_write_in?  0:  spi_sr;
            apb_slverr_out      <=  apb_slverr_in || apb_write_in? 1: 0;

            read_sr             <=  apb_write_in?  0:  1;
            overf               <=  !apb_write_in? 0: overf;

        end
        else if(is_dr) begin
            apb_rdata_out       <=  apb_write_in?  0:  spi_dr;
            apb_slverr_out      <=  apb_slverr_in || (apb_write_in && !write_valid)? 1: 0;
            dr_out              <=  write_valid && sptef?  apb_wdata_in[7: 0]: dr_out;

            spif                <=  !read_sr ||  apb_write_in? spif:  0;
            sptef               <=  !read_sr ||  !write_valid? sptef: 0;
            read_sr             <=  0;

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

assign  spi_cr1   =  spi_cr1_out;
assign  spi_cr2   =  {spie_out, sptie_out, errie_out, 3'd0, bidiroe_out, spc0_out};
assign  spi_spr   =  {1'd0, sppr_out, 1'd0, spr_out };
assign  spi_sr    =  {4'd0, spif,  sptef,  modf,  overf};
assign  spi_dr    =  dr_out;


`ifdef  APB_WSTRB
    assign   write_valid  =  (apb_write_in && apb_strb_in[0])? 1: 0;
`else
    assign   write_valid  =  apb_write_in? 1: 0;
`endif

endmodule




















