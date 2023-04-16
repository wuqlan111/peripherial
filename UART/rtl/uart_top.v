

/****************************************************************************************
* Module Name:     spi_top
* Author:          wuqlan
* Email:           
* Date Created:    2023/4/2
* Description:     SPI top module.
*                  
*
* Version:         0.1
*****************************************************************************************/
module   uart_top #(    parameter   APB_DATA_WIDTH    =  32,
                        parameter   APB_ADDR_WIDTH    =  32,
                        parameter   TIMEOUT_CYCLE     =  6,
                        parameter   UART_REG_BASE     =  32'ha0300000 )
(

                /*--------spi module top signal-------*/
                output  uart_txd_out,
                input   uart_rxd_in,
                input   uart_ctx_in,
                output  uart_rts_out,


                input  apb_clk_in,
                input  apb_rstn_in,

                /*-----------apb bus signal------------*/
                input   [APB_ADDR_WIDTH -1: 0]  apb_addr_in,
                input   apb_penable_in,
                input   apb_psel_in,
                output  [APB_DATA_WIDTH-1:0]  apb_rdata_out,
                output  apb_ready_out,

                `ifdef  APB_WSTRB
                    input   [(APB_DATA_WIDTH / 8) -1:0]  apb_strb_in,
                `endif

                input   apb_slverr_in,
                output  apb_slverr_out,
                input   [APB_DATA_WIDTH-1:0]  apb_wdata_in,
                input   apb_write_in

);



wire  bclk_gen;




/*--------uart regs----------*/
wire [7: 0] dr_rbr;
wire [7: 0] dr_thr;
wire  ier_edssi;
wire  ier_elsi;
wire  ier_etbei;
wire  ier_etbi;
wire  [1: 0] ier_fifoened;
wire  [2:  0]  ier_intid;
wire  ier_ipend;
wire  [1: 0] flcr_rxfifotl;
wire  flcr_dmamode1;
wire  flcr_txclr;
wire  flcr_rxclr;
wire  flcr_fifoen;
wire  flcr_dlab;
wire  flcr_bc;
wire  flcr_sp;
wire  flcr_eps;
wire  flcr_pen;
wire  flcr_stb;
wire  flcr_wls;
wire  mcr_afe;
wire  mcr_loop;
wire  mcr_out2;
wire  mcr_out1;
wire  mcr_rts;
wire  lmsr_rxfifoe;
wire  lmsr_temt;
wire  lmsr_thre;
wire  lmsr_bi;
wire  lmsr_fe;
wire  lmsr_pe;
wire  lmsr_oe;
wire  lmsr_dr;
wire  lmsr_cd;
wire  lmsr_ri;
wire  lmsr_dsr;
wire  lmsr_cts;
wire  lmsr_dcd;
wire  lmsr_teri;
wire  lmsr_ddsr;
wire  lmsr_dcts;
wire  [15:0]  dlr;
wire  [31: 0]  revid1;
wire  [7: 0]  revid2;
wire  mgmt_utrst;
wire  mgmt_urrst;
wire  mgmt_free;
wire  mcr_osm_sel;


sck_generator  bclk_generator(
    .clk_in(apb_clk_in),
    .rstn_in(apb_rstn_in),
    .bclk_out(bclk_gen),
    .divisor(dlr)
);


uart_reg #( .APB_DATA_WIDTH(APB_DATA_WIDTH), .APB_ADDR_WIDTH(APB_ADDR_WIDTH),
                        .UART_REG_BASE(UART_REG_BASE))  uart_registers
        
(
    .apb_clk_in(apb_clk_in),
    .apb_rstn_in,


    /*-----------apb bus signal------------*/
    .apb_addr_in(apb_addr_in),
    .apb_penable_in(apb_penable_in),
    .apb_psel_in(apb_psel_in),
    .apb_rdata_out(apb_rdata_out),
    .apb_ready_out(apb_ready_out),

    `ifdef  APB_WSTRB
        .apb_strb_in(apb_strb_in),
    `endif

    .apb_slverr_in(apb_slverr_in),
    .apb_slverr_out(apb_slverr_out),
    .apb_wdata_in(apb_wdata_in),
    .apb_write_in(apb_write_in),

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








endmodule


