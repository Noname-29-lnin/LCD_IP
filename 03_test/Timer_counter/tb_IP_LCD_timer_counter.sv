// `timescale 1ps/1ps

// module tb_IP_LCD_timer_counter();

// parameter SIZE_DATA = 8;
// parameter SIZE_FUNC = 4;
// parameter CLK_PERIOD = 20;  // 50 MHz clock

// logic i_clk, i_rst_n, i_en_lcd, i_lcd_blon, o_LCD_ON, o_LCD_BLON;
// logic [SIZE_DATA-1:0] i_data, o_LCD_DATA;
// logic [SIZE_FUNC-1:0] i_func;
// logic o_LCD_E, o_LCD_RS, o_LCD_RW, o_done_lcd;

// // Instantiate the DUT
// IP_LCD_timer_counter #(
//     .SIZE_DATA      (SIZE_DATA),
//     .SIZE_FUNC      (SIZE_FUNC),
//     .FREQ           (50000)
// ) uut (
//     .i_clk          (i_clk      ),
//     .i_rst_n        (i_rst_n    ),
//     .i_en_lcd       (i_en_lcd   ),
//     .i_lcd_blon     (i_lcd_blon ),
//     .i_data         (i_data     ),
//     .i_func         (i_func     ),

//     .o_LCD_DATA     (o_LCD_DATA ),
//     .o_LCD_E        (o_LCD_E    ),
//     .o_LCD_RW       (o_LCD_RW   ),
//     .o_LCD_RS       (o_LCD_RS   ),
//     .o_LCD_ON       (o_LCD_ON   ),
//     .o_LCD_BLON     (o_LCD_BLON ),
//     .o_done_lcd     (o_done_lcd ) 
// );

// // Clock generator
// initial i_clk = 0;
// always #(CLK_PERIOD/2) i_clk = ~i_clk;

// // Dump file
// initial begin
//     $dumpfile("tb_IP_LCD_timer_counter.vcd");
//     $dumpvars(0, tb_IP_LCD_timer_counter);
// end

// // Display task
// task display_status;
//     input string test_name;
//     begin
//         $display("[%0t] TEST: %s", $time, test_name);
//         $display("  Inputs: func=%0d, data=%h, en_lcd=%b, blon=%b",
//                  i_func, i_data, i_en_lcd, i_lcd_blon);
//         $display("  Outputs: LCD_DATA=%h, E=%b, RW=%b, RS=%b, ON=%b, BLON=%b, done=%b",
//                  o_LCD_DATA, o_LCD_E, o_LCD_RW, o_LCD_RS, o_LCD_ON, o_LCD_BLON, o_done_lcd);
//     end
// endtask

// // Wait for operation completion
// task wait_for_done;
//     begin
//         @(posedge o_done_lcd);
//         #(CLK_PERIOD*2);
//     end
// endtask

// // Test initialization sequence
// task test_init;
//     begin
//         $display("\n\n=== TESTING INITIALIZATION SEQUENCE ===");
//         i_func = 0;  // FUNC_INIT
//         i_en_lcd = 1;
//         i_lcd_blon = 1;
//         @(negedge i_clk);
        
//         // Check each step of initialization
//         repeat(9) begin
//             wait_for_done();
//             display_status("Init Sequence Step");
//         end
        
//         // Verify LCD is enabled
//         if (o_LCD_ON !== 1'b1 || o_LCD_BLON !== 1'b1) begin
//             $display("ERROR: LCD not enabled after initialization");
//             $finish;
//         end
//     end
// endtask

// // Test cursor positioning
// task test_cursor;
//     input [7:0] position;
//     begin
//         $display("\n\n=== TESTING CURSOR POSITIONING: %h ===", position);
//         i_func = 1;  // FUNC_SETCURSOR
//         i_data = position;
//         @(negedge i_clk);
//         wait_for_done();
//         display_status("Set Cursor");
        
//         // Verify correct address was set
//         if (position[7:4] == 4'h0) begin
//             if (o_LCD_DATA !== (8'h80 | position[3:0])) begin
//                 $display("ERROR: Line 1 position mismatch. Expected: %h, Got: %h",
//                          8'h80 | position[3:0], o_LCD_DATA);
//                 $finish;
//             end
//         end
//         else if (position[7:4] == 4'h1) begin
//             if (o_LCD_DATA !== (8'hC0 | position[3:0])) begin
//                 $display("ERROR: Line 2 position mismatch. Expected: %h, Got: %h",
//                          8'hC0 | position[3:0], o_LCD_DATA);
//                 $finish;
//             end
//         end
//     end
// endtask

// // Test LCD commands
// task test_command;
//     input [7:0] cmd;
//     input string cmd_name;
//     begin
//         $display("\n\n=== TESTING COMMAND: %s (%h) ===", cmd_name, cmd);
//         i_func = 2;  // FUNC_CMD
//         i_data = cmd;
//         @(negedge i_clk);
//         wait_for_done();
//         display_status(cmd_name);
        
//         // Verify command was sent correctly
//         if (o_LCD_DATA !== cmd || o_LCD_RS !== 1'b0) begin
//             $display("ERROR: Command not sent correctly");
//             $finish;
//         end
//     end
// endtask

// // Test data writing
// task test_data;
//     input [7:0] data;
//     begin
//         $display("\n\n=== TESTING DATA WRITE: %h (%c) ===", data, data);
//         i_func = 3;  // FUNC_DATA
//         i_data = data;
//         @(negedge i_clk);
//         wait_for_done();
//         display_status("Write Data");
        
//         // Verify data was sent correctly
//         if (o_LCD_DATA !== data || o_LCD_RS !== 1'b1) begin
//             $display("ERROR: Data not sent correctly");
//             $finish;
//         end
//     end
// endtask

// // Test backlight and enable control
// task test_control_signals;
//     begin
//         $display("\n\n=== TESTING CONTROL SIGNALS ===");
        
//         // Disable LCD
//         i_en_lcd = 0;
//         i_lcd_blon = 0;
//         #100;
//         if (o_LCD_ON !== 1'b0 || o_LCD_BLON !== 1'b0) begin
//             $display("ERROR: LCD should be disabled");
//             $finish;
//         end
        
//         // Re-enable LCD
//         i_en_lcd = 1;
//         i_lcd_blon = 1;
//         #100;
//         if (o_LCD_ON !== 1'b1 || o_LCD_BLON !== 1'b1) begin
//             $display("ERROR: LCD should be enabled");
//             $finish;
//         end
//     end
// endtask

// // Main test sequence
// initial begin
//     // Initialize inputs
//     i_rst_n = 0;
//     i_en_lcd = 0;
//     i_lcd_blon = 0;
//     i_func = 0;
//     i_data = 0;
    
//     // Apply reset
//     #100;
//     i_rst_n = 1;
//     #100;
    
//     // Test 1: Initialization sequence
//     test_init();
    
//     // Test 2: Control signals
//     test_control_signals();
    
//     // Test 3: Cursor positioning
//     test_cursor(8'h00);  // Line 1, position 0
//     // test_cursor(8'h0F);  // Line 1, position 15
//     // test_cursor(8'h10);  // Line 2, position 0
//     // test_cursor(8'h1F);  // Line 2, position 15
    
//     // Test 4: LCD commands
//     test_command(8'h01, "Clear Display");
//     // test_command(8'h02, "Return Home");
//     // test_command(8'h06, "Entry Mode Set");
//     test_command(8'h08, "Display Off");
//     // test_command(8'h0C, "Display On");
//     // test_command(8'h38, "Function Set");
    
//     // Test 5: Data writing
//     test_data(8'h41);  // 'A'
//     // test_data(8'h42);  // 'B'
//     // test_data(8'h43);  // 'C'
//     // test_data(8'h31);  // '1'
//     // test_data(8'h32);  // '2'
//     // test_data(8'h33);  // '3'
    
//     // Test 6: Mixed sequence
//     $display("\n\n=== TESTING MIXED SEQUENCE ===");
//     test_command(8'h01, "Clear Display");
//     test_cursor(8'h00);   // Line 1, position 0
//     test_data("H");
//     // test_data("e");
//     // test_data("l");
//     // test_data("l");
//     // test_data("o");
//     // test_cursor(8'h40);   // Line 2, position 0 (8'h40 = 8'hC0?)
//     // test_data("W");
//     // test_data("o");
//     // test_data("r");
//     // test_data("l");
//     // test_data("d");
//     // test_data("!");
    
//     // Test 7: Invalid function code
//     $display("\n\n=== TESTING INVALID FUNCTION ===");
//     i_func = 4;  // Invalid function code
//     @(negedge i_clk);
//     #100;
//     if (o_done_lcd !== 1'b0) begin
//         $display("ERROR: Should not complete for invalid function");
//         $finish;
//     end
    
//     // All tests passed
//     $display("\n\n====================================");
//     $display("ALL TESTS PASSED SUCCESSFULLY!");
//     $display("====================================");
//     $finish;
// end

// endmodule

`timescale 1ps/1ps
module tb_IP_LCD_timer_counter();

parameter SIZE_DATA = 8;
parameter SIZE_FUNC = 4;
parameter CLK_PERIOD = 20;  // 50 MHz clock

logic i_clk, i_rst_n, i_en_lcd, i_on_lcd, i_lcd_blon;
logic o_LCD_E, o_LCD_RW, o_LCD_RS, o_LCD_ON, o_LCD_BLON, o_done_lcd;
logic [SIZE_DATA-1:0] i_data, o_LCD_DATA;
logic [SIZE_FUNC-1:0] i_func;
IP_LCD_timer_counter #(
    .SIZE_DATA      (8) ,
    .SIZE_FUNC      (4) ,
    .FREQ           (50_000_000)
) uut (
    .i_clk          (i_clk),
    .i_rst_n        (i_rst_n),
    .i_en_lcd       (i_en_lcd), 
    .i_on_lcd       (i_on_lcd),
    .i_lcd_blon     (i_lcd_blon),
    .i_data         (i_data),
    .i_func         (i_func),

    .o_LCD_DATA     (o_LCD_DATA),
    .o_LCD_E        (o_LCD_E),
    .o_LCD_RW       (o_LCD_RW),
    .o_LCD_RS       (o_LCD_RS),
    .o_LCD_ON       (o_LCD_ON),
    .o_LCD_BLON     (o_LCD_BLON),
    .o_done_lcd     (o_done_lcd)
);

initial i_clk = 0;
always #(CLK_PERIOD/2) i_clk = ~i_clk;

initial begin
    $dumpfile("tb_IP_LCD_timer_counter.vcd");
    $dumpvars(0, tb_IP_LCD_timer_counter);
end

task display_testcase;
    input string testcase;
    begin
        $display("=========== Testcase: %s ===========", testcase);
    end
endtask 
task display_input;
    begin
        $display("| Time = %t \t| i_rst_n = %b \t| i_on_lcd = %b \t| i_lcd_blon = %b \t|", 
                    $time, i_rst_n, i_on_lcd, i_lcd_blon);
        $display("| Time = %t \t| i_en_lcd = %b \t| i_fun = %h \t| i_data = %h \t|", 
                    $time, i_en_lcd, i_func, i_data);
    end
endtask
task display_output;
    begin
        $display("| Time = %t \t| o_LCD_RW = %b \t| o_LCD_RS = %b \t| o_LCD_E = %b \t|", 
                    $time, o_LCD_RW, o_LCD_RS, o_LCD_E);
        $display("| Time = %t \t| o_LCD_DATA = %h \t| o_done_lcd = %b \t|", 
                    $time, o_LCD_DATA, o_done_lcd);
    end
endtask 
task wait_for_done;
    begin
        @(posedge o_done_lcd);
        #1;
    end
endtask
task wait_for_end;
    begin
        // @(negedge o_done_lcd);
        #20;
    end
endtask
task check_init;
    begin
        display_testcase("Init");
        @(posedge i_clk);
        i_func = 0;
        i_en_lcd = 1;
        i_data = 0;
        display_input();
        wait_for_done();
        display_output();
        wait_for_end();
        i_en_lcd = 0;
        if (o_LCD_ON !== 1'b1 || o_LCD_BLON !== 1'b1) begin
            $display("ERROR: LCD not enabled after initialization");
        end
        
    end
endtask
task check_cursor;
    input [7:0] cursor_data;
    begin
        display_testcase("Setcursor");
        @(posedge i_clk);
        i_func = 1;
        i_en_lcd = 1;
        i_data = cursor_data;
        display_input();
        wait_for_done();
        display_output();
        wait_for_end();
        i_en_lcd = 0;
        if (o_LCD_ON !== 1'b1 || o_LCD_BLON !== 1'b1) begin
            $display("ERROR: LCD not enabled after initialization");
        end
    end
endtask
task check_cmd;
    input [7:0] cmd_data;
    begin
        display_testcase("Command");
        @(posedge i_clk);
        i_func = 2;
        i_en_lcd = 1;
        i_data = cmd_data;
        display_input();
        wait_for_done();
        display_output();
        wait_for_end();
        i_en_lcd = 0;
        if (o_LCD_ON !== 1'b1 || o_LCD_BLON !== 1'b1) begin
            $display("ERROR: LCD not enabled after initialization");
        end
    end
endtask
task check_date;
    input [7:0] data_data;
    begin
        display_testcase("Command");
        @(posedge i_clk);
        i_func = 3;
        i_en_lcd = 1;
        i_data = data_data;
        display_input();
        wait_for_done();
        display_output();
        wait_for_end();
        i_en_lcd = 0;
        if (o_LCD_ON !== 1'b1 || o_LCD_BLON !== 1'b1) begin
            $display("ERROR: LCD not enabled after initialization");
        end
    end
endtask
task check_control_signal;
    begin
        display_testcase("Control Signal");
        i_on_lcd = 0;
        i_lcd_blon = 0;
        #(CLK_PERIOD*10);
        if (o_LCD_ON !== 1'b0 || o_LCD_BLON !== 1'b0) begin
            $display("ERROR: LCD should be disabled");
        end
        display_output();
        #(CLK_PERIOD*10);
        i_on_lcd = 1;
        i_lcd_blon = 1;
        #(CLK_PERIOD*10);
        if (o_LCD_ON !== 1'b0 || o_LCD_BLON !== 1'b0) begin
            $display("ERROR: LCD should be disabled");
        end
        display_output();
    end
endtask

initial begin
    i_rst_n = 0;
    i_en_lcd = 0;
    i_on_lcd = 0;
    i_lcd_blon = 0;
    i_func = 0;
    i_data = 0;
    #100;
    i_rst_n = 1;
    check_control_signal();

    #100;
    check_init();

    #100;
    check_cursor(8'h00);
    #20;
    check_cursor(8'h05);
    #20;
    check_cursor(8'h10);
    #20;
    check_cursor(8'h15);

    #100;
    check_cmd(8'h01);
    #20;
    check_cmd(8'h02);
    #20;
    check_cmd(8'h06);

    #100;
    check_date(8'h29);
    #20;
    check_date(8'h30);

    #1000;
    $display("Finish test");
    $finish;
end

endmodule
