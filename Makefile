# CUDA Cache Bandwidth Test Makefile

# CUDA编译器
NVCC = nvcc

# 编译选项
NVCC_FLAGS = -O3 -arch=sm_80 -Xcompiler -O3

# 目标文件
TARGET_BASIC = cuda_cache_bandwidth
TARGET_ADVANCED = advanced_cache_test

# 源文件
SOURCE_BASIC = cuda_cache_bandwidth.cu
SOURCE_ADVANCED = advanced_cache_test.cu

# 默认目标
all: $(TARGET_BASIC) $(TARGET_ADVANCED)

# 编译规则
$(TARGET_BASIC): $(SOURCE_BASIC)
	$(NVCC) $(NVCC_FLAGS) -o $(TARGET_BASIC) $(SOURCE_BASIC)

$(TARGET_ADVANCED): $(SOURCE_ADVANCED)
	$(NVCC) $(NVCC_FLAGS) -o $(TARGET_ADVANCED) $(SOURCE_ADVANCED)

# 运行程序
run: $(TARGET_BASIC)
	./$(TARGET_BASIC)

run-advanced: $(TARGET_ADVANCED)
	./$(TARGET_ADVANCED)

# 清理
clean:
	rm -f $(TARGET_BASIC) $(TARGET_ADVANCED)

# 帮助信息
help:
	@echo "Available targets:"
	@echo "  all           - Build both basic and advanced cache bandwidth test programs"
	@echo "  run           - Build and run the basic program"
	@echo "  run-advanced  - Build and run the advanced program"
	@echo "  clean         - Remove built files"
	@echo "  help          - Show this help message"

.PHONY: all run run-advanced clean help