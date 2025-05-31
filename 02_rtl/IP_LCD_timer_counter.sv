module IP_LCD_timer_counter #(
    parameter SIZE_DATA     = 8 ,
    parameter SIZE_FUNC     = 4 //,
    // parameter FREQ          = 50_000_000
)(
    input logic         i_clk   ,
    input logic         i_rst_n ,
    input logic         i_en_lcd,
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
// localparam [SIZE_DELAY-1:0]  DELAY_15ms      = (0.015)/(1/FREQ),
//                              DELAY_4_1_ms    = (0.0041)/(1/FREQ),
//                              DELAY_100us     = (0.0001)/(1/FREQ),
//                              DELAY_37us      = (0.000037)/(1/FREQ);
localparam [SIZE_DELAY-1:0]  DELAY_15ms      = 32'd750000,
                             DELAY_4_1_ms    = 32'd205000,
                             DELAY_1_52ms    = 32'd76000,
                             DELAY_100us     = 32'd5000,
                             DELAY_37us      = 32'd1850,
                             DELAY_230ns     = 32'd12;
// logic [SIZE_DELAY-1:0] delay, ndelay;
// localparam [SIZE_DELAY-1:0]  WAIT_15MS       = 1,
//                              WAIT_4_1MS      = 2,
//                              WAIT_100US      = 3,
//                              WAIT_37US       = 4,
//                              WAIT_1_52MS     = 5;

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
                                DONE            = 16,
                                DONE_WAIT       = 17;

// State INIT
parameter SIZE_STEP = 9;
logic [SIZE_STEP-1:0] init_step, ninit_step;
assign ninit_step = init_step + 1;
// logic [SIZE_DATA-1:0] w_init_data;
// State SETCURSOR
// logic [SIZE_DATA-1:0] w_setcursor_data;

always @(*) begin : proc_next_state
    case (state)
        IDLE: begin
            case (w_func_i)
                FUNC_INIT: begin
                    nstate = INIT_SETUP;
                end 
                FUNC_SETCURSOR: begin
                    nstate = SETCURSOR_SETUP;
                end
                FUNC_CMD: begin
                    nstate = CMD_SETUP;
                end
                FUNC_DATA: begin
                    nstate = DATA_SETUP;
                end
                default: begin
                    nstate = IDLE;
                end
            endcase
        end 
        INIT_SETUP: begin
            case (init_step)
                0: begin
                    nstate = INIT_STEP;
                end
                1, 2, 3: begin
                    // w_init_data = CMD_INIT_LCD;
                    nstate = INIT_STEP;
                end
                4: begin
                    // w_init_data = CMD_DISPLAY_OFF;
                    nstate = INIT_STEP;
                end
                5: begin
                    // w_init_data = CMD_CLEAR_DISPLAY;
                    nstate = INIT_STEP;
                end
                6: begin
                    // w_init_data = CMD_RETURN_HOME;
                    nstate = INIT_STEP;
                end
                7: begin
                    // w_init_data = CMD_ENTRY_INCREASE;
                    nstate = INIT_STEP;
                end
                8: begin
                    // w_init_data = CMD_DISPLAY_ON;
                    nstate = INIT_STEP;
                end
                default: begin
                    // w_init_data = 8'h00;
                    nstate = IDLE;
                end
            endcase
        end
        INIT_WAIT: begin
            // case (delay)
            //     WAIT_15MS: begin
            //         nstate = (count == DELAY_15ms) ? INIT_SETUP : INIT_WAIT;
            //     end
            //     WAIT_4_1MS: begin
            //         nstate = (count == DELAY_4_1_ms) ? INIT_SETUP : INIT_WAIT;
            //     end 
            //     WAIT_1_52MS: begin
            //         nstate = (count == DELAY_1_52ms) ? INIT_SETUP : INIT_WAIT;
            //     end
            //     WAIT_100US: begin
            //         nstate = (count == DELAY_100us) ? INIT_SETUP : INIT_WAIT;
            //     end
            //     WAIT_37US: begin
            //         nstate = (count == DELAY_37us) ? INIT_SETUP : INIT_WAIT;
            //     end
            //     default: begin
            //         nstate = INIT_STEP;
            //     end
            // endcase
            case (init_step)
                0       : nstate = (count == DELAY_15ms) ? INIT_SETUP : INIT_WAIT;
                1       : nstate = (count == DELAY_4_1_ms) ? INIT_SETUP : INIT_WAIT;
                2, 3    : nstate = (count == DELAY_100us) ? INIT_SETUP : INIT_WAIT;
                4, 7, 8 : nstate = (count == DELAY_37us) ? INIT_SETUP : INIT_WAIT;
                5, 6    : nstate = (count == DELAY_1_52ms) ? INIT_SETUP : INIT_WAIT;
                default : nstate = INIT_SETUP;
            endcase
        end
        INIT_STEP: begin
            // case (init_step)
            //     0: begin
            //         ndelay = WAIT_15MS;
            //     end 
            //     1: begin
            //         ndelay = WAIT_4_1MS;
            //     end
            //     2, 3: begin
            //         ndelay = WAIT_100US;
            //     end
            //     4: begin
            //         ndelay = WAIT_37US;
            //     end
            //     5, 6: begin
            //         ndelay = WAIT_1_52MS;
            //     end
            //     7, 8: begin
            //         ndelay = WAIT_37US;
            //     end
            //     default: begin
            //         ndelay  = '0;
            //     end
            // endcase
            
            nstate = (init_step > 8) ? DONE : INIT_WAIT;
        end
        SETCURSOR_SETUP: begin
            // case (w_data_i[7:4])
                // 4'h00: begin
                    // w_setcursor_data = CMD_LINE_1 + {4'h0, w_data_i[3:0]};
                // end 
                // 4'h01: begin
                    // w_setcursor_data = CMD_LINE_2 + {4'h0, w_data_i[3:0]};
                // end
                // default: begin
                    // w_setcursor_data = CMD_LINE_1;
                // end
            // endcase
            nstate = SETCURSOR_WAIT;
        end
        SETCURSOR_WAIT: begin
            nstate = (count == DELAY_37us) ? DONE : SETCURSOR_WAIT;
        end
        CMD_SETUP: begin
            // case(w_data_i)
            //     CMD_CLEAR_DISPLAY: begin
            //         ndelay = WAIT_1_52MS;
            //     end
            //     CMD_RETURN_HOME: begin
            //         ndelay = WAIT_1_52MS;
            //     end
            //     default: begin
            //         ndelay = WAIT_37US;
            //     end
            // endcase
            
            nstate = CMD_WAIT;
        end
        CMD_WAIT: begin
            case (w_data_i)
                CMD_CLEAR_DISPLAY: begin
                    nstate = (count == DELAY_1_52ms) ? DONE : CMD_WAIT;
                end 
                CMD_RETURN_HOME: begin
                    nstate = (count == DELAY_37us) ? DONE : CMD_WAIT;
                end
                default: begin
                    nstate = IDLE;
                end
            endcase
        end
        DATA_SETUP: begin
            nstate = DATA_WAIT;
        end
        DATA_WAIT: begin
            nstate = (count == DELAY_37us) ? DONE : DATA_WAIT;
        end
        DONE: begin
            nstate = DONE_WAIT;
        end
        DONE_WAIT: begin
            nstate = (count == DELAY_230ns) ? IDLE : DONE_WAIT;
        end
        default: begin
            nstate = IDLE;
        end
    endcase
end

always_ff @( posedge i_clk or negedge i_rst_n ) begin : proc_state_next_ff
    if(~i_rst_n) begin
        state <= IDLE;
    end else if(~i_en_lcd) begin  // Synchronous disable
        state <= IDLE;
    end else begin
        state <= nstate;
    end
end

always_ff @( posedge i_clk or negedge i_rst_n ) begin : proc_state
    if(~i_rst_n) begin
        count       <= '0;
        init_step   <= '0;
    end else begin
        case (state)
            IDLE: begin
                count       <= '0;
                init_step   <= '0;
            end 
            INIT_SETUP: begin
                count       <= '0;
            end 
            INIT_WAIT: begin
                count <= ncount;
                init_step <= ninit_step;
            end
            INIT_STEP: begin
                count       <= '0;
            end
            SETCURSOR_SETUP: begin
                count       <= '0; 
            end
            SETCURSOR_WAIT: begin
                count       <= ncount; 
            end 
            CMD_SETUP: begin
                count       <= '0; 
            end 
            CMD_WAIT: begin
                count       <= ncount;
            end 
            DATA_SETUP: begin
                count       <= '0;
            end
            DATA_WAIT: begin
                count       <= ncount;    
            end
            DONE: begin
                count       <= '0;
                init_step   <= '0;   
            end
            DONE_WAIT: begin
                count       <= ncount;
                init_step   <= '0;   
            end
            default: begin
                count       <= '0;
                init_step   <= '0;
            end
        endcase
    end
end

// Output Data LCD
// logic [SIZE_DATA-1:0] w_LCD_DATA_o;
// always_ff @( posedge i_clk or negedge i_rst_n ) begin
//     if(~i_rst_n) begin
//         o_LCD_E     <= 1'b0;
//         o_LCD_RW    <= 1'b0;
//         o_LCD_RS    <= 1'B0;
//         o_LCD_DATA  <= '0;
//     end else begin
//         case (state)
//             IDLE: begin
//                 o_LCD_RW    <= 1'b0;
//                 o_LCD_RS    <= 1'B0;
//                 o_LCD_DATA  <= '0;
//             end 
//             INIT_SETUP: begin
//                 o_LCD_RW    <= 1'b0;
//                 o_LCD_RS    <= 1'B0;
//                 o_LCD_DATA  <= '0;
//             end 
//             INIT_WAIT: begin
//                 o_LCD_RW    <= 1'b0;
//                 o_LCD_RS    <= 1'B0;
//             end
//             INIT_STEP: begin
//                 o_LCD_RW    <= 1'b0;
//                 o_LCD_RS    <= 1'B0;

//                 case (init_step)
//                     1, 2, 3: begin
//                         o_LCD_DATA <= CMD_INIT_LCD;
//                     end
//                     4: begin
//                         o_LCD_DATA <= CMD_DISPLAY_OFF;
//                     end
//                     5: begin
//                         o_LCD_DATA <= CMD_CLEAR_DISPLAY;
//                     end
//                     6: begin
//                         o_LCD_DATA <= CMD_RETURN_HOME;
//                     end
//                     7: begin
//                         o_LCD_DATA <= CMD_ENTRY_INCREASE;
//                     end
//                     8: begin
//                         o_LCD_DATA <= CMD_DISPLAY_ON;
//                     end
//                     default: begin
//                         o_LCD_DATA <= 8'h00;
//                     end
//                 endcase
//             end
//             SETCURSOR_SETUP: begin
//                 o_LCD_RW    <= 1'b0;
//                 o_LCD_RS    <= 1'B0;
//                 case (w_data_i[7:4])
//                     4'h00: begin
//                         o_LCD_DATA <= CMD_LINE_1 + {4'h0, w_data_i[3:0]};
//                     end 
//                     4'h01: begin
//                         o_LCD_DATA <= CMD_LINE_2 + {4'h0, w_data_i[3:0]};
//                     end
//                     default: begin
//                         o_LCD_DATA <= CMD_LINE_1;
//                     end
//                 endcase
//             end
//             SETCURSOR_WAIT: begin
//                 o_LCD_RW    <= 1'b0;
//                 o_LCD_RS    <= 1'B0;
//             end
//             CMD_SETUP: begin
//                 o_LCD_RW    <= 1'b0;
//                 o_LCD_RS    <= 1'B0;
//                 o_LCD_DATA  <= w_data_i;
//             end
//             CMD_WAIT: begin
//                 o_LCD_RW    <= 1'b0;
//                 o_LCD_RS    <= 1'B0;
//             end
//             DATA_SETUP: begin
//                 o_LCD_RW    <= 1'b0;
//                 o_LCD_RS    <= 1'B1;
//                 o_LCD_DATA  <= w_data_i;
//             end
//             DATA_WAIT: begin
//                 o_LCD_RW    <= 1'b0;
//                 o_LCD_RS    <= 1'B1;
//             end
//             DONE: begin
//                 o_LCD_E     <= 1'b1;
//             end
//             DONE_WAIT: begin
//                 o_LCD_E     <= 1'b1;  
//             end
//             default: begin
//                 o_LCD_E     <= 1'b0;
//                 o_LCD_RW    <= 1'b0;
//                 o_LCD_RS    <= 1'B0;
//                 o_LCD_DATA  <= '0;
//             end
//         endcase
//     end
// end
always_ff @( posedge i_clk or negedge i_rst_n ) begin : proc_o_LCD_DATA
    if(~i_rst_n) begin
        o_LCD_DATA <= '0;
    end else begin
        case (state)
            INIT_SETUP, INIT_WAIT: begin
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
            SETCURSOR_SETUP, SETCURSOR_WAIT: begin
                case (w_data_i[7:4])
                    4'h00: begin
                        o_LCD_DATA <= CMD_LINE_1 + {4'h0, w_data_i[3:0]};
                    end 
                    4'h01: begin
                        o_LCD_DATA <= CMD_LINE_2 + {4'h0, w_data_i[3:0]};
                    end
                    default: begin
                        o_LCD_DATA <= CMD_LINE_1;
                    end
                endcase
            end
            CMD_SETUP, CMD_WAIT: begin
                o_LCD_DATA <= w_data_i;
            end
            DATA_SETUP, DATA_WAIT: begin
                o_LCD_DATA <= w_data_i;
            end
            default: begin
                o_LCD_DATA <= '0;
            end
        endcase
    end
end

always_ff @( posedge i_clk or negedge i_rst_n ) begin : proc_o_LCD_E
    if(~i_rst_n) begin
        o_LCD_E <= 1'b0;
    end else begin
        case (state)
            DONE        : o_LCD_E <= 1'b1;
            DONE_WAIT   : o_LCD_E <= 1'b1;   
            default     : o_LCD_E <= 1'b0;
        endcase
    end
end

always_ff @( posedge i_clk or negedge i_rst_n ) begin : proc_o_LCD_RW
    if(~i_rst_n) begin
        o_LCD_RW <= 1'b0;
    end else begin
        // case (state)
        //     : 
        //     default: 
        // endcase
        o_LCD_RW <= 1'b0;
    end
end

always_ff @( posedge i_clk or negedge i_rst_n ) begin : proc_o_LCD_RS
    if(~i_rst_n) begin
        o_LCD_RS <= 1'b0;
    end else begin
        case (state)
            DATA_SETUP  : o_LCD_RS <= 1'b1;
            DATA_WAIT   : o_LCD_RS <= 1'b1; 
            default     : o_LCD_RS <= 1'b0; 
        endcase
    end
end

assign o_LCD_ON = i_en_lcd;
assign o_LCD_BLON = i_lcd_blon;
always_ff @( posedge i_clk or negedge i_rst_n ) begin : proc_done_LCD
    if(~i_rst_n) begin
        o_done_lcd <= 1'b0;
    end else begin
        o_done_lcd <= (state == DONE_WAIT && nstate == IDLE) ? 1'b1 : 1'b0;
    end
end

endmodule
