#!/bin/bash

# AXI4 Master Agent 编译和运行脚本
# 支持 ModelSim/QuestaSim 和 VCS

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 默认设置
SIMULATOR="questa"
TEST_NAME="axi4_test"
COMPILE_ONLY=false
RUN_ONLY=false

# 帮助信息
show_help() {
    echo "AXI4 Master Agent 编译和运行脚本"
    echo ""
    echo "用法: $0 [选项]"
    echo ""
    echo "选项:"
    echo "  -s, --simulator <sim>    选择仿真器 (questa|vcs) [默认: questa]"
    echo "  -t, --test <test_name>   选择测试用例 [默认: axi4_test]"
    echo "  -c, --compile-only       仅编译，不运行"
    echo "  -r, --run-only           仅运行，不编译"
    echo "  -h, --help               显示此帮助信息"
    echo ""
    echo "测试用例:"
    echo "  axi4_test        - 基本测试"
    echo "  axi4_write_test  - 写操作测试"
    echo "  axi4_read_test   - 读操作测试"
    echo "  axi4_burst_test  - 突发传输测试"
    echo "  axi4_random_test - 随机测试"
    echo ""
    echo "示例:"
    echo "  $0 -s questa -t axi4_write_test"
    echo "  $0 -s vcs -c"
    echo "  $0 -r"
}

# 解析命令行参数
while [[ $# -gt 0 ]]; do
    case $1 in
        -s|--simulator)
            SIMULATOR="$2"
            shift 2
            ;;
        -t|--test)
            TEST_NAME="$2"
            shift 2
            ;;
        -c|--compile-only)
            COMPILE_ONLY=true
            shift
            ;;
        -r|--run-only)
            RUN_ONLY=true
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            echo -e "${RED}错误: 未知选项 $1${NC}"
            show_help
            exit 1
            ;;
    esac
done

# 检查仿真器
check_simulator() {
    case $SIMULATOR in
        questa|modelsim)
            if ! command -v vsim &> /dev/null; then
                echo -e "${RED}错误: 未找到 QuestaSim/ModelSim${NC}"
                exit 1
            fi
            ;;
        vcs)
            if ! command -v vcs &> /dev/null; then
                echo -e "${RED}错误: 未找到 VCS${NC}"
                exit 1
            fi
            ;;
        *)
            echo -e "${RED}错误: 不支持的仿真器 $SIMULATOR${NC}"
            exit 1
            ;;
    esac
}

# 清理函数
cleanup() {
    echo -e "${YELLOW}清理临时文件...${NC}"
    rm -rf work/
    rm -f transcript
    rm -f vsim.wlf
    rm -f simv
    rm -f simv.daidir/
    rm -f *.log
    rm -f *.vcd
    rm -f *.wlf
}

# QuestaSim/ModelSim 编译
compile_questa() {
    echo -e "${GREEN}使用 QuestaSim/ModelSim 编译...${NC}"
    
    # 创建工作库
    vlib work
    
    # 编译文件
    vlog -sv +incdir+. \
        axi4_interface.sv \
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
    
    if [ $? -ne 0 ]; then
        echo -e "${RED}编译失败${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}编译成功${NC}"
}

# QuestaSim/ModelSim 运行
run_questa() {
    echo -e "${GREEN}使用 QuestaSim/ModelSim 运行测试: $TEST_NAME${NC}"
    
    # 运行仿真
    vsim -c -do "run -all; quit" axi4_tb +UVM_TESTNAME=$TEST_NAME
    
    if [ $? -ne 0 ]; then
        echo -e "${RED}仿真失败${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}仿真完成${NC}"
}

# VCS 编译
compile_vcs() {
    echo -e "${GREEN}使用 VCS 编译...${NC}"
    
    # 编译
    vcs -full64 -sverilog +incdir+. \
        +define+UVM_NO_DPI \
        +v2k \
        -timescale=1ns/1ps \
        axi4_interface.sv \
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
        axi4_tb.sv \
        -o simv
    
    if [ $? -ne 0 ]; then
        echo -e "${RED}编译失败${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}编译成功${NC}"
}

# VCS 运行
run_vcs() {
    echo -e "${GREEN}使用 VCS 运行测试: $TEST_NAME${NC}"
    
    # 运行仿真
    ./simv +UVM_TESTNAME=$TEST_NAME
    
    if [ $? -ne 0 ]; then
        echo -e "${RED}仿真失败${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}仿真完成${NC}"
}

# 主函数
main() {
    echo -e "${GREEN}AXI4 Master Agent 编译和运行脚本${NC}"
    echo -e "${YELLOW}仿真器: $SIMULATOR${NC}"
    echo -e "${YELLOW}测试用例: $TEST_NAME${NC}"
    echo ""
    
    # 检查仿真器
    check_simulator
    
    # 清理
    cleanup
    
    # 编译
    if [ "$RUN_ONLY" = false ]; then
        case $SIMULATOR in
            questa|modelsim)
                compile_questa
                ;;
            vcs)
                compile_vcs
                ;;
        esac
    fi
    
    # 运行
    if [ "$COMPILE_ONLY" = false ]; then
        case $SIMULATOR in
            questa|modelsim)
                run_questa
                ;;
            vcs)
                run_vcs
                ;;
        esac
    fi
    
    echo -e "${GREEN}完成!${NC}"
}

# 运行主函数
main