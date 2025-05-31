#include "VIP_LCD_timer_counter.h"
#include "verilated.h"
#include "verilated_vcd_c.h"
#include <iostream>
#include <iomanip>
#include <cstdlib>

// Constants
#define CLK_PERIOD 20
#define RESET_TIME 100
#define LCD_FUNC_INIT      0
#define LCD_FUNC_SETCURSOR 1
#define LCD_FUNC_CMD       2
#define LCD_FUNC_DATA      3
#define MAX_WAIT_CYCLES 1000000 // Timeout after 1 million cycles

vluint64_t main_time = 0; // Current simulation time

double sc_time_stamp() {
    return main_time;
}

class LCDTest {
public:
    VIP_LCD_timer_counter* top;
    VerilatedVcdC* tfp;
    vluint64_t& main_time;
    
    LCDTest(VIP_LCD_timer_counter* top, VerilatedVcdC* tfp, vluint64_t& main_time) 
        : top(top), tfp(tfp), main_time(main_time) {}
    
    void reset() {
        top->i_rst_n = 0;
        run_cycles(RESET_TIME/CLK_PERIOD);
        top->i_rst_n = 1;
        run_cycles(5);
    }
    
    void run_cycles(int cycles) {
        for (int i = 0; i < cycles; i++) {
            tick();
        }
    }
    
    void tick() {
        top->i_clk = 0;
        top->eval();
        if (tfp) tfp->dump(main_time);
        main_time += CLK_PERIOD/2;
        
        top->i_clk = 1;
        top->eval();
        if (tfp) tfp->dump(main_time);
        main_time += CLK_PERIOD/2;
    }
    
    bool wait_for_done(int max_cycles = MAX_WAIT_CYCLES) {
        int cycles = 0;
        while (!top->o_done_lcd && cycles < max_cycles) {
            tick();
            cycles++;
        }
        
        if (cycles >= max_cycles) {
            std::cerr << "TIMEOUT: wait_for_done exceeded " << max_cycles << " cycles" << std::endl;
            return false;
        }
        
        // Wait a few extra cycles after done
        run_cycles(2);
        return true;
    }
    
    void test_init() {
        std::cout << "=== TESTING INITIALIZATION SEQUENCE ===" << std::endl;
        top->i_func = LCD_FUNC_INIT;
        top->i_en_lcd = 1;
        top->i_lcd_blon = 1;
        tick();  // Capture input
        
        // Should take about 9 steps
        for (int i = 0; i < 9; i++) {
            std::cout << "Init step " << i << std::endl;
            if (!wait_for_done()) {
                std::cerr << "ERROR: Init sequence failed at step " << i << std::endl;
                exit(1);
            }
            print_status("Init Step");
        }
        
        // Verify LCD is enabled
        if (top->o_LCD_ON != 1 || top->o_LCD_BLON != 1) {
            std::cerr << "ERROR: LCD not enabled after initialization" << std::endl;
            exit(1);
        }
    }
    
    // ... (các hàm test khác giữ nguyên) ...
    
    void print_status(const std::string& test_name) {
        std::cout << "[" << std::dec << main_time << "] " << test_name << "\n"
                  << "  Inputs: func=0x" << std::hex << static_cast<int>(top->i_func)
                  << " data=0x" << static_cast<int>(top->i_data)
                  << " en_lcd=" << static_cast<int>(top->i_en_lcd)
                  << " blon=" << static_cast<int>(top->i_lcd_blon) << "\n"
                  << "  Outputs: LCD_DATA=0x" << static_cast<int>(top->o_LCD_DATA)
                  << " E=" << static_cast<int>(top->o_LCD_E)
                  << " RW=" << static_cast<int>(top->o_LCD_RW)
                  << " RS=" << static_cast<int>(top->o_LCD_RS)
                  << " ON=" << static_cast<int>(top->o_LCD_ON)
                  << " BLON=" << static_cast<int>(top->o_LCD_BLON)
                  << " done=" << static_cast<int>(top->o_done_lcd) << "\n"
                  << std::endl;
    }
};

int main(int argc, char** argv) {
    Verilated::commandArgs(argc, argv);
    Verilated::debug(1); // Bật debug
    VIP_LCD_timer_counter* top = new VIP_LCD_timer_counter;
    
    // Initialize VCD trace
    Verilated::traceEverOn(true);
    VerilatedVcdC* tfp = new VerilatedVcdC;
    top->trace(tfp, 99);
    tfp->open("waveform.vcd");
    
    // Create test environment
    LCDTest test(top, tfp, main_time);
    
    // Initialize inputs
    top->i_clk = 0;
    top->i_rst_n = 0;
    top->i_en_lcd = 0;
    top->i_lcd_blon = 0;
    top->i_data = 0;
    top->i_func = 0;
    
    // Apply reset
    test.reset();
    
    std::cout << "Reset complete, starting tests..." << std::endl;
    
    try {
        // Run tests
        test.test_init();
        
        // ... (các test khác) ...
        
        std::cout << "\n\n====================================" << std::endl;
        std::cout << "ALL TESTS PASSED SUCCESSFULLY!" << std::endl;
        std::cout << "====================================" << std::endl;
    }
    catch (const std::exception& e) {
        std::cerr << "\nERROR: " << e.what() << std::endl;
        std::cerr << "TESTS FAILED!" << std::endl;
    }
    
    // Cleanup
    tfp->close();
    delete top;
    delete tfp;
    
    return 0;
}