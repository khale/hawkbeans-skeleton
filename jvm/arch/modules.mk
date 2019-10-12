
ifeq ($(PLATFORM),"hawknest")
include $(JVM_SRC_DIR)/arch/hawknest/modules.mk
else
include $(JVM_SRC_DIR)/arch/x64-linux/modules.mk
endif
