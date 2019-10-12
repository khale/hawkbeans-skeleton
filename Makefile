CLANG_EXEC:=clang
GCC_EXEC:=gcc

lc = $(shell echo $(1) | tr A-Z a-z)

PROJECT_NAME=p2
PROJECT_SERVER="http://subutai.cs.iit.edu"
PROJECT_PORT=3000

CLANG_IGNORED_WARNINGS = reserved-id-macro \
						variadic-macros \
						undef \
						gnu-zero-variadic-macro-arguments \
						documentation \
						padded \
						missing-noreturn \
						unused-parameter \
						covered-switch-default \
						disabled-macro-expansion \
						pedantic

CC_STD_FLAG = -std=gnu11 

CLANG_WARNING_FLAGS = -Weverything $(addprefix -Wno-,$(CLANG_IGNORED_WARNINGS))

GCC_IGNORED_WARNINGS = packed-bitfield-compat \
					   unused-parameter \
					   cast-function-type

GCC_WARNING_FLAGS = -Wall -Wextra $(addprefix -Wno-,$(GCC_IGNORED_WARNINGS))

CC_COMMON_DEFINES := GNU_SOURCE ASSERT_RECOVER UNREACHABLE_RECOVER
CC_DEBUG_DEFINES := DEBUG_ENABLE

ifdef DEBUG_GC
CC_DEBUG_DEFINES += DEBUG_GC
endif

ifdef DEBUG_MM
CC_DEBUG_DEFINES += DEBUG_MM
endif

ifdef DEBUG_BUDDY
CC_DEBUG_DEFINES += DEBUG_BUDDY
endif

ifdef DEBUG_EXCP
CC_DEBUG_DEFINES += DEBUG_EXCP
endif

ifdef DEBUG_CLASS
CC_DEBUG_DEFINES += DEBUG_CLASS
endif

ifdef DEBUG_NATIVE
CC_DEBUG_DEFINES += DEBUG_NATIVE
endif

ifdef DEBUG_THREAD
CC_DEBUG_DEFINES += DEBUG_THREAD
endif

ifdef DEBUG_STACK
CC_DEBUG_DEFINES += DEBUG_STACK
endif

ifdef DEBUG_INTERP
CC_DEBUG_DEFINES += DEBUG_INTERP
endif

ifdef REFERENCE
CC_COMMON_DEFINES += REFERENCE
endif

CC_RELEASE_DEFINES := ASSERT_ASSUME UNREACHABLE_ASSUME 

CC_DEFINES = $(CC_COMMON_DEFINES) $(CC_$(MODE)_DEFINES)
CC_DEFINES_FLAGS = $(addprefix -D,$(CC_DEFINES))

JVM_INCLUDE_DIR = include
CC_INCLUDE_FLAG = -I$(JVM_INCLUDE_DIR)

# libs that the JVM will link with
JVM_LIBS = readline
CC_LIB_FLAGS = $(addprefix -l,$(JVM_LIBS))

CC_LTO_FLAG = -flto
CC_ARCH_FLAG = -march=native

ifdef UBSAN
COMMON_SANITIZER_FLAGS += -fsanitize=undefined
CLANG_SANITIZER_FLAGS += -fsanitize=nullability
endif

ifdef ASAN
COMMON_SANITIZER_FLAGS += -fsanitize=address
endif

CC_SANITIZER_FLAGS += $(COMMON_SANITIZER_FLAGS) $($(COMPILER)_SANITIZER_FLAGS)

CC_COMMON_FLAGS = $(CC_WARNING_FLAGS) $(CC_STD_FLAG) $(CC_DEFINES_FLAGS) $(CC_INCLUDE_FLAG) $(CC_ARCH_FLAG)
CC_DEBUG_FLAGS = $(CC_COMMON_FLAGS) $(CC_SANITIZER_FLAGS) -g -O1 -fno-inline -fno-omit-frame-pointer -fno-optimize-sibling-calls
CC_OPT_FLAGS = $(CC_COMMON_FLAGS) $(CC_SANITIZER_FLAGS) -g -O3
CC_RELEASE_FLAG = $(CC_COMMON_FLAGS) $(CC_LTO_FLAG) -g -O3

CC_FLAGS = $(CC_$(MODE)_FLAGS)
CC_EXEC = $($(COMPILER)_EXEC)
CC_COMMAND = $(CC_EXEC) $(CC_FLAGS)

JVM_SRC_DIR = jvm
JVM_INCLUDE_DIR = include

BUILD_DIR = build
JVM_BUILD_DIR = $(BUILD_DIR)/jvm/$(call lc,$(COMPILER))/$(call lc,$(MODE))

BIN_DIR = bin
JVM = $(BIN_DIR)/hawkbeans-$(call lc,$(COMPILER))-$(call lc, $(MODE))

JVM_SRC := 
include $(JVM_SRC_DIR)/modules.mk

JVM_OBJ = $(addprefix $(JVM_BUILD_DIR)/,$(JVM_SRC:.c=.o))
JVM_DEP = $(JVM_OBJ:.o=.d)

COMPILER = CLANG
MODE = DEBUG

jvm: $(JVM)

check:
	@echo "JVM SRC: $(JVM_SRC)"
	@echo "JVM OBJ: $(JVM_OBJ)"

clean:
	@rm -rf $(BUILD_DIR) $(BIN_DIR) submission.tar.gz testcode/*.class

include $(wildcard $(JVM_DEP))

$(JVM_OBJ): $(JVM_BUILD_DIR)/%.o: $(JVM_SRC_DIR)/%.c
	@echo "$@ <- $<"
	@mkdir -p $(dir $@)
	@$(CC_COMMAND) -MD -MP -c $< -o $@

$(JVM): $(JVM_OBJ)
	@echo "Linking $@..."
	@mkdir -p $(dir $@)
	@$(CC_COMMAND) $(CC_LIB_FLAGS) $^ -o $@

jlibs: jbuild.xml javasrc/*
	@ant -f jbuild.xml
	@jar xvf classes.jar
	@rm -rf classes.jar META-INF build	

TESTSRC:=$(wildcard testcode/*.java)
TESTCLASS:=$(TESTSRC:java=class)

testcode: $(TESTCLASS)

testcode/%.class: testcode/%.java
	@echo "$@ <- $<"
	@javac -g $<

handin:
	@echo "Creating tarball and attemptin submission..."
	@$(MAKE) clean
	@tar cvzf submission.tar.gz ./*
	@echo "  submission file successfully created in submission.tar.gz"
	@echo "Initiating submission..."
	python3 scripts/submit.py $(PROJECT_NAME) submission.tar.gz -s $(PROJECT_SERVER) -p $(PROJECT_PORT)
	@echo "Submission complete. Cleaning up."
	@rm -f submission.tar.gz
	
buildtest: $(JVM)
	@make -C test buildruntest
	@test/buildtest.sh

.PHONY: jvm clean buildtest testcode
