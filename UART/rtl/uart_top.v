

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

















