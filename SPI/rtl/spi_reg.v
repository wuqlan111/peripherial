
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
                        parameter   TIMEOUT_CYCLE     =  6,
                        parameter   SPI_REG_BASE      =  32'ha0300000 )
(
    input  apb_clk_in,
    input  apb_rstn_in,


    /*-----------apb bus signal------------*/
    input  [APB_ADDR_WIDTH -1: 0]  apb_addr_in,
    input  apb_penable_in,

    `ifdef  APB_PROT
        input  [2:0]  apb_prot_in,
    `endif

    `ifdef  APB_WSTRB
        input  [(APB_DATA_WIDTH / 8) -1:0]  apb_strb_in,
    `endif

    `ifdef  APB_SLVERR
        input   apb_slverr_in,
        output  apb_slverr_out,
    `endif

    input   apb_psel_in,
    output  reg  [APB_DATA_WIDTH-1:0]  apb_rdata_out,
    output  reg  apb_ready_out,
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
    output  reg  spie_out,
    output  reg   


);



/*FSM state definition*/
localparam  STATE_RST       =   0;
localparam  STATE_SETUP     =   1;
localparam  STATE_TRANS     =   2;
localparam  STATE_ERROR     =   3;


reg  [3:0]  apb_state;
reg  [3:0]  next_state;

wire  addr_valid;
wire  [7: 0]  addr_offset;


//////////////////////////////////Combinatorial logic//////////////////////////////////////////


/*FSM state*/
always @(*) begin
    next_state  =  0;
    if (!apb_rstn_in)
        next_state[STATE_RST]  =  1'd1;
    else begin
        case (1'd1)
            apb_state[STATE_RST]:begin
                    if (!apb_psel_in || apb_penable_in)
                        next_state[STATE_RST]    =  1'd1;
                    else
                        next_state[STATE_SETUP]  =  1'd1;
            end

            apb_state[STATE_SETUP]:begin
                if ( !apb_penable_in || !apb_psel_in || !addr_valid)
                    next_state[STATE_ERROR]  =  1'd1;
                else
                    next_state[STATE_TRANS]  =  1'd1;

            end

            apb_state[STATE_TRANS]:begin
                if ( !apb_penable_in || !apb_psel_in )
                    next_state[STATE_ERROR]  =  1'd1;
                else
                    next_state[STATE_RST]  =  1'd1;
            end
            
            default:
                next_state[STATE_RST]  =  1'd1;

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
        
        `ifdef  APB_SLVERR
            apb_slverr_out    <=  0;
        `endif
        apb_rdata_out       <=  0;
        apb_ready_out       <=  0;

    end
    else begin
        case (1'd1)
            apb_state[STATE_RST]:begin

                `ifdef  APB_SLVERR
                    apb_slverr_out    <=  0;
                `endif
                apb_rdata_out       <=  0;
                apb_ready_out       <=  0;
                
            end

            apb_state[STATE_SETUP]:begin
                
                `ifdef  APB_PROT
                    other_prot_out      <=   apb_prot_in;
                `endif
                `ifdef  APB_WSTRB
                    other_strb_out      <=   apb_strb_in;
                `endif

                apb_ready_out       <=   0;

            end

            apb_state[STATE_TRANS]: begin

                `ifdef  APB_SLVERR
                    apb_slverr_out      <=  apb_slverr_in;
                    apb_rdata_out       <=  apb_slverr_in? 0: other_rdata_in;
                `else

                `endif

                apb_ready_out       <=  1;
            end

            apb_state[STATE_ERROR]:begin
                `ifdef  APB_SLVERR
                    apb_slverr_out       <=  1;
                `endif
                apb_ready_out            <=  1;
                
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




always @(posedge  apb_clk_in  or  negedge  apb_rstn_in ) begin
    if (!apb_rstn_in) begin
        

    end





    
end


assign   addr_valid   =  (apb_addr_in[APB_ADDR_WIDTH -1: 8] != SPI_REG_BASE[APB_ADDR_WIDTH-1: 8])? 0: 1;
assign   addr_offset  =  apb_addr_in[7: 0];



endmodule


