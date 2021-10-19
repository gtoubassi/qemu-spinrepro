# Simple bootloader example for x86 systems that should print out a simple message to the user

kernelbase  = 0x07e00

.code16     # We're dealing with 16 bit code
.text

start:

#
# Disable interrupts and reset the segment registers
#
    cli
    mov $0, %ax
    mov %ax, %ds
    mov %ax, %es
    mov %ax, %ss

# Skip the A20 line shenanigans

#
# Read the kernel from disk.  The size is hardcoded and needs to be
# synchronized with linker.ld.  See "LBA in Extended Mode" at
# https://wiki.osdev.org/ATA_in_x86_RealMode_(BIOS)
#
    mov $kernelbase >> 4, %ax   # Convert the base address to a segment (we are using a zero offset)
    mov %ax, diskstruct_segment
readloop:
    mov $0x42, %ah
    mov $0, %al
    mov $diskstruct, %si
    mov $0x80, %dl      # The drive.  80h is the "C" drive
    int $0x13
    jnc readsuccess
    hlt
readsuccess:
    addw $1, diskstruct_lba_low
    cmpw $10, diskstruct_lba_low   # kernel size / 512 is # of blocks + the first boot block
    je readdone
    addw $512 * 1 >> 4, diskstruct_segment   # We read 512 bytes per block, then >> 4 to convert to segment
    jmp readloop
readdone:


#
# Promote to 32-bit protected mode
#
    lgdt gdtdesc
    movl %cr0, %eax
    orl $1, %eax        # 1 is Protection Enabled
    movl %eax, %cr0
    ljmp $8, $start32   # Long Jump using gdt entry +8 (code segment) to get cs/eip loaded
    hlt


#
# start32 is called once we enter 32 bit protected mode. It
# continues to upgrade us to 64 bit long mode.
#
.code32
start32:
    movw $16, %ax
    movw %ax, %ds
    movw %ax, %es
    movw %ax, %ss
    movw $0, %ax
    movw %ax, %fs
    movw %ax, %gs
    movl $start, %esp    # We grow the stack from 7c00 (where this boot block is loaded) down.

    # Clear 4 page tables (4096 X 4 bytes per store)
    # We start the page tables at 0x1000 per wiki.osdev.org/Setting_Up_Long_Mode
    # According to staff.ustc.edu.cn/~xyfeng/research/cos/resources/machine/mem.htm
    # 500-9FBFF is a free for all.  We are loaded at 7c00 so 4096x4 will mean we are using
    # 0x1000-0x5000
    mov $0x1000, %edi
    mov %eax, %eax
    mov $4096, %ecx
    rep stosl

    # Point %cr3 at the top level page table (PML4T)
    # This doesn't activate paging yet, but its where the system will look when it is active
    mov $0x1000, %edi
    mov %edi, %cr3

    #
    # Link the page tables together
    # The "|3" is because the low bits are flags.  This means "this entry is present and readable"
    #
    movl $0x2000 | 7, (%edi)
    add $0x1000, %edi
    movl $0x3000 | 7, (%edi)
    add $0x1000, %edi
    movl $0x4000 | 7, (%edi)
    add $0x1000, %edi

    # Now lets identity map the lowest level page table (just one of them).  The page
    # table as 512 entries, each representing 4k, so that means we are identity mapping 0-2MB
    # Any other access will fault.
    mov $7, %ebx
    mov $512, %ecx
identitymaploop:
    mov %ebx, (%edi)
    add $0x1000, %ebx
    add $8, %edi
    loop identitymaploop

    # Enable PAE (6th bit in cr4) which is the 4 level page table heirarchy in long mode
    mov %cr4, %eax
    or $1 << 5, %eax
    mov %eax, %cr4

    # Paging still isn't enabled.  But we are all set up.  cr3 is pointing to our root page directory,
    # and PAE is set.

    # Set the "long mode" LM bit in the Extended Feature Enable Register (EFER) model-specific register (MSR)
    mov $0xc0000080, %ecx   # 0xc0000080 is the EFER MSR
    rdmsr
    or $1 << 8, %eax        # LM bit is bit 8.
    or $1 << 11, %eax       # NXE bit is bit 11, allowing us to mark data pages as NOT executable
    wrmsr

    # Now enable paging
    mov %cr0, %eax
    or $1 << 31, %eax
    mov %eax, %cr0

    # Enable SSE so we can use xmm registers which are required for
    # call conventions with fp args
    mov %cr0, %eax
    and  $0xfffb, %ax		#clear coprocessor emulation CR0.EM
    or $0x2, %ax 			#set coprocessor monitoring  CR0.MP
    mov %eax, %cr0
    mov %cr4, %eax
    or $3 << 9, %ax 		#set CR4.OSFXSR and CR4.OSXMMEXCPT at the same time
    mov %eax, %cr4

    # We are now in compatibility submode of long mode.  How do we actually get to long mode?
    # Load a properly configured long mode GDT
    lgdt gdt64desc
    ljmp $8, $start64   # Long Jump using gdt entry +8 (code segment) to get cs/eip loaded

#
# start64 is called when we ACTUALLY are in full 64 bit long mode with the first 2mb of
# ram identity mapped.
#
.code64
start64:
    cli
    call start64C   # call to C code!
    hlt

diskstruct:
    .byte 16, 0   # size of structure, then a zero
diskstruct_numsectors:
    .word 1       # of sectors
diskstruct_offset:
    .word 0x0
diskstruct_segment:
    .word 0
diskstruct_lba_low:
    .word 1
diskstruct_lba_mid:
    .word 0
diskstruct_lba_hi:
    .long 0

.p2align 2
gdt:
    .word 0, 0
    .byte 0, 0, 0, 0            # Null segment

    .word 0xffff, 0             # Code segment
    .byte 0, 0x9a, 0xcf, 0      # offset 0, limit 0xffffffff, flags 0xc, access 0x9a

    .word 0xffff, 0             # Data segment
    .byte 0, 0x92, 0xcf, 0      # offset 0, limit 0xffffffff, flags 0xc, access 0x92

gdtdesc:
    .word (gdtdesc - gdt - 1)
    .long gdt


.p2align 2
	.globl	_bootGDT64
_bootGDT64:
gdt64:
    .word 0x0, 0
    .byte 0, 0, 0, 0            # Null segment

    .word 0, 0                  # Kernel Code segment
    .byte 0, 0x98, 0x20, 0      # See page 97 of AMD64 arch vol 2

    .word 0, 0                  # Kernel Data segment
    .byte 0, 0x92, 0, 0         # See page 98 of AMD64 arch vol 2
                                # Except the docs say we don't need
                                # the W bit but we do.  0x90 crashes

    # Note these values are different than those at https://wiki.osdev.org/Getting_to_Ring_3
    # based on the AMD docs which say a bunch of fields are ignored in 64 bit mode

    .word 0, 0                  # User Code segment
    .byte 0, 0xf8, 0x20, 0      # See page 97 of AMD64 arch vol 2

    .word 0, 0                  # User Data segment
    .byte 0, 0xf2, 0, 0         # See page 98 of AMD64 arch vol 2
                                # The docs say DPL is ignored, and we don't need
                                # the W bit but it seems we do, perhaps a QEMU thing?
                                # According to docs I'd want 0x90

    .word 0, 0                  # TSS is actually 128 bits in 64 bit mode
    .byte 0, 0x89, 0, 0         # See page 100 of AMD64 arch vol 2
    .long 0, 0                  # Note https://wiki.osdev.org/TSS indicated 0x40 flags???

gdt64desc:
    .word (gdt64desc - gdt64 - 1)
    .long gdt64

