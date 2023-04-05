
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
module   spi_top #(     parameter   APB_DATA_WIDTH    =  32,
                        parameter   APB_ADDR_WIDTH    =  32,
                        parameter   TIMEOUT_CYCLE     =  6,
                        parameter   SPI_REG_BASE      =  32'ha0300000 )
(

                /*--------spi module top signal-------*/
                inout  miso_io,
                inout  mosi_io,
                inout  sck_io,
                inout  ss_io,


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
                input   apb_write_in

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




wire  serial_in;
wire  serial_out;

/*------connect core and registers--------*/
wire  [7: 0]  spi_cr1;
wire  spi_spie;
wire  spi_sptie;
wire  spi_errie;
wire  spi_bidiroe;
wire  spi_spc0;
wire  [2: 0]  spi_sppr;
wire  [2: 0]  spi_spr;
wire  spi_spif;
wire  spi_sptef;
wire  spi_modf;
wire  spi_overf;
wire  [7: 0]  spi_dr;

wire  sck_out;
wire  sck_in;

wire  ss_in;
wire  ss_out;

wire  [7: 0]  shift_reg;
wire  shift_finish;



spi_reg     #(  .APB_DATA_WIDTH(APB_DATA_WIDTH), 
                .APB_ADDR_WIDTH(APB_ADDR_WIDTH),
                .SPI_REG_BASE(SPI_REG_BASE) )
            spi_register
(
    .apb_clk_in(apb_clk_in),
    .apb_rstn_in(apb_rstn_in),


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

    /*-------SPI register---------*/
    .spi_cr1_out(spi_cr1),
    .spie_out(spi_spie),
    .sptie_out(spi_sptie),
    .errie_out(spi_errie),
    .bidiroe_out(spi_bidiroe),
    .spc0_out(spi_spc0),
    .sppr_out(spi_sppr),
    .spr_out(spi_spr),
    .shift_end_in(),
    .modf_in(spi_modf),
    .over_in(spi_overf),
    .dr_out(spi_dr)

);







spi_core  spi_core_module(

    /*-------system clk and reset signal*/
    .clk_in(apb_clk_in),
    .rstn_in(apb_rstn_in),

    /*-------ctrl regs--------*/
    .bidiroe_in(spi_bidiroe),
    .errie_in(spi_errie),
    .spc0_in(spi_spc0),
    .spi_cr1_in(spi_cr1),
    .spi_dr_in(spi_dr),
    .spie_in(spi_spie),
    .sppr_in(spi_sppr),
    .spr_in(spi_spr),
    .sptie_in(spi_sptie),
    .shift_out(shift_reg),

    /*-------control signal----------*/
    .finished_out(shift_finish),

    /*------spi signal------*/
    .serial_in(serial_in),
    .serial_out(serial_out),
    .sck_in(sck_in),
    .sck_out(sck_out),
    .ss_in(ss_in),
    .ss_out(ss_out)
);






assign   miso_io   =  !spi_cr1[CR1_MTSR] ?  serial_out: 1'bz;
assign   mosi_io   =   spi_cr1[CR1_MTSR] ?  serial_out: 1'bz;
assign   sck_io    =   spi_cr1[CR1_MTSR] ?  sck_out: 1'bz;
assign   ss_io     =   spi_cr1[CR1_MTSR] && spi_cr1[CR1_MODFEN] 
                        && spi_cr1[CR1_SSOE] ?  ss_out: 1'bz;
assign   ss_in     =   spi_cr1[CR1_MTSR] && spi_cr1[CR1_MODFEN] 
                        && spi_cr1[CR1_SSOE] ?  1: ss_io;

assign   sck_io     =   spi_cr1[CR1_MTSR] ? sck_out :  1'bz;
assign   sck_in     =   spi_cr1[CR1_MTSR] ? (spi_cr1[CR1_CPOL]? 1: 0):   ss_io;

endmodule


