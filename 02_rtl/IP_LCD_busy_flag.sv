module IP_LCD_busy_flag #(
    parameter SIZE_DATA     = 8 ,
    parameter SIZE_FUNC     = 4  
)(
    input logic         i_clk   ,
    input logic         i_rst_n ,
    input logic         i_en_lcd,
    input logic [SIZE_DATA-1:0] i_data,
    input logic [SIZE_FUNC-1:0] i_func,

    output logic [SIZE_DATA-1:0]    o_LCD_DATA  ,
    output logic                    o_LCD_E     ,
    output logic                    o_LCD_RW    ,
    output logic                    o_LCD_RS    ,
    output logic                    o_LCD_ON    ,
    output logic                    o_LCD_BLON  ,
    output logic                    o_done_lcd  
);


    
endmodule
