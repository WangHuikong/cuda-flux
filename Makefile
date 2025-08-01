# AXI4 Master Agent Makefile
# 支持 ModelSim/QuestaSim 和 VCS

# 默认设置
SIMULATOR ?= questa
TEST_NAME ?= axi4_test
UVM_HOME ?= /path/to/uvm

# 文件列表
SV_FILES = axi4_interface.sv \
           axi4_config.sv \
           axi4_transaction.sv \
           axi4_master_driver.sv \
           axi4_master_monitor.sv \
           axi4_master_sequencer.sv \
           axi4_master_agent.sv \
           axi4_sequences.sv \
           axi4_test_env.sv \
           axi4_test.sv \
           axi4_slave.sv \
           axi4_tb.sv

# 默认目标
all: compile run

# 帮助
help:
	@echo "AXI4 Master Agent Makefile"
	@echo ""
	@echo "目标:"
	@echo "  all          - 编译并运行 (默认)"
	@echo "  compile      - 仅编译"
	@echo "  run          - 仅运行"
	@echo "  clean        - 清理文件"
	@echo "  help         - 显示此帮助"
	@echo ""
	@echo "变量:"
	@echo "  SIMULATOR    - 仿真器 (questa|vcs) [默认: questa]"
	@echo "  TEST_NAME    - 测试用例 [默认: axi4_test]"
	@echo "  UVM_HOME     - UVM库路径"
	@echo ""
	@echo "测试用例:"
	@echo "  axi4_test        - 基本测试"
	@echo "  axi4_write_test  - 写操作测试"
	@echo "  axi4_read_test   - 读操作测试"
	@echo "  axi4_burst_test  - 突发传输测试"
	@echo "  axi4_random_test - 随机测试"
	@echo ""
	@echo "示例:"
	@echo "  make SIMULATOR=vcs TEST_NAME=axi4_write_test"
	@echo "  make compile"
	@echo "  make run TEST_NAME=axi4_read_test"

# 清理
clean:
	@echo "清理文件..."
	rm -rf work/
	rm -f transcript
	rm -f vsim.wlf
	rm -f simv
	rm -f simv.daidir/
	rm -f *.log
	rm -f *.vcd
	rm -f *.wlf
	@echo "清理完成"

# QuestaSim/ModelSim 编译
compile_questa:
	@echo "使用 QuestaSim/ModelSim 编译..."
	vlib work
	vlog -sv +incdir+. $(SV_FILES)
	@echo "编译完成"

# QuestaSim/ModelSim 运行
run_questa:
	@echo "使用 QuestaSim/ModelSim 运行测试: $(TEST_NAME)"
	vsim -c -do "run -all; quit" axi4_tb +UVM_TESTNAME=$(TEST_NAME)
	@echo "仿真完成"

# VCS 编译
compile_vcs:
	@echo "使用 VCS 编译..."
	vcs -full64 -sverilog +incdir+. \
		+define+UVM_NO_DPI \
		+v2k \
		-timescale=1ns/1ps \
		$(SV_FILES) \
		-o simv
	@echo "编译完成"

# VCS 运行
run_vcs:
	@echo "使用 VCS 运行测试: $(TEST_NAME)"
	./simv +UVM_TESTNAME=$(TEST_NAME)
	@echo "仿真完成"

# 编译目标
compile: clean
ifeq ($(SIMULATOR),questa)
	$(MAKE) compile_questa
else ifeq ($(SIMULATOR),vcs)
	$(MAKE) compile_vcs
else
	@echo "错误: 不支持的仿真器 $(SIMULATOR)"
	@echo "支持的仿真器: questa, vcs"
	@exit 1
endif

# 运行目标
run:
ifeq ($(SIMULATOR),questa)
	$(MAKE) run_questa
else ifeq ($(SIMULATOR),vcs)
	$(MAKE) run_vcs
else
	@echo "错误: 不支持的仿真器 $(SIMULATOR)"
	@echo "支持的仿真器: questa, vcs"
	@exit 1
endif

# 检查仿真器
check_simulator:
ifeq ($(SIMULATOR),questa)
	@which vsim > /dev/null || (echo "错误: 未找到 QuestaSim/ModelSim"; exit 1)
else ifeq ($(SIMULATOR),vcs)
	@which vcs > /dev/null || (echo "错误: 未找到 VCS"; exit 1)
else
	@echo "错误: 不支持的仿真器 $(SIMULATOR)"
	@echo "支持的仿真器: questa, vcs"
	@exit 1
endif

# 设置默认目标
.PHONY: all help clean compile run compile_questa run_questa compile_vcs run_vcs check_simulator