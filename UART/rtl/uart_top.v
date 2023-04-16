

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
module   uart_top #(     parameter   APB_DATA_WIDTH    =  32,
                        parameter   APB_ADDR_WIDTH    =  32,
                        parameter   TIMEOUT_CYCLE     =  6,
                        parameter   UART_REG_BASE      =  32'ha0300000 )
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
















endmodule


