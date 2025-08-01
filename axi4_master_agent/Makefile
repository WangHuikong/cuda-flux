# AXI4 Master Agent Makefile

# 仿真器选择
SIMULATOR ?= questa

# 文件路径
INC_DIR = inc
RTL_DIR = rtl
TB_DIR = tb

# 源文件
INC_FILES = $(wildcard $(INC_DIR)/*.sv)
RTL_FILES = $(wildcard $(RTL_DIR)/*.sv)
TB_FILES = $(wildcard $(TB_DIR)/*.sv)

# 编译选项
VLOG_OPTS = -sv +incdir+$(INC_DIR)
VCS_OPTS = -full64 -sverilog +incdir+$(INC_DIR)
IVERILOG_OPTS = -g2012 -I$(INC_DIR)

# 默认目标
all: compile

# 编译
compile:
ifeq ($(SIMULATOR),questa)
	@echo "Compiling with QuestaSim..."
	vlog $(VLOG_OPTS) $(INC_FILES) $(RTL_FILES) $(TB_FILES)
else ifeq ($(SIMULATOR),vcs)
	@echo "Compiling with VCS..."
	vcs $(VCS_OPTS) $(INC_FILES) $(RTL_FILES) $(TB_FILES)
else ifeq ($(SIMULATOR),iverilog)
	@echo "Compiling with Icarus Verilog..."
	iverilog $(IVERILOG_OPTS) $(INC_FILES) $(RTL_FILES) $(TB_FILES) -o simv
else
	@echo "Unknown simulator: $(SIMULATOR)"
	@echo "Supported simulators: questa, vcs, iverilog"
	exit 1
endif

# 运行仿真
run: compile
ifeq ($(SIMULATOR),questa)
	@echo "Running with QuestaSim..."
	vsim -c -do "run -all; quit" axi4_master_test
else ifeq ($(SIMULATOR),vcs)
	@echo "Running with VCS..."
	./simv
else ifeq ($(SIMULATOR),iverilog)
	@echo "Running with Icarus Verilog..."
	vvp simv
endif

# 运行GUI仿真
gui: compile
ifeq ($(SIMULATOR),questa)
	@echo "Running GUI simulation with QuestaSim..."
	vsim -gui axi4_master_test
else ifeq ($(SIMULATOR),vcs)
	@echo "Running GUI simulation with VCS..."
	./simv -gui
else
	@echo "GUI simulation not supported for $(SIMULATOR)"
endif

# 清理
clean:
	rm -rf work/
	rm -rf simv/
	rm -rf csrc/
	rm -rf *.log
	rm -rf *.vpd
	rm -rf *.wlf
	rm -rf transcript
	rm -rf simv
	rm -rf dump.vcd

# 检查语法
check:
	@echo "Checking syntax..."
	vlog -sv -lint $(VLOG_OPTS) $(INC_FILES) $(RTL_FILES) $(TB_FILES)

# 生成波形
wave: run
ifeq ($(SIMULATOR),questa)
	@echo "Opening waveform viewer..."
	vsim -view vsim.wlf
else ifeq ($(SIMULATOR),vcs)
	@echo "Opening waveform viewer..."
	dve -vpd vcdplus.vpd
else
	@echo "Waveform viewing not configured for $(SIMULATOR)"
endif

# 帮助
help:
	@echo "Available targets:"
	@echo "  compile    - Compile all source files"
	@echo "  run        - Compile and run simulation"
	@echo "  gui        - Compile and run GUI simulation"
	@echo "  clean      - Clean all generated files"
	@echo "  check      - Check syntax only"
	@echo "  wave       - Run simulation and open waveform viewer"
	@echo "  help       - Show this help message"
	@echo ""
	@echo "Environment variables:"
	@echo "  SIMULATOR  - Choose simulator (questa/vcs/iverilog)"
	@echo ""
	@echo "Examples:"
	@echo "  make run                    # Run with default simulator"
	@echo "  make SIMULATOR=vcs run     # Run with VCS"
	@echo "  make SIMULATOR=questa gui  # Run GUI with QuestaSim"

# 安装依赖（如果需要）
install:
	@echo "Installing dependencies..."
	# 这里可以添加安装依赖的命令
	@echo "Dependencies installed."

# 测试
test: run
	@echo "Running tests..."
	# 这里可以添加测试验证逻辑

# 文档
docs:
	@echo "Generating documentation..."
	# 这里可以添加文档生成命令

.PHONY: all compile run gui clean check wave help install test docs