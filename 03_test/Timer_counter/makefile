# Configuration
TOPMODULE := IP_LCD_timer_counter
CPP_TESTBENCH := tb_IP_LCD_timer_counter.cpp
VERILATOR_FLAGS := --cc --exe --build --timing --trace
WARNING_IGNORE := -Wno-fatal -Wno-lint -Wno-style -Wno-width
VERILOG_SOURCES := ../../02_rtl/IP_LCD_timer_counter.sv

# Targets
all: clean compile run

compile:
	@echo "-> Compiling design with Verilator..."
	@verilator $(VERILATOR_FLAGS) $(WARNING_IGNORE) \
		--top-module $(TOPMODULE) \
		$(VERILOG_SOURCES) \
		$(CPP_TESTBENCH)

run:
	@echo "-> Running simulation..."
	@./obj_dir/V$(TOPMODULE) | tee simulation.log
	@echo "Simulation completed. Log saved to simulation.log"

sim:
	@echo "-> Opening waveform viewer..."
	@gtkwave waveform.vcd &> /dev/null &

clean:
	@echo "-> Cleaning project..."
	@rm -rf obj_dir *.dmp *.vcd simulation.log

help:
	@echo "Makefile targets:"
	@echo "  all      : Clean, compile and run (default)"
	@echo "  compile  : Compile the design with Verilator"
	@echo "  run      : Run the simulation"
	@echo "  sim      : Open waveform viewer"
	@echo "  clean    : Remove generated files"
	@echo "  help     : Show this help message"

.PHONY: all compile run sim clean help