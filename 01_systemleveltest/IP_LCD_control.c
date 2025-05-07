#include <stdio.h>
#include <math.h>
#include <stdlib.h>

#define CMD_CLEAR_DISPLAY    1
#define CMD_RETURN_HOME      2
#define CMD_ENTRY_INCREASE   6 // Tăng địa chỉ, không dịch màn hình
#define CMD_DISPLAY_OFF      8 // Tắt hiển thị
#define CMD_DISPLAY_ON      12 // Bật hiển thị, tắt con trỏ
#define CMD_INIT_LCD        56 // Chế độ 8-bit, 2 dòng, font 5x8
#define CMD_LINE_1          128 
#define CMD_LINE_2          192 

#define CLK_FREQ            50000000
#define DELAY_15ms          CLK_FREQ/1000 * 15 
#define DELAY_4_1ms         CLK_FREQ/1000 * 4.1 
#define DELAY_100us         CLK_FREQ/10000 
#define DELAY_1_52ms        CLK_FREQ/1000 * 1.52
#define DELAY_37us          CLK_FREQ/100000 * 37

int delay_count = 0;

typedef enum{
    FUNC_INIT       = 0,
    FUNC_SETCURSOR  = 1,
    FUNC_DATA       = 2,
    FUNC_CMD        = 3
} MODE_t; 
MODE_t i_func;

typedef enum{
    MODE_IDLE,
    MODE_INIT,
    MODE_INIT_WAIT,
    MODE_INIT_STEP,
    MODE_CMD,
    MODE_CMD_WAIT,
    MODE_DATA,
    MODE_DATA_WAIT,
    MODE_SETSURSOR,
    MODE_SETCURSOR_WAIT,
    MODE_DONE
} STATE_t;
STATE_t state, nstate;
int init_step = 0;


// Global variable
int i_dat;
int o_LCD_DATA, o_LCD_RW, o_LCD_RS, o_LCD_E, o_LCD_ON, o_LCD_BLON, o_valid;

int main(void){
    
     

    return 0;
}

