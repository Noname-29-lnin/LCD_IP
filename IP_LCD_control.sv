`define WriteCommand(ctr_en, ctr_rw, ctr_rs, data, source)  \
                    data    <= source               \
                    ctr_en  <= 1'b1                 \
                    ctr_rw  <= 1'b0                 \
                    ctr_rs  <= 1'b0
`define WriteData(ctr_en, ctr_rw, ctr_rs, data, source) \
                    data    <= source           \
                    ctr_en  <= 1'b1             \
                    ctr_rw  <= 1'b0             \
                    ctr_rs  <= 1'b1

module IP_LCD_control #(
    parameter SIZE_DATA     = 8,
    parameter SIZE_FUNC     = 2 
)(
    input logic                     i_clk   ,   // Clock from DLL
    input logic                     i_rst_n ,   // Reset active low
    input logic [SIZE_DATA-1:0]     i_data  ,   // Input data or command 
    input logic [SIZE_FUNC-1:0]     i_func  ,   // Input function 
    output logic [SIZE_DATA-1:0]    o_LCD_DATA  ,   // Output data LCD 
    output logic                    o_LCD_RW    ,   // RW: Enable write data  
    output logic                    o_LCD_RS    ,
    output logic                    o_LCD_E     ,
    output logic                    o_LCD_ON    ,
    output logic                    o_LCD_BLON  ,
    output logic                    o_valid     
);

// Define i_func
localparam FUNC_INIT        = SIZE_FUNC'h0;
localparam FUNC_SETCURSOR   = SIZE_FUNC'h1;
localparam FUNC_DATA        = SIZE_FUNC'h2;
localparam FUNC_CMD         = SIZE_FUNC'h3;

// Define state in FSM
parameter SIZE_FSM = 11;
logic [SIZE_FSM-1:0] state, nstate;
localparam [SIZE_FSM-1:0] MODE_IDLE             = SIZE_FSM'h0,  // Trang thai cho
                          MODE_INIT             = SIZE_FSM'h1,  // Trang thai khoi tao 
                          MODE_INIT_MAINTAIN    = SIZE_FSM'h2,  // Trang thai cho khoi tao
                          MODE_INIT_STEP        = SIZE_FSM'h3,  // Trang thai thuc hien cac buoc INIT 
                          MODE_CMD              = SIZE_FSM'h4,  // Trang thai nap Command
                          MODE_CMD_MAINTAIN     = SIZE_FSM'h5,  // Trang thai cho nap command
                          MODE_DATA             = SIZE_FSM'h6,  // Trang thai nap Data 
                          MODE_DATA_MAINTAIN    = SIZE_FSM'h7,  // Trang thai cho nap Data 
                          MODE_SETCURSOR        = SIZE_FSM'h8,  // Trang thai chinh con tro
                          // MODE_SETCURSOR_MAINTAIN=SIZE_FSM'h8,  // Trang thai cho chinh con tro
                          MODE_DONE             = SIZE_FSM'h10; // Done 

parameter SIZE_DELAY = 32; // for F = 1MHz
logic [SIZE_DELAY-1:0] delay_count;
localparam [SIZE_DELAY-1:0] DELAY_15ms          = SIZE_DELAY'd15000, // 15ms: thoi gian sau khi reset_n
                            DELAY_4_1ms         = SIZE_DELAY'd4100 , // 4.1ms:
                            DELAY_1ms           = SIZE_DELAY'd1000 , // 1ms : 
                            DELAY_1_52ms        = SIZE_DELAY'd1520 , // 1.52ms: lenh clear and return home
                            DELAY_100us         = SIZE_DELAY'd100  , // 100us: cho cac lenh init khac
                            DELAY_37us          = SIZE_DELAY'd37   ; // 37us : cac command co ban

logic [SIZE_DATA-1:0]  t_cmd_data ; // temp command data 
logic [7:0] init_step;      // Dem cac buoc init_step
localparam [SIZE_DATA-1:0]  CMD_CLEAR_DISPLAY   = SIZE_DATA'h01    , // Clear display 
                            CMD_RETRUN_HOME     = SIZE_DATA'h02    , // Retrun cursor home
                            CMD_EMTRY_INCREASE  = SIZE_DATA'h04    , // Entry mode: giam dia chi, khong dich man hing
                            CMD_EMTRY_DECREASE  = SIZE_DATA'h06    , // Entry mode: tang dia chi, khong dich man hinh
                            CMD_DISPLAY_OFF_CURSOR_OFF = SIZE_DATA'h08,
                            CMD_DISPLAY_ON_CURSOR_OFF  = SIZE_DATA'h0C,
                            CMD_DISPLAY_ON_CURSOR_ON   = SIZE_DATA'h0E,
                            CMD_CURSOR_LEFT     = SIZE_DATA'h10    , // Dich con tro sang trai
                            CMD_CURSOR_RIGHT    = SIZE_DATA'h14    , // Dich con tro sang phai
                            CMD_DISPLAY_LEFT    = SIZE_DATA'h18    , // Dich man hinh sang trai
                            CMD_DISPLAY_RIGHT   = SIZE_DATA'h1C    , // Dich man hinh sang phai
                            CMD_INIT_LCD        = SIZE_DATA'h38    ; // Che do 8-bit, 2line, font 5x8


always_comb begin
    nstate = state; // doc trang thai hien tai 

    case(nstate)
        MODE_IDLE: begin
            case(i_func)
                FUNC_INIT: 
                    nstate = MODE_INIT;
                FUNC_SETCURSOR:
                    nstate = MODE_SETCURSOR;
                FUNC_DATA:
                    nstate = MODE_DATA;
                FUNC_CMD:
                    nstate = MODE_CMD;
                default:
                    nstate = MODE_IDLE;
            endcase
        end 
        MODE_INIT: begin
            delay_count = 0;
            init_step   = 0;
            nstate = MODE_INIT_MAINTAIN;
        end 
        MODE_INIT_MAINTAIN: begin
            if(delay_count >= DELAY_15ms) begin
                delay_count = 0;
                nstate = MODE_INIT_STEP;
            end else 
                nstate = MODE_INIT_MAINTAIN;
        end 
        MODE_INIT_STEP: begin
            if(init_step < 8) begin  
                delay_count = 0;
                nstate = MODE_INIT_STEP;
            end else begin
                delay_count = 0;
                init_step = 0;
                nstate = MODE_DONE;
            end 
        end 

        MODE_SETCURSOR: begin
            case(i_data[7:4])
                4'd0: 
                    t_cmd_data = 8'h80 + i_data[3:0];
                4'd1:
                    t_cmd_data = 8'h80 + 8'h40 + i_data[3:0];
                default:
                    t_cmd_data = 8'h80;
            endcase

            if(delay_count >= DELAY_37us) begin
                delay_count = 0;
                nstate = MODE_DONE;
            end 
        end 

        MODE_DATA: begin
            if(delay_count >= DELAY_37us) begin
                nstate = MODE_DONE;
                delay_count = 0;
            end
            else begin
                nstate = MODE_DATA;
            end 

        end  

        MODE_CMD: begin
            case(i_data)
                CMD_CLEAR_DISPLAY, CMD_RETRUN_HOME: begin
                    if(delay_count >= DELAY_1_52ms) begin
                        nstate = MODE_DONE;
                        delay_count = 0;
                    end 
                    else 
                        nstate = MODE_CMD;
                end 
                default: begin
                    if(delay_count >= DELAY_37us) begin
                        delay_count = 0;
                        nstate = MODE_DONE;
                    end 
                    else 
                        nstate = MODE_CMD;
                end 
            endcase
        end 

        MODE_DONE: begin  
            delay_count = 0
            nstate = MODE_IDLE;
        end
        default: begin 
            delay_count = 0;
            init_step   = 0;
            nstate = MODE_IDLE;
        end 
    endcase
end 

assign o_valid = (nstate == MODE_DONE) ? 1 : 0;

always_ff @(posedge i_clk or negedge i_rst_n) begin : proc_func
    if(~i_rst_n) begin
        state       <= MODE_IDLE;
        o_LCD_E     <= 0;
        o_LCD_RW    <= 0;
        o_LCD_RS    <= 0;
        o_LCD_DATA  <= 0;
        o_LCD_ON    <= 1; // bat LCD 
        o_LCD_BLON  <= 0; // tat den nen LCD 
    end else begin
        state       <= nstate;
        case(state)
            MODE_IDLE: begin
                o_LCD_E <= 0;
            end 
            MODE_INIT: begin
                o_LCD_E <= 0; 
            end 
            MODE_INIT_MAINTAIN: begin
                delay_count <= delay_count + 1;
            end 
            MODE_INIT_STEP: begin
                case(init_step)
                    0: begin
                        `WriteCommand(o_LCD_E, o_LCD_RW, o_LCD_RS, o_LCD_DATA, CMD_INIT_LCD)
                        delay_count <= delay_count + 1;
                        if(delay_count >= DELAY_4_1ms) 
                            init_step <= init_step + 1;
                        else 
                            init_step <= init_step;
                    end 
                    1: begin
                        `WriteCommand(o_LCD_E, o_LCD_RW, o_LCD_RS, o_LCD_DATA, CMD_INIT_LCD)
                        delay_count <= delay_count + 1;
                        if(delay_count >= DELAY_100us) begin
                            o_LCD_E   <= 0;
                            init_step <= init_step + 1;
                        end
                        else 
                            init_step <= init_step;
                    end 
                    2: begin
                        `WriteCommand(o_LCD_E, o_LCD_RW, o_LCD_RS, o_LCD_DATA, CMD_INIT_LCD)
                        delay_count <= delay_count + 1;
                        if(delay_count >= DELAY_100us) begin 
                            o_LCD_E   <= 0;
                            init_step <= init_step + 1;
                        end
                        else 
                            init_step <= init_step;
                    end 
                   3: begin
                        `WriteCommand(o_LCD_E, o_LCD_RW, o_LCD_RS, o_LCD_DATA, CMD_INIT_LCD)
                        delay_count <= delay_count + 1;
                        if(delay_count >= DELAY_100us) begin 
                            o_LCD_E   <= 0;
                            init_step <= init_step + 1;
                        end 
                        else 
                            init_step <= init_step;
                    end  
                    4: begin
                        `WriteCommand(o_LCD_E, o_LCD_RW, o_LCD_RS, o_LCD_DATA, CMD_DISPLAY_OFF_CURSOR_OFF)
                        delay_count <= delay_count + 1;
                        if(delay_count >= DELAY_37us) begin 
                            o_LCD_E   <= 0;
                            init_step <= init_step + 1;
                        end 
                        else
                            init_step <= init_step;
                    end 
                    5: begin
                        `WriteCommand(o_LCD_E, o_LCD_RW, o_LCD_RS, o_LCD_DATA, CMD_CLEAR_DISPLAY)
                        delay_count <= delay_count + 1;
                        if(delay_count >= DELAY_1_52ms) begin 
                            o_LCD_E   <= 0;
                            init_step <= init_step + 1;
                        end
                        else
                            init_step <= init_step;
                    end 
                    6: begin
                        `WriteCommand(o_LCD_E, o_LCD_RW, o_LCD_RS, o_LCD_DATA, CMD_EMTRY_INCREASE)
                        delay_count <= delay_count + 1;
                        if(delay_count >= DELAY_37us) begin
                            o_LCD_E   <= 0;
                            init_step <= init_step + 1;
                        end
                        else    
                            init_step <= init_step;
                    end 
                    7: begin
                        `WriteCommand(o_LCD_E, o_LCD_RW, o_LCD_RS, o_LCD_DATA, CMD_DISPLAY_ON_CURSOR_OFF)
                        delay_count <= delay_count + 1;
                        if(delay_count >= DELAY_37us) begin
                            o_LCD_E   <= 0;
                            init_step <= init_step + 1;
                        end 
                        else 
                            init_step <= init_step;
                    end 
                    default: begin
                        o_LCD_E <= 0;
                    end 
                endcase 
            end 
            
            MODE_SETCURSOR: begin
                `WriteCommand(o_LCD_E, o_LCD_RW, o_LCD_RS, o_LCD_DATA, t_cmd_data)
                if(delay_count >= DELAY_37us) 
                    o_LCD_E <= 0;
                else
                    delay_count <= delay_count + 1;
            end 
            MODE_DATA: begin
                `WriteData(o_LCD_E, o_LCD_RW, o_LCD_RS, o_LCD_DATA, i_data)
                if(delay_count >= DELAY_37us)
                    o_LCD_E <= 0;
                else
                    delay_count <= delay_count + 1;
            end 
            MODE_CMD: begin
                `WriteCommand(o_LCD_E, o_LCD_RW, o_LCD_RS, o_LCD_DATA, i_data)
                case(i_data)
                    CMD_CLEAR_DISPLAY, CMD_RETRUN_HOME: begin
                        if(delay_count >= DELAY_1_52ms)
                            o_LCD_E <= 0;
                        else 
                            delay_count <= delay_count + 1;
                    end 
                    default: begin
                        if(delay_count >= DELAY_37us)
                            o_LCD_E <= 0;
                        else 
                            delay_count <= delay_count + 1;
                    end 
                endcase 
            end
            MODE_DONE: begin
                o_LCD_E <= 0;
                o_LCD_RS <= 0;
                o_LCD_RW <= 0;
            end  
            default: begin
                o_LCD_E <= 0;
                o_LCD_RS <= 0;
                o_LCD_RW <= 0;
            end 
        endcase 
    end 
end 
endmodule

