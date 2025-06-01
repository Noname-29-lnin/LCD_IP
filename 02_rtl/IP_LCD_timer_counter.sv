module IP_LCD_timer_counter #(
    parameter SIZE_DATA     = 8 ,
    parameter SIZE_FUNC     = 4 ,
    parameter FREQ          = 50_000_000
)(
    input logic         i_clk   ,
    input logic         i_rst_n ,
    input logic         i_en_lcd, 
    input logic         i_on_lcd,
    input logic         i_lcd_blon,
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

// Delay
parameter SIZE_DELAY = 32; 
logic [SIZE_DELAY-1:0] count, ncount;
assign ncount = count + 1'b1;
// localparam int  DELAY_15ms      = int'(0.015 * FREQ  + 0.5),
//                 DELAY_4_1_ms    = int'(0.0041 * FREQ + 0.5),
//                 DELAY_1_52ms    = int'(0.00152 * FREQ + 0.5),
//                 DELAY_100us     = int'(0.0001 * FREQ + 0.5),
//                 DELAY_37us      = int'(0.000037 * FREQ + 0.5),
//                 DELAY_230ns     = int'(0.00000023 * FREQ + 0.5);
localparam int  DELAY_15ms      = 50,
                DELAY_4_1_ms    = 30,
                DELAY_1_52ms    = 20,
                DELAY_100us     = 9,
                DELAY_37us      = 4,
                DELAY_230ns     = 2;
// localparam [SIZE_DELAY-1:0]  DELAY_15ms      = 32'd750000,
//                              DELAY_4_1_ms    = 32'd205000,
//                              DELAY_1_52ms    = 32'd76000,
//                              DELAY_100us     = 32'd5000,
//                              DELAY_37us      = 32'd1850,
//                              DELAY_230ns     = 32'd12;

// Func
logic [SIZE_FUNC-1:0] w_func_i, w_func_next;
localparam [SIZE_FUNC-1:0]  FUNC_INIT       = 0 ,
                            FUNC_SETCURSOR  = 1 ,
                            FUNC_CMD        = 2 ,
                            FUNC_DATA       = 3 ;
logic w_update_func;
assign w_update_func = (state == IDLE) ? 1'b1 : 1'b0;
assign w_func_i = w_update_func ? i_func : w_func_next;
always_ff @( posedge i_clk or negedge i_rst_n ) begin : save_i_func
    if(~i_rst_n) begin
        w_func_next <= '0;
    end else begin
        w_func_next <= w_func_i;
    end
end

// Data input
logic [SIZE_DATA-1:0] w_data_i, w_data_next;
logic w_update_data;
assign w_update_data = (state == IDLE) ? 1'b1 : 1'b0;
assign w_data_i = w_update_data ? i_data : w_data_next;
always_ff @( posedge i_clk or negedge i_rst_n ) begin : save_i_data
    if(~i_rst_n) begin
        w_data_next <= '0;
    end else begin
        w_data_next <= w_data_i;
    end
end

// CMD
localparam [SIZE_DATA-1:0] CMD_CLEAR_DISPLAY     = 8'h01, // Xóa màn hình
                           CMD_RETURN_HOME       = 8'h02, // Đưa con trỏ về đầu
                           CMD_ENTRY_INCREASE    = 8'h06, // Tăng địa chỉ, không dịch màn hình
                           CMD_DISPLAY_OFF       = 8'h08, // Tắt hiển thị
                           CMD_DISPLAY_ON        = 8'h0C, // Bật hiển thị, tắt con trỏ
                           CMD_INIT_LCD          = 8'h38, // Chế độ 8-bit, 2 dòng, font 5x8
                           CMD_LINE_1            = 8'h80,
                           CMD_LINE_2            = 8'hC0;

// The case of LCD
parameter SIZE_STATE = 32;
logic [SIZE_STATE-1:0] state, nstate;
localparam  [SIZE_STATE-1:0]    IDLE            = 0 ,
                                INIT_SETUP      = 1 ,
                                INIT_WAIT       = 2 ,
                                INIT_STEP       = 3 ,
                                SETCURSOR_SETUP = 4 ,
                                SETCURSOR_WAIT  = 5 ,
                                CMD_SETUP       = 7 ,
                                CMD_WAIT        = 8 ,
                                DATA_SETUP      = 9 ,
                                DATA_WAIT       = 10,
                                DONE            = 11,
                                DONE_WAIT       = 12,
                                INIT_DONE       = 13,
                                INIT_DONE_WAIT  = 14;

// State INIT
parameter SIZE_STEP = 9;
logic [SIZE_STEP-1:0] init_step, ninit_step;
assign ninit_step = init_step + 1;

always @(*) begin : proc_next_state
    case (state)
        IDLE: begin
            case (w_func_i)
                FUNC_INIT:
                    nstate = (i_en_lcd) ? INIT_SETUP : IDLE;
                FUNC_SETCURSOR:
                    nstate = (i_en_lcd) ? SETCURSOR_SETUP : IDLE;
                FUNC_CMD:
                    nstate = (i_en_lcd) ? CMD_SETUP : IDLE;
                FUNC_DATA:
                    nstate = (i_en_lcd) ? DATA_SETUP : IDLE;
                default:
                    nstate = IDLE;
            endcase
        end 
        INIT_SETUP: begin
            nstate = INIT_STEP;
        end
        INIT_STEP:
            nstate = (init_step > 8) ? IDLE : INIT_WAIT;
        INIT_WAIT: begin
            case (init_step)
                0       : nstate = (count == DELAY_15ms) ? INIT_STEP : INIT_WAIT;
                1       : nstate = (count == DELAY_4_1_ms) ? INIT_DONE : INIT_WAIT;
                2, 3    : nstate = (count == DELAY_100us) ? INIT_DONE : INIT_WAIT;
                4, 7, 8 : nstate = (count == DELAY_37us) ? INIT_DONE : INIT_WAIT;
                5, 6    : nstate = (count == DELAY_1_52ms) ? INIT_DONE : INIT_WAIT;
                default : nstate = INIT_DONE;
            endcase
        end
        INIT_DONE: 
            nstate = INIT_DONE_WAIT;
        INIT_DONE_WAIT:
            nstate = (count == DELAY_230ns) ? INIT_STEP : INIT_DONE_WAIT;
        SETCURSOR_SETUP:
            nstate = SETCURSOR_WAIT;
        SETCURSOR_WAIT:
            nstate = (count == DELAY_37us) ? DONE : SETCURSOR_WAIT;
        CMD_SETUP:
            nstate = CMD_WAIT;
        CMD_WAIT: begin
            case (w_data_i)
                CMD_CLEAR_DISPLAY, CMD_RETURN_HOME:
                    nstate = (count == DELAY_1_52ms) ? DONE : CMD_WAIT;
                default:
                    nstate = (count == DELAY_37us) ? DONE : CMD_WAIT;
            endcase
        end
        DATA_SETUP:
            nstate = DATA_WAIT;
        DATA_WAIT:
            nstate = (count == DELAY_37us) ? DONE : DATA_WAIT;
        DONE:
            nstate = DONE_WAIT;
        DONE_WAIT: 
            nstate = (count == DELAY_230ns) ? IDLE : DONE_WAIT;
        default:
            nstate = IDLE;
    endcase
end

always_ff @( posedge i_clk or negedge i_rst_n ) begin : proc_state_next_ff
    if(~i_rst_n) 
        state <= IDLE;
    else 
        state <= nstate;
end

always_ff @( posedge i_clk or negedge i_rst_n ) begin : proc_state_count
    if(~i_rst_n) begin
        count       <= '0;
    end else begin
        case (state)
            INIT_WAIT, INIT_DONE_WAIT, SETCURSOR_WAIT, CMD_WAIT, DATA_WAIT, DONE_WAIT: 
                count       <= ncount;
            default: 
                count       <= '0;
        endcase
    end
end
always_ff @( posedge i_clk or negedge i_rst_n ) begin : proc_state_init_step
    if(~i_rst_n) begin
        init_step   <= '0;
    end else begin
        case (state)
            IDLE, INIT_SETUP:
                init_step   <= '0;
            INIT_STEP: 
                init_step   <= ninit_step;
            default: 
                init_step   <= init_step;
        endcase
    end
end
always_ff @( posedge i_clk or negedge i_rst_n ) begin : proc_o_LCD_DATA
    if(~i_rst_n) begin
        o_LCD_DATA <= '0;
    end else begin
        case (state)
            IDLE:
                o_LCD_DATA <= '0;
            INIT_STEP: begin
                case (init_step)
                    1, 2, 3: begin
                        o_LCD_DATA <= CMD_INIT_LCD;
                    end
                    4: begin
                        o_LCD_DATA <= CMD_DISPLAY_OFF;
                    end
                    5: begin
                        o_LCD_DATA <= CMD_CLEAR_DISPLAY;
                    end
                    6: begin
                        o_LCD_DATA <= CMD_RETURN_HOME;
                    end
                    7: begin
                        o_LCD_DATA <= CMD_ENTRY_INCREASE;
                    end
                    8: begin
                        o_LCD_DATA <= CMD_DISPLAY_ON;
                    end
                    default: begin
                        o_LCD_DATA <= 8'h00;
                    end
                endcase
            end 
            SETCURSOR_SETUP: begin
                case (w_data_i[7:4])
                    4'h00: 
                        o_LCD_DATA <= CMD_LINE_1 + {4'h0, w_data_i[3:0]};
                    4'h01: 
                        o_LCD_DATA <= CMD_LINE_2 + {4'h0, w_data_i[3:0]};
                    default: 
                        o_LCD_DATA <= CMD_LINE_1;
                endcase
            end
            CMD_SETUP: 
                o_LCD_DATA <= w_data_i;
            DATA_SETUP: 
                o_LCD_DATA <= w_data_i;
            default: 
                o_LCD_DATA <= o_LCD_DATA;
        endcase
    end
end

always_ff @( posedge i_clk or negedge i_rst_n ) begin : proc_o_LCD_E
    if(~i_rst_n) begin
        o_LCD_E <= 1'b0;
    end else begin
        case (state)
            INIT_DONE       : o_LCD_E <= 1'b1;
            INIT_DONE_WAIT  : o_LCD_E <= 1'b1;
            DONE            : o_LCD_E <= 1'b1;
            DONE_WAIT       : o_LCD_E <= 1'b1;   
            default         : o_LCD_E <= 1'b0;
        endcase
    end
end

always_ff @( posedge i_clk or negedge i_rst_n ) begin : proc_o_LCD_RW
    if(~i_rst_n) begin
        o_LCD_RW <= 1'b0;
    end else begin
        o_LCD_RW <= 1'b0;
    end
end

always_ff @( posedge i_clk or negedge i_rst_n ) begin : proc_o_LCD_RS
    if(~i_rst_n) begin
        o_LCD_RS <= 1'b0;
    end else begin
        case (state)
            DATA_SETUP, DATA_WAIT: 
                o_LCD_RS <= 1'b1;
            INIT_DONE, INIT_DONE_WAIT, DONE, DONE_WAIT:
                o_LCD_RS <= o_LCD_RS;
            default: 
                o_LCD_RS <= 1'b0; 
        endcase
    end
end

assign o_LCD_ON = i_on_lcd;
assign o_LCD_BLON = i_lcd_blon;
always_ff @( posedge i_clk or negedge i_rst_n ) begin : proc_done_LCD
    if(~i_rst_n) begin
        o_done_lcd <= 1'b0;
    end else begin
        o_done_lcd <= ((state == DONE_WAIT && nstate == IDLE) || (init_step > 8)) ? 1'b1 : 1'b0;
    end
end

endmodule
