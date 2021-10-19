CC=x86_64-elf-gcc
OBJ=obj
KERNEL_LDFLAGS=--oformat binary -T $(OBJ)/linker.ld
KERNEL_LINKER_SCRIPT=linker.ld
KERNEL_LINKER_SCRIPT_CPPFLAGS=-Isrc -P -x c -E

AS=x86_64-elf-gcc
ASFLAGS=-x assembler-with-cpp -c
CPP=x86_64-elf-gcc
LD=x86_64-elf-ld

KERNEL_OFILES=\
	  $(OBJ)/boot.s.o\
	  $(OBJ)/start.o\
	  $(OBJ)/x86.s.o

.PHONY: all
all: $(OBJ)/kernel.img

run: $(OBJ)/kernel.img
	qemu-system-x86_64  -hda $(OBJ)/kernel.img

$(OBJ)/kernel.img: $(OBJ)/linker.ld $(KERNEL_OFILES)
	@mkdir -p $(@D)
	$(LD) $(KERNEL_LDFLAGS) -o $@ $(KERNEL_OFILES)

.PHONY: clean
clean:
	/bin/rm -rf $(OBJ)

$(OBJ)/linker.ld: $(KERNEL_LINKER_SCRIPT)
	@mkdir -p $(@D)
	$(CPP) $(KERNEL_LINKER_SCRIPT_CPPFLAGS) -o $@ $<

$(OBJ)/%.s.o: %.s
	@mkdir -p $(@D)
	$(AS) -o $@ $(ASFLAGS) $<

$(OBJ)/%.s.o: %.s
	@mkdir -p $(@D)
	$(AS) -o $@ $(ASFLAGS) $<

$(OBJ)/%.o: %.c
	@mkdir -p $(@D)
	$(CC) $(KERNEL_CFLAGS) -c -o $@ $<
