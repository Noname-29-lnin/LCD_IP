# Định nghĩa trình biên dịch
CC = gcc

# Các cờ biên dịch
CFLAGS = -Wall -Wextra -O2

# Tên chương trình
TARGET = IP_LCD_control

# Các file nguồn
SRCS = IP_LCD_control.c

# Các file object
OBJS = $(SRCS:.c=.o)

# Lệnh mặc định
all: clean compile run

# Biên dịch chương trình
compile: $(OBJS)
        @echo "-> Compile"
        @$(CC) $(CFLAGS) -o $(TARGET) $(OBJS) -lm

# Biên dịch từng file nguồn thành file object
%.o: %.c
        @$(CC) $(CFLAGS) -c $< -o $@

# Chạy chương trình
run:
        @echo "-> Run"
        @./$(TARGET)

# Xóa các file object và chương trình đã biên dịch
clean:
        @echo "-> Clean"
        @rm -f $(OBJS) $(TARGET)

# Phony targets để chỉ ra rằng các lệnh này không tạo ra file cùng tên
.PHONY: all compile run clean