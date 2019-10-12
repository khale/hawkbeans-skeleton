include $(JVM_SRC_DIR)/arch/modules.mk 

JVM_SRC += mm.c \
       class.c \
       thread.c \
       stack.c \
       hashtable.c \
       native.c \
       bc_interp.c \
       exceptions.c \
       gc.c 
