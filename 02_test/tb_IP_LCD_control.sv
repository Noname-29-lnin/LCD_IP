`timescale 1ps / 1ps

module tb_IP_LCD_control;
    // Định nghĩa tín hiệu
    logic                   clk;
    logic                   rst_n;
    logic [7:0]             i_data;
    logic [2:0]             i_func;
    logic [7:0]             o_LCD_DATA;
    logic                   o_LCD_RW;
    logic                   o_LCD_RS;
    logic                   o_LCD_E;
    logic                   o_LCD_ON;
    logic                   o_LCD_BLON;
    logic                   o_valid;

    // Khởi tạo module
    IP_LCD_control #(
        .CLK_FREQ(50_000_000)
    ) uut (
        .i_clk(clk),
        .i_rst_n(rst_n),
        .i_data(i_data),
        .i_func(i_func),
        .o_LCD_DATA(o_LCD_DATA),
        .o_LCD_RW(o_LCD_RW),
        .o_LCD_RS(o_LCD_RS),
        .o_LCD_E(o_LCD_E),
        .o_LCD_ON(o_LCD_ON),
        .o_LCD_BLON(o_LCD_BLON),
        .o_valid(o_valid)
    );

    // Tạo clock 50 MHz (chu kỳ 20ns)
    always #10 clk = ~clk;
    
    // // Kịch bản kiểm tra
    // initial begin
    //     // Khởi tạo
    //     rst_n = 0;
    //     i_data = 8'h00;
    //     i_func = 2'h0;
    //     #100;
    //     rst_n = 1;

    //     // Kiểm tra khởi tạo LCD
    //     i_func = 2'h0; // FUNC_INIT
    //     #100_000_000; // Chờ 100ms

    //     // Đặt con trỏ (dòng 1, vị trí 0)
    //     i_func = 2'h1; // FUNC_SETCURSOR
    //     i_data = 8'h00;
    //     #100_000;

    //     // Ghi dữ liệu
    //     i_func = 2'h2; // FUNC_DATA
    //     i_data = 8'h41; // Ký tự 'A'
    //     #100_000;

    //     // Ghi lệnh xóa màn hình
    //     i_func = 2'h3; // FUNC_CMD
    //     i_data = 8'h01; // CMD_CLEAR_DISPLAY
    //     #10_000_000;

    //     $finish;
    // end

    // Theo dõi tín hiệu
    initial begin
        $dumpfile("tb_IP_LCD_control.vcd");
        $dumpvars(0, tb_IP_LCD_control);
    end
    // initial begin
    //     @(posedge clk);
    //     $display("At clock edge: state = %h, nstate = %h", uut.state, uut.nstate);
    //     @(posedge clk);
    //     $display("In always_comb: state = %h, nstate = %h", uut.state, uut.nstate);
    // end

    initial begin
        $display("Reset LCD");
        rst_n = 0;
        i_data = 8'h29;
        i_func = 3'h1;
        #100;
        $display("Time=%t, i_data=%h, o_LCD_data=%h, o_valid=%b", $time, i_data, o_LCD_DATA, o_valid);
        $display("E=%b, RS=%b, RW=%b", o_LCD_E, o_LCD_RS, o_LCD_RW);
        
        rst_n = 1;
        #100;


        $display("------------------------------- Test Case 1 -------------------------------");
        $display("Test function initial LCD");        
        @(posedge clk);
        i_data = 8'h29;
        i_func = 3'h1; // FUNC_INIT
        
        // $display("Time=%t, i_data=%h, i_func=%h, o_LCD_DATA=%h, o_valid=%b", $time, i_data, i_func, o_LCD_DATA, o_valid);
        // $display("E=%b, RS=%b, RW=%b", o_LCD_E, o_LCD_RS, o_LCD_RW);
        $display("Test initial LCD");
        $display("Time=%t, i_data=%h, i_func=%h", $time, i_data, i_func);
        wait(o_valid);
        #20;
        $display("o_LCD_DATA=%h, o_valid=%b", o_LCD_DATA, o_valid);
        $display("E=%b, RS=%b, RW=%b", o_LCD_E, o_LCD_RS, o_LCD_RW);

        #100;
        $display("------------------------------- Test Case 2 -------------------------------");
        @(posedge clk);
        i_data = 8'h00;
        i_func = 3'h2; // FUNC_SETCURSOR

        $display("Test setcursor (0, 0)");
        $display("Time=%t, i_data=%h, i_func=%h", $time, i_data, i_func);
        wait(o_valid);
        #20;
        $display("o_LCD_DATA=%h, o_valid=%b", o_LCD_DATA, o_valid);
        $display("E=%b, RS=%b, RW=%b", o_LCD_E, o_LCD_RS, o_LCD_RW);

        #100;
        @(posedge clk);
        i_data = 8'h05;
        i_func = 3'h2; // FUNC_SETCURSOR

        $display("Test setcursor (0, 5)");
        $display("Time=%t, i_data=%h, i_func=%h", $time, i_data, i_func);
        wait(o_valid);
        #20;
        $display("o_LCD_DATA=%h, o_valid=%b", o_LCD_DATA, o_valid);
        $display("E=%b, RS=%b, RW=%b", o_LCD_E, o_LCD_RS, o_LCD_RW);
        
        #100;
        @(posedge clk);
        i_data = 8'h10;
        i_func = 3'h2; // FUNC_SETCURSOR

        $display("Test setcursor (1, 0)");
        $display("Time=%t, i_data=%h, i_func=%h", $time, i_data, i_func);
        wait(o_valid);
        #20;
        $display("o_LCD_DATA=%h, o_valid=%b", o_LCD_DATA, o_valid);
        $display("E=%b, RS=%b, RW=%b", o_LCD_E, o_LCD_RS, o_LCD_RW);
        
        #100;
        @(posedge clk);
        i_data = 8'h15;
        i_func = 3'h2; // FUNC_SETCURSOR

        $display("Test setcursor (1, 5)");
        $display("Time=%t, i_data=%h, i_func=%h", $time, i_data, i_func);
        wait(o_valid);
        #20;
        $display("o_LCD_DATA=%h, o_valid=%b", o_LCD_DATA, o_valid);
        $display("E=%b, RS=%b, RW=%b", o_LCD_E, o_LCD_RS, o_LCD_RW);

        $display("------------------------------- Test Case 3 -------------------------------");

        #100;
        @(posedge clk);
        i_data = 8'h29;
        i_func = 3'h3; // FUNC_DATA

        $display("Test send Data = 0x29");
        $display("Time=%t, i_data=%h, i_func=%h", $time, i_data, i_func);
        wait(o_valid);
        #20;
        $display("o_LCD_DATA=%h, o_valid=%b", o_LCD_DATA, o_valid);
        $display("E=%b, RS=%b, RW=%b", o_LCD_E, o_LCD_RS, o_LCD_RW);

        #100;
        @(posedge clk);
        i_data = 8'h30;
        i_func = 3'h3; // FUNC_DATA

        $display("Test send Data = 0x30");
        $display("Time=%t, i_data=%h, i_func=%h", $time, i_data, i_func);
        wait(o_valid);
        #20;
        $display("o_LCD_DATA=%h, o_valid=%b", o_LCD_DATA, o_valid);
        $display("E=%b, RS=%b, RW=%b", o_LCD_E, o_LCD_RS, o_LCD_RW);

        $display("------------------------------- Test Case 4 -------------------------------");

        #100;
        @(posedge clk);
        i_data = 8'h01;
        i_func = 3'h4; // FUNC_DATA

        $display("Test send command = 0x01 (Clear display)");
        $display("Time=%t, i_data=%h, i_func=%h", $time, i_data, i_func);
        wait(o_valid);
        #20;
        $display("o_LCD_DATA=%h, o_valid=%b", o_LCD_DATA, o_valid);
        $display("E=%b, RS=%b, RW=%b", o_LCD_E, o_LCD_RS, o_LCD_RW);

        #100;
        @(posedge clk);
        i_data = 8'h06;
        i_func = 3'h4; // FUNC_DATA

        $display("Test send command = 0x06 (Entry mode set)");
        $display("Time=%t, i_data=%h, i_func=%h", $time, i_data, i_func);
        wait(o_valid);
        #20;
        $display("o_LCD_DATA=%h, o_valid=%b", o_LCD_DATA, o_valid);
        $display("E=%b, RS=%b, RW=%b", o_LCD_E, o_LCD_RS, o_LCD_RW);
        
        #10000;
        $display("Finish Simulation");
        $finish;
    end
endmodule

// `timescale 1ps / 1ps

// module tb_IP_LCD_control;
//     // Định nghĩa tín hiệu
//     logic                   clk;
//     logic                   rst_n;
//     logic [7:0]             i_data;
//     logic [1:0]             i_func; // Sửa từ [2:0] thành [1:0] để khớp với module
//     logic [7:0]             o_LCD_DATA;
//     logic                   o_LCD_RW;
//     logic                   o_LCD_RS;
//     logic                   o_LCD_E;
//     logic                   o_LCD_ON;
//     logic                   o_LCD_BLON;
//     logic                   o_valid;

//     // Khởi tạo module
//     IP_LCD_control #(
//         .CLK_FREQ(50_000_000)
//     ) uut (
//         .i_clk(clk),
//         .i_rst_n(rst_n),
//         .i_data(i_data),
//         .i_func(i_func),
//         .o_LCD_DATA(o_LCD_DATA),
//         .o_LCD_RW(o_LCD_RW),
//         .o_LCD_RS(o_LCD_RS),
//         .o_LCD_E(o_LCD_E),
//         .o_LCD_ON(o_LCD_ON),
//         .o_LCD_BLON(o_LCD_BLON),
//         .o_valid(o_valid)
//     );

//     // Tạo clock 50 MHz (chu kỳ 20ns = 20_000ps)
//     // initial begin
//     //     clk = 0;
//     //     forever #10_000 clk = ~clk;
//     // end

//     always #10 clk = ~clk;
//     // Hàm hỗ trợ để hiển thị trạng thái
//     task display_status(input string test_name);
//         @(posedge clk); // Chờ 1 chu kỳ clock sau khi o_valid bật lên
//         $display("Test: %s", test_name);
//         $display("Time=%0t ps, i_data=%h, i_func=%h, o_LCD_DATA=%h, o_valid=%b", $time, i_data, i_func, o_LCD_DATA, o_valid);
//         $display("E=%b, RS=%b, RW=%b, state=%h, init_step=%0d", o_LCD_E, o_LCD_RS, o_LCD_RW, uut.state, uut.init_step);
//         $display("-----------------------------------");
//     endtask

//     // Kịch bản kiểm tra
//     initial begin
//         // Khởi tạo
//         $display("Starting Simulation");
//         rst_n = 0;
//         i_data = 8'h00;
//         i_func = 2'h0;
//         #100_000; // Chờ 100ns
//         rst_n = 1;
//         #100_000; // Chờ thêm để đảm bảo reset hoàn tất
//         $display("Reset completed");

//         // Test Case 1: Kiểm tra khởi tạo LCD
//         $display("Test Case 1: LCD Initialization");
//         i_func = 2'h0; // FUNC_INIT
//         i_data = 8'h00; // Không cần i_data trong init
//         wait(o_valid);
//         display_status("LCD Init Complete");
//         #100_000; // Chờ thêm để đảm bảo init hoàn tất

//         // Test Case 2: Đặt con trỏ (các vị trí hợp lệ)
//         $display("Test Case 2: Set Cursor Positions");
//         // Dòng 1, vị trí 0
//         i_func = 2'h1; // FUNC_SETCURSOR
//         i_data = 8'h00; // Dòng 1, vị trí 0
//         wait(o_valid);
//         display_status("Set Cursor (Line 1, Pos 0)");
//         // #100_000; // Chờ 100ns
        
//         // Dòng 1, vị trí 5
//         @(posedge clk);
//         i_data = 8'h05; // Dòng 1, vị trí 5
//         i_func = 2'h1;
//         wait(o_valid);
//         display_status("Set Cursor (Line 1, Pos 5)");
//         // #100_000; // Chờ 100ns
        
//         // Dòng 2, vị trí 0
//         @(posedge clk);
//         i_data = 8'h10; // Dòng 2, vị trí 0
//         i_func = 2'h1;
//         wait(o_valid);
//         display_status("Set Cursor (Line 2, Pos 0)");
//         // #100_000; // Chờ 100ns
        
//         // Dòng 2, vị trí 5
//         @(posedge clk);
//         i_data = 8'h15; // Dòng 2, vị trí 5
//         i_func = 2'h1;
//         wait(o_valid);
//         display_status("Set Cursor (Line 2, Pos 5)");
//         #100_000;

//         // Test Case 3: Ghi dữ liệu
//         $display("Test Case 3: Write Data");
//         // Ghi ký tự 'A'
//         @(posedge clk);
//         i_func = 2'h2; // FUNC_DATA
//         i_data = 8'h41; // Ký tự 'A'
//         wait(o_valid);
//         display_status("Write Data 'A'");
//         // #100_000; // Chờ 100ns
        
//         // Ghi ký tự 'B'
//         @(posedge clk);
//         i_data = 8'h42; // Ký tự 'B'
//         i_func = 2'h2;
//         wait(o_valid);
//         display_status("Write Data 'B'");
//         #100_000;

//         // Test Case 4: Ghi lệnh
//         $display("Test Case 4: Send Commands");
//         // Lệnh xóa màn hình
//         @(posedge clk);
//         i_func = 2'h3; // FUNC_CMD
//         i_data = 8'h01; // CMD_CLEAR_DISPLAY
//         wait(o_valid);
//         display_status("Clear Display");
        
//         // Lệnh đưa con trỏ về đầu
//         @(posedge clk);
//         i_data = 8'h02; // CMD_RETURN_HOME
//         i_func = 2'h3;
//         wait(o_valid);
//         display_status("Return Home");
//         #1_000_000;

//         // Test Case 5: Kiểm tra trường hợp biên - i_data không hợp lệ
//         $display("Test Case 5: Invalid Cursor Position");
//         @(posedge clk);
//         i_func = 2'h1; // FUNC_SETCURSOR
//         i_data = 8'h2F; // Dòng không hợp lệ (2)
//         wait(o_valid);
//         display_status("Invalid Cursor (Line 2, Pos 15)");
//         #100_000;

//         // Test Case 6: Kiểm tra timing - thay đổi i_func ngay khi o_valid
//         $display("Test Case 6: Timing Stress Test");
//         @(posedge clk);
//         i_func = 2'h1;
//         i_data = 8'h00;
//         wait(o_valid);
//         @(posedge clk);
//         i_func = 2'h2; // Thay đổi ngay sau o_valid
//         i_data = 8'h43; // Ký tự 'C'
//         wait(o_valid);
//         display_status("Write Data 'C' after Cursor Set");
//         #100_000;

//         // Test Case 7: Kiểm tra reset trong khi đang xử lý
//         $display("Test Case 7: Reset During Operation");
//         @(posedge clk);
//         i_func = 2'h3;
//         i_data = 8'h01; // CMD_CLEAR_DISPLAY
//         #500_000; // Reset giữa chừng
//         rst_n = 0;
//         #100_000;
//         rst_n = 1;
//         $display("Reset triggered, checking state");
//         #100_000;
//         display_status("Post-Reset State");
//         #100_000;

//         // Kết thúc mô phỏng
//         $display("Simulation Completed");
//         $finish;
//     end

//     // Theo dõi tín hiệu
//     initial begin
//         $dumpfile("tb_IP_LCD_control.vcd");
//         $dumpvars(0, tb_IP_LCD_control);
//     end
// endmodule