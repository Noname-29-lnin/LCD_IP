// // Macro để ghi lệnh (command) vào LCD
// `define WriteCommand(ctr_en, ctr_rw, ctr_rs, data, source) \
//     begin \
//         data    <= source; \
//         ctr_en  <= 1'b1; \
//         ctr_rw  <= 1'b0; \
//         ctr_rs  <= 1'b0; \
//     end

// // Macro để ghi dữ liệu (data) vào LCD
// `define WriteData(ctr_en, ctr_rw, ctr_rs, data, source) \
//     begin \
//         data    <= source; \
//         ctr_en  <= 1'b1; \
//         ctr_rw  <= 1'b0; \
//         ctr_rs  <= 1'b1; \
//     end

// module IP_LCD_control #(
//     parameter SIZE_DATA     = 8,    // Độ rộng dữ liệu: 8 bit
//     parameter SIZE_FUNC     = 2,    // Độ rộng chức năng: 2 bit
//     parameter CLK_FREQ      = 50_000_000 // Tần số clock: 50 MHz (DE2)
// )(
//     input  logic                    i_clk,      // Clock đầu vào (50 MHz trên DE2)
//     input  logic                    i_rst_n,    // Reset active low
//     input  logic [SIZE_DATA-1:0]    i_data,     // Dữ liệu hoặc lệnh đầu vào
//     input  logic [SIZE_FUNC-1:0]    i_func,     // Chức năng đầu vào
//     output logic [SIZE_DATA-1:0]    o_LCD_DATA, // Dữ liệu ra cho LCD
//     output logic                    o_LCD_RW,   // Read/Write (0: write)
//     output logic                    o_LCD_RS,   // Register Select (0: command, 1: data)
//     output logic                    o_LCD_E,    // Enable tín hiệu LCD
//     output logic                    o_LCD_ON,   // Bật LCD
//     output logic                    o_LCD_BLON, // Bật đèn nền
//     output logic                    o_valid     // Tín hiệu hoàn thành
// );

// // Định nghĩa các chức năng
// typedef enum logic [SIZE_FUNC-1:0] {
//     FUNC_INIT       = 2'h0, // Khởi tạo LCD
//     FUNC_SETCURSOR  = 2'h1, // Đặt vị trí con trỏ
//     FUNC_DATA       = 2'h2, // Ghi dữ liệu
//     FUNC_CMD        = 2'h3  // Ghi lệnh
// } func_t;

// // Định nghĩa trạng thái FSM
// typedef enum logic [4:0] {
//     MODE_IDLE           = 5'h0, // Trạng thái chờ
//     MODE_INIT           = 5'h1, // Bắt đầu khởi tạo
//     MODE_INIT_MAINTAIN  = 5'h2, // Chờ khởi tạo
//     MODE_INIT_STEP      = 5'h3, // Thực hiện các bước khởi tạo
//     MODE_CMD            = 5'h4, // Ghi lệnh
//     MODE_DATA           = 5'h5, // Ghi dữ liệu
//     MODE_SETCURSOR      = 5'h6, // Đặt con trỏ
//     MODE_DONE           = 5'h7,  // Hoàn thành
//     MODE_CMD_WAIT       = 5'h8,  // Cho CMD hoan thanh
//     MODE_DATA_WAIT      = 5'h9, 
//     MODE_SETCURSOR_WAIT = 5'hA
// } state_t;

// // Định nghĩa các lệnh LCD theo HD44780U
// localparam [SIZE_DATA-1:0] CMD_CLEAR_DISPLAY     = 8'h01, // Xóa màn hình
//                            CMD_RETURN_HOME       = 8'h02, // Đưa con trỏ về đầu
//                            CMD_ENTRY_INCREASE    = 8'h06, // Tăng địa chỉ, không dịch màn hình
//                            CMD_DISPLAY_OFF       = 8'h08, // Tắt hiển thị
//                            CMD_DISPLAY_ON        = 8'h0C, // Bật hiển thị, tắt con trỏ
//                            CMD_INIT_LCD          = 8'h38; // Chế độ 8-bit, 2 dòng, font 5x8

// // Định nghĩa thời gian chờ (dựa trên clock 50 MHz)
// localparam SIZE_DELAY = 32;
// localparam [SIZE_DELAY-1:0] DELAY_15ms   = CLK_FREQ / 1000 * 15,    // 15ms
//                             DELAY_4_1ms  = CLK_FREQ / 1000 * 4.1,  // 4.1ms
//                             DELAY_100us  = CLK_FREQ / 10000,       // 100us
//                             DELAY_1_52ms = CLK_FREQ / 1000 * 1.52, // 1.52ms
//                             DELAY_37us   = CLK_FREQ / 100000 * 37; // 37us

// // Biến nội bộ
// logic [4:0]                 state, nstate;      // Trạng thái hiện tại và tiếp theo
// logic [SIZE_DELAY-1:0]      delay_count;        // Bộ đếm thời gian chờ
// logic [SIZE_DATA-1:0]       t_cmd_data;         // Dữ liệu lệnh tạm thời
// logic [3:0]                 init_step;          // Bước khởi tạo

// // Logic chuyển trạng thái
// always_comb begin
//     nstate = state;
//     case (state)
//         MODE_IDLE: begin
//             case (i_func)
//                 FUNC_INIT:      nstate = MODE_INIT;
//                 FUNC_SETCURSOR: nstate = MODE_SETCURSOR;
//                 FUNC_DATA:      nstate = MODE_DATA;
//                 FUNC_CMD:       nstate = MODE_CMD;
//                 default:        nstate = MODE_IDLE;
//             endcase
//         end
//         MODE_INIT: begin
//             nstate = MODE_INIT_MAINTAIN;
//         end
//         MODE_INIT_MAINTAIN: begin
//             if (delay_count >= DELAY_15ms) begin
//                 nstate = MODE_INIT_STEP;
//             end else begin
//                 nstate = MODE_INIT_MAINTAIN;
//             end
//         end
//         MODE_INIT_STEP: begin
//             if (init_step >= 8) begin
//                 nstate = MODE_DONE;
//             end else begin
//                 nstate = MODE_INIT_STEP;
//             end
//         end
//         MODE_SETCURSOR: begin
//             case (i_data[7:4])
//                     4'h0: t_cmd_data = 8'h80 + {4'h0, i_data[3:0]}; // Dòng 1
//                     4'h1: t_cmd_data = 8'h80 + 8'h40 + {4'h0, i_data[3:0]}; // Dòng 2
//                     default: t_cmd_data = 8'h80; // Mặc định dòng 1, vị trí 0
//             endcase 

//             if (delay_count >= DELAY_37us) begin
//                 nstate = MODE_DONE;
//             end else begin
//                 nstate = MODE_SETCURSOR;
//             end
//         end
//         MODE_DATA: begin
//             if (delay_count >= DELAY_37us) begin
//                 nstate = MODE_DONE;
//             end else begin
//                 nstate = MODE_DATA;
//             end
//         end
//         MODE_CMD: begin
//             if (i_data == CMD_CLEAR_DISPLAY || i_data == CMD_RETURN_HOME) begin
//                 if (delay_count >= DELAY_1_52ms) begin
//                     nstate = MODE_DONE;
//                 end else begin
//                     nstate = MODE_CMD;
//                 end
//             end else begin
//                 if (delay_count >= DELAY_37us) begin
//                     nstate = MODE_DONE;
//                 end else begin
//                     nstate = MODE_CMD;
//                 end
//             end
//         end
//         MODE_DONE: begin
//             nstate = MODE_IDLE;
//         end
//         default: begin
//             nstate = MODE_IDLE;
//         end
//     endcase
// end

// // Logic điều khiển đầu ra và trạng thái
// always_ff @(posedge i_clk or negedge i_rst_n) begin
//     if (!i_rst_n) begin
//         state           <= MODE_IDLE;
//         o_LCD_E         <= 1'b0;
//         o_LCD_RW        <= 1'b0;
//         o_LCD_RS        <= 1'b0;
//         o_LCD_DATA      <= 8'h00;
//         o_LCD_ON        <= 1'b1;  // Bật LCD
//         o_LCD_BLON      <= 1'b0;  // Tắt đèn nền
//         delay_count     <= '0;
//         init_step       <= '0;
//         o_valid         <= 1'b0;
//     end else begin
//         state <= nstate;
//         o_valid <= (nstate == MODE_DONE) ? 1'b1 : 1'b0;

//         case (state)
//             MODE_IDLE: begin
//                 o_LCD_E <= 1'b0;
//                 delay_count <= '0;
//             end
//             MODE_INIT: begin
//                 o_LCD_E <= 1'b0;
//                 delay_count <= '0;
//                 init_step <= '0;
//             end
//             MODE_INIT_MAINTAIN: begin
//                 delay_count <= delay_count + 1;
//             end
//             MODE_INIT_STEP: begin
//                 case (init_step)
//                     0: begin
//                         `WriteCommand(o_LCD_E, o_LCD_RW, o_LCD_RS, o_LCD_DATA, CMD_INIT_LCD)
//                         delay_count <= delay_count + 1;
//                         if (delay_count >= DELAY_4_1ms) begin
//                             delay_count <= '0;
//                             init_step <= init_step + 1;
//                         end
//                     end
//                     1, 2, 3: begin
//                         `WriteCommand(o_LCD_E, o_LCD_RW, o_LCD_RS, o_LCD_DATA, CMD_INIT_LCD)
//                         delay_count <= delay_count + 1;
//                         if (delay_count >= DELAY_100us) begin
//                             delay_count <= '0;
//                             o_LCD_E <= 1'b0;
//                             init_step <= init_step + 1;
//                         end
//                     end
//                     4: begin
//                         `WriteCommand(o_LCD_E, o_LCD_RW, o_LCD_RS, o_LCD_DATA, CMD_DISPLAY_OFF)
//                         delay_count <= delay_count + 1;
//                         if (delay_count >= DELAY_37us) begin
//                             delay_count <= '0;
//                             o_LCD_E <= 1'b0;
//                             init_step <= init_step + 1;
//                         end
//                     end
//                     5: begin
//                         `WriteCommand(o_LCD_E, o_LCD_RW, o_LCD_RS, o_LCD_DATA, CMD_CLEAR_DISPLAY)
//                         delay_count <= delay_count + 1;
//                         if (delay_count >= DELAY_1_52ms) begin
//                             delay_count <= '0;
//                             o_LCD_E <= 1'b0;
//                             init_step <= init_step + 1;
//                         end
//                     end
//                     6: begin
//                         `WriteCommand(o_LCD_E, o_LCD_RW, o_LCD_RS, o_LCD_DATA, CMD_ENTRY_INCREASE)
//                         delay_count <= delay_count + 1;
//                         if (delay_count >= DELAY_37us) begin
//                             delay_count <= '0;
//                             o_LCD_E <= 1'b0;
//                             init_step <= init_step + 1;
//                         end
//                     end
//                     7: begin
//                         `WriteCommand(o_LCD_E, o_LCD_RW, o_LCD_RS, o_LCD_DATA, CMD_DISPLAY_ON)
//                         delay_count <= delay_count + 1;
//                         if (delay_count >= DELAY_37us) begin
//                             delay_count <= '0;
//                             o_LCD_E <= 1'b0;
//                             init_step <= init_step + 1;
//                         end
//                     end
//                     default: begin
//                         o_LCD_E <= 1'b0;
//                     end
//                 endcase
//             end
//             MODE_SETCURSOR: begin
//                 // case (i_data[7:4])
//                 //     4'h0: t_cmd_data <= 8'h80 + i_data[3:0]; // Dòng 1
//                 //     4'h1: t_cmd_data <= 8'h80 + 8'h40 + i_data[3:0]; // Dòng 2
//                 //     default: t_cmd_data <= 8'h80; // Mặc định dòng 1, vị trí 0
//                 // endcase
//                 `WriteCommand(o_LCD_E, o_LCD_RW, o_LCD_RS, o_LCD_DATA, t_cmd_data)
//                 delay_count <= delay_count + 1;
//                 if (delay_count >= DELAY_37us) begin
//                     o_LCD_E <= 1'b0;
//                     delay_count <= '0;
//                 end
//             end
//             MODE_DATA: begin
//                 `WriteData(o_LCD_E, o_LCD_RW, o_LCD_RS, o_LCD_DATA, i_data)
//                 delay_count <= delay_count +1;
//                 if (delay_count >= DELAY_37us) begin
//                     o_LCD_E <= 1'b0;
//                     delay_count <= '0;
//                 end
//             end
//             MODE_CMD: begin
//                 `WriteCommand(o_LCD_E, o_LCD_RW, o_LCD_RS, o_LCD_DATA, i_data)
//                 delay_count <= delay_count + 1;
//                 if (i_data == CMD_CLEAR_DISPLAY || i_data == CMD_RETURN_HOME) begin
//                     if (delay_count >= DELAY_1_52ms) begin
//                         o_LCD_E <= 1'b0;
//                         delay_count <= '0;
//                     end
//                 end else begin
//                     if (delay_count >= DELAY_37us) begin
//                         o_LCD_E <= 1'b0;
//                         delay_count <= '0;
//                     end
//                 end
//             end
//             MODE_DONE: begin
//                 o_LCD_E <= 1'b0;
//                 o_LCD_RS <= 1'b0;
//                 o_LCD_RW <= 1'b0;
//                 delay_count <= '0;
//             end
//             default: begin
//                 o_LCD_E <= 1'b0;
//                 o_LCD_RS <= 1'b0;
//                 o_LCD_RW <= 1'b0;
//                 delay_count <= '0;
//             end
//         endcase
//     end
// end

// endmodule

module IP_LCD_control #(
    parameter SIZE_DATA     = 8,
    parameter SIZE_FUNC     = 3,
    parameter CLK_FREQ      = 50_000_000
)(
    input logic                     i_clk       ,
    input logic                     i_rst_n     ,
    input logic [SIZE_DATA-1:0]     i_data      ,
    input logic [SIZE_FUNC-1:0]     i_func      ,
    output logic [SIZE_DATA-1:0]    o_LCD_DATA  ,
    output logic                    o_LCD_E     ,
    output logic                    o_LCD_RW    ,
    output logic                    o_LCD_RS    ,
    output logic                    o_LCD_ON    ,
    output logic                    o_LCD_BLON  ,
    output logic                    o_valid         
);

// localparam [SIZE_FUNC-1:0]  FUNC_INIT        = 2'h0  , // Init LCD
                            // FUNC_SETCURSOR   = 2'h1  , // Set cursor 
                            // FUNC_DATA        = 2'h2  , // This is Data
                            // FUNC_CMD         = 2'h3  ; // This is command
localparam [SIZE_FUNC-1:0]  FUNC_INIT        = 3'h1  , // Init LCD
                            FUNC_SETCURSOR   = 3'h2  , // Set cursor 
                            FUNC_DATA        = 3'h3  , // This is Data
                            FUNC_CMD         = 3'h4  ; // This is command
parameter SIZE_STATE = 5;
localparam [SIZE_STATE-1:0] MODE_IDLE           = 5'h0    ,
                            MODE_INIT           = 5'h1    ,
                            MODE_INIT_WAIT      = 5'h2    ,
                            MODE_INIT_STEP      = 5'h3    ,
                            MODE_SETCURSOR      = 5'h4    ,
                            MODE_SETCURSOR_WAIT = 5'h5    ,
                            MODE_DATA           = 5'h6    ,
                            MODE_DATA_WAIT      = 5'h7    ,
                            MODE_CMD            = 5'h8    ,
                            MODE_CMD_WAIT       = 5'h9    ,
                            MODE_DONE           = 5'hA    ;


parameter SIZE_DELAY = 32;
localparam [SIZE_DELAY-1:0] DELAY_10ms      = CLK_FREQ / 1000 * 10      , // thoi gian cho khoi dong nguyen
                            DELAY_4_1ms     = (CLK_FREQ * 41) / 10000   ,
                            DELAY_100us     = (CLK_FREQ) / 10000        ,
                            DELAY_1_52ms    = (CLK_FREQ * 19) / 12500   ,
                            DELAY_37us      = (CLK_FREQ) / 100000 * 37;

localparam [SIZE_DATA-1:0] CMD_CLEAR_DISPLAY     = 8'h01, // Xóa màn hình
                           CMD_RETURN_HOME       = 8'h02, // Đưa con trỏ về đầu
                           CMD_ENTRY_INCREASE    = 8'h06, // Tăng địa chỉ, không dịch màn hình
                           CMD_DISPLAY_OFF       = 8'h08, // Tắt hiển thị
                           CMD_DISPLAY_ON        = 8'h0C, // Bật hiển thị, tắt con trỏ
                           CMD_INIT_LCD          = 8'h38, // Chế độ 8-bit, 2 dòng, font 5x8
                           CMD_LINE_1            = 8'h80,
                           CMD_LINE_2            = 8'hC0;
// Bien noi bo
logic [SIZE_STATE-1:0] state, nstate;
logic [SIZE_DELAY-1:0] delay_count;
// logic [SIZE_DATA-1:0]  t_cmd_data;
logic [3:0]            init_step;

// Combinational
// always @(posedge i_clk) begin : proc_setcursor_data
//     case (i_data[7:4])
//         4'h0: t_cmd_data <= CMD_LINE_1 + {4'h0, i_data[3:0]};
//         4'h1: t_cmd_data <= CMD_LINE_2 + {4'h0, i_data[3:0]};
//         default: t_cmd_data <= CMD_LINE_1;
//     endcase
// end

always_comb begin : proc_nstate
    case(state)
        MODE_IDLE: begin
            case(i_func)
                FUNC_INIT:      nstate = MODE_INIT     ;
                FUNC_SETCURSOR: nstate = MODE_SETCURSOR;
                FUNC_DATA:      nstate = MODE_DATA     ;
                FUNC_CMD:       nstate = MODE_CMD      ;
                default:        nstate = MODE_IDLE     ;
            endcase
        end

        MODE_INIT: begin
            nstate = (delay_count < DELAY_10ms) ? MODE_INIT : MODE_INIT_WAIT; 
        end
        
        MODE_INIT_WAIT: begin
            // nstate = MODE_INIT_STEP;
            nstate = (init_step < 9) ? MODE_INIT_STEP : MODE_DONE;
        end

        MODE_INIT_STEP: begin
            case(init_step)
                0: begin
                    nstate = (delay_count < DELAY_4_1ms) ? MODE_INIT_STEP : MODE_INIT_WAIT;
                end
                1, 2, 3: begin
                    nstate = (delay_count < DELAY_100us) ? MODE_INIT_STEP : MODE_INIT_WAIT;
                end
                4, 7, 8: begin
                    nstate = (delay_count < DELAY_37us) ? MODE_INIT_STEP : MODE_INIT_WAIT;
                end
                5, 6: begin
                    nstate = (delay_count < DELAY_1_52ms) ? MODE_INIT_STEP : MODE_INIT_WAIT;
                end
                // 6, 7: begin
                //     nstate = (delay_count < DELAY_37us) ? MODE_INIT_STEP : MODE_INIT_WAIT;
                // end
                default: begin
                    nstate = MODE_IDLE;
                end
            endcase
        end
        
        MODE_SETCURSOR: begin
            nstate = MODE_SETCURSOR_WAIT;
        end

        MODE_SETCURSOR_WAIT: begin
            nstate = (delay_count < DELAY_37us) ? MODE_SETCURSOR_WAIT : MODE_DONE;
        end

        MODE_DATA: begin
            nstate = MODE_DATA_WAIT;
        end

        MODE_DATA_WAIT: begin
            nstate = (delay_count < DELAY_37us) ? MODE_DATA_WAIT : MODE_DONE;
        end

        MODE_CMD: begin
             nstate = MODE_CMD_WAIT;
        end

        MODE_CMD_WAIT: begin
            if(i_data == CMD_CLEAR_DISPLAY || i_data == CMD_RETURN_HOME)
                nstate = (delay_count < DELAY_1_52ms) ? MODE_CMD_WAIT : MODE_DONE;
            else
                nstate = (delay_count < DELAY_37us) ? MODE_CMD_WAIT : MODE_DONE;
        end

        MODE_DONE: begin
            nstate = MODE_IDLE;
        end

        default: begin
            nstate = MODE_IDLE;
        end
    endcase
end

// sequency
always_ff @( posedge i_clk or negedge i_rst_n ) begin : proc_state
    if(~i_rst_n) begin
        delay_count     <= '0;
        state           <= MODE_IDLE;
        init_step       <= '0;
        // t_cmd_data      <= '0;
        o_LCD_E         <= 1'b0;
        o_LCD_RW        <= 1'b0;
        o_LCD_RS        <= 1'b0;
        o_LCD_DATA      <= 8'h00;
        o_LCD_ON        <= 1'b1;  // Bật LCD
        o_LCD_BLON      <= 1'b0;  // Tắt đèn nền
        delay_count     <= '0;
        init_step       <= '0;
        o_valid         <= 1'b0;
    end else begin

        // case (i_data[7:4])
        //     4'h0: t_cmd_data <= CMD_LINE_1 + {4'h0, i_data[3:0]};
        //     4'h1: t_cmd_data <= CMD_LINE_2 + {4'h0, i_data[3:0]};
        //     default: t_cmd_data <= CMD_LINE_1;
        // endcase

        state <= nstate;
        // o_valid <= (nstate == MODE_DONE) ? 1'b1 : 1'b0;
        o_valid <= (state == MODE_DONE) ? 1'b1 : 1'b0; // thay doi tai sau chu ky xong 

        case (state)
            
            MODE_IDLE: begin
                o_LCD_BLON      <= 1'b1;
                delay_count     <= '0;
                init_step       <= '0;
            end 

            MODE_INIT: begin
                delay_count     <= delay_count + 1;
                o_LCD_E         <= 1'b0;
            end 

            MODE_INIT_WAIT: begin
                o_LCD_E         <= 1'b1;
                delay_count     <= '0;
            end

            MODE_INIT_STEP: begin
                case(init_step)
                    0: begin
                        o_LCD_RS    <= 1'b0;
                        o_LCD_RW    <= 1'b0;
                        o_LCD_DATA  <= CMD_INIT_LCD;
                        delay_count <= delay_count + 1;
                        init_step   <= (delay_count < DELAY_4_1ms) ? init_step : init_step + 1;
                    end
                    1, 2, 3: begin
                        o_LCD_RS    <= 1'b0;
                        o_LCD_RW    <= 1'b0;
                        o_LCD_DATA  <= CMD_INIT_LCD;
                        delay_count <= delay_count + 1;
                        init_step   <= (delay_count < DELAY_100us) ? init_step : init_step + 1;
                    end
                    4: begin
                        o_LCD_RS    <= 1'b0;
                        o_LCD_RW    <= 1'b0;
                        o_LCD_DATA  <= CMD_DISPLAY_OFF;
                        delay_count <= delay_count + 1;
                        init_step   <= (delay_count < DELAY_37us) ? init_step : init_step + 1;
                    end
                    5: begin
                        o_LCD_RS    <= 1'b0;
                        o_LCD_RW    <= 1'b0;
                        o_LCD_DATA  <= CMD_CLEAR_DISPLAY;
                        delay_count <= delay_count + 1;
                        init_step   <= (delay_count < DELAY_1_52ms) ? init_step : init_step + 1;
                    end
                    6: begin
                        o_LCD_RS    <= 1'b0;
                        o_LCD_RW    <= 1'b0;
                        o_LCD_DATA  <= CMD_RETURN_HOME;
                        delay_count <= delay_count + 1;
                        init_step   <= (delay_count < DELAY_1_52ms) ? init_step : init_step + 1;
                    end
                    7: begin
                        o_LCD_RS    <= 1'b0;
                        o_LCD_RW    <= 1'b0;
                        o_LCD_DATA  <= CMD_ENTRY_INCREASE;
                        delay_count <= delay_count + 1;
                        init_step   <= (delay_count < DELAY_37us) ? init_step : init_step + 1;
                    end
                    8: begin
                        o_LCD_RS    <= 1'b0;
                        o_LCD_RW    <= 1'b0;
                        o_LCD_DATA  <= CMD_DISPLAY_ON;
                        delay_count <= delay_count + 1;
                        init_step   <= (delay_count < DELAY_37us) ? init_step : init_step + 1;
                    end
                    default: begin
                        o_LCD_E     <= 1'b0;
                        o_LCD_RS    <= 1'b0;
                        o_LCD_RW    <= 1'b0;
                        init_step   <= '0; 
                    end
                endcase
            end

            MODE_SETCURSOR: begin
                o_LCD_E         <= 1'b1;
                o_LCD_RS        <= 1'b0;
                o_LCD_RW        <= 1'b0;
                delay_count     <= '0;
                // o_LCD_DATA      <= t_cmd_data;
                o_LCD_DATA      <= (i_data[4]) ? CMD_LINE_2 + {4'h0, i_data[3:0]} : CMD_LINE_1 + {4'h0, i_data[3:0]};
            end

            MODE_SETCURSOR_WAIT: begin
                delay_count     <= delay_count + 1;
            end

            MODE_DATA: begin
                o_LCD_E        <= 1'b1;
                o_LCD_RS       <= 1'b1;
                o_LCD_RW       <= 1'b0;
                delay_count    <= '0; 
                o_LCD_DATA     <= i_data;
            end

            MODE_DATA_WAIT: begin
                delay_count    <= delay_count + 1;
            end

            MODE_CMD: begin
                o_LCD_E        <= 1'b1;
                o_LCD_RS       <= 1'b0;
                o_LCD_RW       <= 1'b0;
                delay_count    <= '0; 
                o_LCD_DATA     <= i_data;
            end

            MODE_CMD_WAIT: begin
                delay_count    <= delay_count + 1;
            end

            MODE_DONE: begin
                o_LCD_E         <= 1'b0;
                o_LCD_RS        <= 1'b0;
                o_LCD_RW        <= 1'b0;
            end 

            default: begin
                delay_count <= '0;     
                init_step   <= '0;
                // t_cmd_data  <= '0; 
                o_LCD_E         <= 1'b0;
                o_LCD_RW        <= 1'b0;
                o_LCD_RS        <= 1'b0;
                o_LCD_BLON      <= 1'b0;
            end 
        endcase
    end
end

endmodule