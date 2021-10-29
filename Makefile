CC=x86_64-elf-gcc
OBJ=obj

AS=x86_64-elf-gcc
ASFLAGS=-x assembler-with-cpp -c
LD=x86_64-elf-ld
LDFLAGS=--oformat binary -T linker.ld

KERNEL_OFILES=\
	  $(OBJ)/boot.s.o\
	  $(OBJ)/start.o\
	  $(OBJ)/x86.s.o

.PHONY: all
all: $(OBJ)/kernel.img

run: $(OBJ)/kernel.img
	qemu-system-x86_64  -hda $(OBJ)/kernel.img

$(OBJ)/kernel.img: $(KERNEL_OFILES)
	@mkdir -p $(@D)
	$(LD) $(LDFLAGS) -o $@ $(KERNEL_OFILES)

.PHONY: clean
clean:
	/bin/rm -rf $(OBJ)

$(OBJ)/%.s.o: %.s
	@mkdir -p $(@D)
	$(AS) -o $@ $(ASFLAGS) $<

$(OBJ)/%.s.o: %.s
	@mkdir -p $(@D)
	$(AS) -o $@ $(ASFLAGS) $<

$(OBJ)/%.o: %.c
	@mkdir -p $(@D)
	$(CC) $(KERNEL_CFLAGS) -c -o $@ $<
